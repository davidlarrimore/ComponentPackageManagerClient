public with sharing class CpmAddGithubComponentController {
    @AuraEnabled
    public String githubUrl { get; set; }

    @AuraEnabled
    public static List<ID> runApex(string githubUrl){ 
        List<ID> JobIDs = new List<ID>();
        System.debug('CpmAddGithubComponentController.runApex');  
        System.debug('Processing ' + githubUrl);
        List<String> versions = new List<String>();
        
        Boolean demoConfigFileFlag = false;
        Boolean subRepoFlag = githubUrl.contains('master') ? true : false;

        Demo_Component__c gpbuPackage = new Demo_Component__c();
        List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();

        System.debug('Seeing if Package already exists');
        List<Demo_Component__c> existingPackageLookup = [SELECT Id, Source_Install_Type_Flag__c, Package_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Github_Repository_URL__c = :githubUrl LIMIT 1];
        if(existingPackageLookup.size() > 0){
            System.debug('Package already exists, adding Id and updating');
            gpbuPackage = existingPackageLookup[0];
        }else{
            System.debug('Nope....Inserting New Package: ' + gpbuPackage);
            gpbuPackage.Github_Repository_URL__c = githubUrl;
            gpbuPackage.Description__c = '';
            gpbuPackage.Last_Fetched__c = Datetime.Now();
    
            //Preset Options. We assume we can at least do a Source install from a valid github repo
            gpbuPackage.Source_Install_Type_Flag__c = true;
            gpbuPackage.SFDX_Package_Enabled_Flag__c = false; 
            gpbuPackage.Package_Install_Type_Flag__c = false;    
        }

        //@TODO: add the ability to find the package.xml in a child directory

        if(existingPackageLookup.size() == 0){
            System.debug('Attempting to grab sfdx-project.json from: ' + githubUrl);
            GithubSFDXProjectDotJSON componentSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(githubUrl);
            if(componentSFDXProjectDotJSON != null){
                gpbuPackage.SFDX_Package_Enabled_Flag__c = false; 
                System.debug('found sfdx-project.json, processing...');

                //Processing dependencies
                if(componentSFDXProjectDotJSON.packageAliases != null){
                    System.debug('this is an SFDX deployed Project, processing');
                    gpbuPackage.SFDX_Package_Enabled_Flag__c = true;
                    for(GithubPackageDirectory thisPackageDirectory: (List<GithubPackageDirectory>) componentSFDXProjectDotJSON.packageDirectories){
                        if(thisPackageDirectory.defaultDirectory == true){
                            System.debug('Found the default package directory');
                            gpbuPackage.Package_Install_Type_Flag__c = true;

                            if(!demoConfigFileFlag){
                                gpbuPackage.Title__c = thisPackageDirectory.packageName;  
                            }

                            //Processing Dependencies
                            if(dependentPackageSubscriberPackageVersionIds.size() < 1 && thisPackageDirectory.dependencies != null && thisPackageDirectory.dependencies.size() > 0){
                                for(Map<String,String> thisDependency: (List<map<string,string>>) thisPackageDirectory.dependencies){
                                    if(thisDependency.containsKey('packageName')){
                                        dependentPackageSubscriberPackageVersionIds.add((String)thisDependency.get('packageName'));
                                    }
                                }
                                System.debug('Found some dependent Packages in SFDX-Project.json, will address later: ' + dependentPackageSubscriberPackageVersionIds);
                            }

                            gpbuPackage.SFDX_Package_Name__c = thisPackageDirectory.packageName;
                            gpbuPackage.Latest_SFDX_Package_Version_Name__c = thisPackageDirectory.versionName;
                            gpbuPackage.Latest_SFDX_Package_Version_Description__c = thisPackageDirectory.versionDescription;

                        }else{
                            System.debug('This is not the default package directory, skipping');
                        }
                    }

                    for (String packageAlias : componentSFDXProjectDotJSON.packageAliases.keySet()){
                        System.debug('Processing packageAlias ' + packageAlias + ' : ' + componentSFDXProjectDotJSON.packageAliases.get(packageAlias));
                        gpbuPackage.Latest_SFDX_Package_Alias__c = packageAlias;
                        gpbuPackage.Latest_Subscriber_Package_Version_Id__c = componentSFDXProjectDotJSON.packageAliases.get(packageAlias);
                    }
                }
            }else{
                System.debug('Until we get the Package.XML lookup stuff working, we cannot process a repo without at least an sfdx-project.json');
                return null;
            }

            if(!gpbuPackage.SFDX_Package_Enabled_Flag__c){
                System.debug('Not a SFDX Based project, defaulting project name to Github Repo Name');
                String tempName = githubUrl.substring(githubUrl.lastIndexOf('/')+1, githubUrl.length());
                tempName = tempName.replace('_', ' ');
                tempName = tempName.replace('-', ' ');
                gpbuPackage.Title__c = tempName;
            }

            //TODO: Check for Package.XML (Low Priority)

            System.debug('Seeing if Package already exists');
            existingPackageLookup = [SELECT Id from Demo_Component__c WHERE (Github_Repository_URL__c != null AND Github_Repository_URL__c = :githubUrl) OR (Package_Name__c = :gpbuPackage.SFDX_Package_Name__c AND Package_Name__c != null) OR Title__c = :gpbuPackage.Title__c LIMIT 1];
            if(existingPackageLookup.size() > 0){
                System.debug('Package already exists, adding Id and updating');
                gpbuPackage.Id = existingPackageLookup[0].Id;
            }else{
                System.debug('Nope....Inserting New Package: ' + gpbuPackage);
            }

            upsert gpbuPackage;

            System.debug('Processing Dependent Packages');
            QueueUpdateComponentFromPackageVersion processDependenciesJob = new QueueUpdateComponentFromPackageVersion(dependentPackageSubscriberPackageVersionIds, new Map<String,String>{'parentDemoComponentId'=> gpbuPackage.Id});    
            JobIDs.add(System.enqueueJob(processDependenciesJob)); 

            QueueUpdateComponentFromGithubUser userUpdateJob = new QueueUpdateComponentFromGithubUser(gpbuPackage.Id);    
            JobIDs.add(System.enqueueJob(userUpdateJob));
        }

        //Updating Package Info
        if(gpbuPackage.Package_Install_Type_Flag__c){
            System.debug('This is Package Install Enabled, using Tooling api to grab info');
            QueueUpdateComponentFromPackageVersion packageVersionUpdateJob = new QueueUpdateComponentFromPackageVersion(new List<String>{gpbuPackage.Latest_Subscriber_Package_Version_Id__c},new Map<String,String>{}); 
            JobIDs.add(System.enqueueJob(packageVersionUpdateJob));       
        }


        //Updating Source Info
        if(gpbuPackage.Source_Install_Type_Flag__c && !subRepoFlag){
            System.debug('This is Source Install Enabled, using Github api to grab Commit/tag info');
            QueueUpdateComponentSourceCommitInfo commitUpdateJob = new QueueUpdateComponentSourceCommitInfo(gpbuPackage.Id, new Map<String,String>{});   
            JobIDs.add(System.enqueueJob(commitUpdateJob));

            QueueUpdateComponentSourceTagInfo tagUpdateJob = new QueueUpdateComponentSourceTagInfo(gpbuPackage.Id);    
            JobIDs.add(System.enqueueJob(tagUpdateJob));
        }

        return JobIDs;
    }


}
