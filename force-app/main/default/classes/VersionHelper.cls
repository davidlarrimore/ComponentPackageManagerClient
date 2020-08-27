/*
 *Name: VersionHelper
 *Description: Manages data gathering to support Unlocked Package version and upgrade functions
 *hosted.scratch.herokuapp.com/byoo?template=GithubURL
 *Contact: dlarrimore@salesforce.com
 *
 * 
 */


public with sharing class VersionHelper {

    //Checks for sfdx-project.json if it has it, that means its an SFDX project
    //If it can't find sfdx-project.json, it looks for /src/project.xml this means its a legacy aura project

    public static Demo_Component__c getComponentFromGithubURL(String githubUrl){
        System.debug('Running VersionHelper.getComponentFromGithubURL');  
        System.debug('Processing ' + githubUrl);
        List<String> versions = new List<String>();
        
        Boolean demoConfigFileFlag = false;
        Boolean subRepoFlag = githubUrl.contains('master') ? true : false;


        Demo_Component__c gpbuPackage = new Demo_Component__c();

        //@TODO: add the ability to find the package.xml in a child directory

        List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();

        gpbuPackage.Github_Repository_URL__c = githubUrl;
        gpbuPackage.Description__c = '';
        gpbuPackage.Last_Fetched__c = Datetime.Now();

        //Preset Options. We assume we can at least do a Source install from a valid github repo
        gpbuPackage.Source_Install_Type_Flag__c = true;
        gpbuPackage.SFDX_Package_Enabled_Flag__c = false; 
        gpbuPackage.Package_Install_Type_Flag__c = false;

        System.debug('Attempting to grab component-config.json from: ' + githubUrl);
        GithubComponentConfigDotJSON componentConfig = GithubAPIHelper.getGithubComponentConfigDotJSON(githubUrl);
        
        if(componentConfig != null){
            demoConfigFileFlag = true;
            gpbuPackage.SFDX_Package_Enabled_Flag__c = true;

            gpbuPackage.Title__c = componentConfig.name;
            gpbuPackage.Description__c = componentConfig.description != null ? componentConfig.description : '';
            gpbuPackage.POC_Name__c = componentConfig.author != null ? componentConfig.author : '';
            gpbuPackage.POC_Email__c = componentConfig.authorEmail != null  ? componentConfig.authorEmail : '';
            gpbuPackage.Admin_Permission_Set__c = componentConfig.permissionSet != null ? componentConfig.permissionSet  : '';
            gpbuPackage.SFDX_Package_Name__c = componentConfig.name;

            //Processing Dependencies
            if(componentConfig.dependencies != null){
                for(Map<String,String> thisDependency: (List<map<string,string>>) componentConfig.dependencies){
                    if(thisDependency.containsKey('packageName')){
                        dependentPackageSubscriberPackageVersionIds.add((String)thisDependency.get('packageName'));
                    }
                }
                 System.debug('Found some dependent Packages in component-config.json, will address later: ' + dependentPackageSubscriberPackageVersionIds);
            }
            if(componentConfig.disableSourceInstall && componentConfig.disableSourceInstall == true){
                gpbuPackage.Source_Install_Type_Flag__c = false;                   
            }
        }

        System.debug('Attempting to grab sfdx-project.json from: ' + githubUrl);
        GithubSFDXProjectDotJSON componentSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(githubUrl);
        if(componentSFDXProjectDotJSON != null){
            System.debug('found sfdx-project.json, processing...');

            if(!demoConfigFileFlag){
                gpbuPackage.Source_Install_Type_Flag__c = true; 
            }

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
                    gpbuPackage.Latest_SFDX_Package_Alias__c = componentSFDXProjectDotJSON.packageAliases.get(packageAlias);
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
        List<Demo_Component__c> existingPackageLookup = [SELECT Id from Demo_Component__c WHERE Github_Repository_URL__c = :githubUrl OR Package_Name__c = :gpbuPackage.SFDX_Package_Name__c OR Title__c = :gpbuPackage.Title__c LIMIT 1];
        if(existingPackageLookup.size() > 0){
            System.debug('Package already exists, adding Id and updating');
            gpbuPackage.Id = existingPackageLookup[0].Id;
        }else{
            System.debug('Nope....Inserting New Package: ' + gpbuPackage);
        }

        upsert gpbuPackage;

        System.debug('Processing Dependent Packages');
        QueueUpdateComponentFromPackageVersion processDependenciesJob = new QueueUpdateComponentFromPackageVersion(dependentPackageSubscriberPackageVersionIds, new Map<String,String>{'parentDemoComponentId'=> gpbuPackage.Id}); 
        ID processDependenciesJobId = System.enqueueJob(processDependenciesJob);      

        //Updating Package Info
        if(gpbuPackage.Package_Install_Type_Flag__c){
            System.debug('This is Package Install Enabled, using Tooling api to grab info');
            QueueUpdateComponentFromPackageVersion updateJob = new QueueUpdateComponentFromPackageVersion(new List<String>{gpbuPackage.Latest_Subscriber_Package_Version_Id__c},new Map<String,String>{}); 
            ID updateJobID = System.enqueueJob(updateJob);        
        }

        //Updating Source Info
        if(gpbuPackage.Source_Install_Type_Flag__c && !subRepoFlag){
            System.debug('This is Source Install Enabled, using Github api to grab Commit/tag info');
            QueueUpdateComponentSourceCommitInfo commitUpdateJob = new QueueUpdateComponentSourceCommitInfo(gpbuPackage.Id); 
            ID commitUpdateJobID = System.enqueueJob(commitUpdateJob);   
            
            QueueUpdateComponentSourceTagInfo tagUpdateJob = new QueueUpdateComponentSourceTagInfo(gpbuPackage.Id); 
            ID tagUpdateJobID = System.enqueueJob(tagUpdateJob);   
            
        }

        return gpbuPackage; 
    }
    
    @future(callout = true)
    public static void updateComponentSourceCommitInfo(Id gpbuPackageId){
        System.debug('Running VersionHelper.updateComponentSourceCommitInfo');  
        List<Demo_Component__c> gpbuPackage = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :gpbuPackageId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('Processing ' + gpbuPackage[0].Github_Repository_URL__c);   
            List<GithubRepoCommit> githubCommits = GithubAPIHelper.getGithubCommits(gpbuPackage[0].Github_Repository_URL__c);

            if(githubCommits != null && githubCommits.size() > 0){
                for(GithubRepoCommit thisCommit: githubCommits){
                    if (thisCommit.latestCommitFlag){
                        gpbuPackage[0].Latest_Commit_DateTime__c = thisCommit.commitInfo.committer.commitDate;
                        gpbuPackage[0].Latest_Commit_Description__c = thisCommit.commitInfo.message;
                        gpbuPackage[0].Latest_Commit_Hash__c = thisCommit.sha;

                        //If not an SFDX Based project, we assume POC information is not there, grabbing commit author info;
                        if (!gpbuPackage[0].SFDX_Package_Enabled_Flag__c){
                            GithubUser githubUser = GithubAPIHelper.getGithubUser(thisCommit.author.url);
                            gpbuPackage[0].POC_Name__c = githubUser.name;
                            gpbuPackage[0].POC_Email__c = githubUser.email;
                        }

                        update gpbuPackage[0];
                    }
                }
            }else{
                System.debug('No Commits found');  
            }
        }else{
            System.debug('Could not find Component ' + gpbuPackage[0].Id);   
        }
    }

    @future(callout = true)
    public static void updateComponentSourceTagInfo(Id gpbuPackageId){
        System.debug('Running VersionHelperupdateComponentSourceTagInfo');  
        List<Demo_Component__c> gpbuPackage = [SELECT Id, Github_Repository_URL__c FROM Demo_Component__c WHERE Id = :gpbuPackageId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('Processing ' + gpbuPackage[0].Github_Repository_URL__c);   
            List<GithubRepoTag> githubTags = GithubAPIHelper.getGithubTags(gpbuPackage[0].Github_Repository_URL__c);

            if(githubTags != null && githubTags.size() > 0){
                for(GithubRepoTag thisTag: githubTags){
                    if (thisTag.latestTagFlag){
                        gpbuPackage[0].Latest_Tag_Commit_DateTime__c = thisTag.tagDate;
                        gpbuPackage[0].Latest_Tag_Commit_Description__c = thisTag.githubCommit.commitInfo.message;
                        gpbuPackage[0].Latest_Tag_Commit_Hash__c = thisTag.githubCommit.sha;
                        gpbuPackage[0].Latest_Tag_Version_Name__c = thisTag.name;
                        update gpbuPackage[0];
                    }
                }
            }else{
                System.debug('No Commits found');  
            }
        }else{
            System.debug('Could not find Component ' + gpbuPackage[0].Id);   
        }
    }


    /* 
     * Uses Subscriber_Package_Version_Id to find Component and updates. If none is found, it creates a new component. This one includes an ID method that allows you to create a dependency on the spot....
     * Options:
     *  - parentDemoComponentId = '<Id of parent/depender component>' (If set, We need to create a package dependency as well)
     *  - installedFlag = 'true' or 'false' (This package is installed, we should update fields appropriatley)
     * 
     */
    public static void updateComponentFromPackageVersion(MetadataSubscriberPackage subscriberPackage, MetadataSubscriberPackageVersion subscriberPackageVersion, Map<String,String> options){
         System.debug('Running VersionHelper.updateComponentFromPackageVersion'); 
         Boolean newComponentFlag = false;
         Boolean createDependencyFlag = false;

        Demo_Component__c demoComponent = new Demo_Component__c();
        System.debug('attempting to find Demo Component via Subscriber Package Id or Subscriber Package Version Id');
        List<Demo_Component__c> demoComponentLookup = [SELECT Id, Latest_Subscriber_Package_Version_Id__c, Title__c, Package_Installed_Subscriber_Version_Id__c,Subscriber_Package_Id__c, Github_Repository_URL__c, Package_Install_Type_Flag__c FROM Demo_Component__c WHERE Subscriber_Package_Id__c = :subscriberPackage.id OR Latest_Subscriber_Package_Version_Id__c = :subscriberPackageVersion.id LIMIT 1];
        
        if(demoComponentLookup.size() > 0){
            demoComponent = demoComponentLookup[0];  
            System.debug('This package already exists as part of component, ' + demoComponent.Title__c + ', checking Latest_Subscriber_Package_Version_Id__c.');
            if(demoComponentLookup[0].Latest_Subscriber_Package_Version_Id__c == subscriberPackageVersion.id){
                System.debug('Component Latest_Subscriber_Package_Version_Id__c is the same as provided Subscriber Package Version ID');
            }else{
                System.debug('Found a different (And we can assume updated) Latest_Subscriber_Package_Version_Id__c. We will update existing: Provided ' + subscriberPackageVersion.id + ' vs Latest ' + demoComponent.Latest_Subscriber_Package_Version_Id__c);
            }
            demoComponent = demoComponentLookup[0];
        }else{
            newComponentFlag = true;
        }

        if(newComponentFlag){
            System.debug('No component found. Creating.');
            System.debug('Since this is a new component, we are going to set basic info');
            demoComponent.Source_Install_Type_Flag__c = false;
            demoComponent.SFDX_Package_Enabled_Flag__c = false; 
            demoComponent.Package_Install_Type_Flag__c = true;     
            demoComponent.Title__c = subscriberPackage.name;
            demoComponent.Description__c = subscriberPackage.description;  
        }

        demoComponent.Subscriber_Package_Id__c = subscriberPackage.id;
        demoComponent.Package_Name__c = subscriberPackage.name;
        demoComponent.Latest_Subscriber_Package_Version_Id__c = subscriberPackageVersion.id;
        demoComponent.Latest_Package_Version__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();
        demoComponent.Latest_Package_Version_Name__c = subscriberPackageVersion.name;
        demoComponent.Last_Fetched__c = Datetime.Now();

        //We only process this if installedFlag is true, which means it came from a getInstalledPackages call
        if(options.containsKey('installedFlag') && options.get('installedFlag') == 'true'){
            system.debug('Found Installed Flag, processing');

            demoComponent.Installed__c = true;
            demoComponent.Installation_Type__c = 'Package'; 

            if(demoComponent.Package_Install_Type_Flag__c){
                system.debug('Found Installed Flag, processing'); 
                demoComponent.Installed_Version_Tracking_Method__c = 'SFDX Project';                    
            }else{
                demoComponent.Installed_Version_Tracking_Method__c = 'None'; 
            }

            demoComponent.Package_Installed_Subscriber_Version_Id__c = subscriberPackageVersion.id;
            demoComponent.Package_Installed_Version_Name__c = subscriberPackageVersion.name;
            demoComponent.Package_Installed_Version_Number__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();    
        }

        upsert demoComponent;

        if(options.containsKey('parentDemoComponentId')){
            System.debug('parentDemoComponentId found, creating dependency'); 
            
            List<Demo_Component__c> parentDemoComponent = [SELECT Id FROM Demo_Component__c WHERE Id = :options.get('parentDemoComponentId') LIMIT 1];
            if(parentDemoComponent.size() > 0){
                System.debug('Found Parent Demo Component'); 
                if(!newComponentFlag){
                    List<Component_Dependency__c> packageDependencyLookup = [SELECT Id, Demo_Component__c, Dependent_Component__c FROM Component_Dependency__c WHERE Demo_Component__c = :parentDemoComponent[0].Id AND Dependent_Component__c = :demoComponentLookup[0].Id LIMIT 1];
                    if(packageDependencyLookup.size() > 0){
                        System.debug('Package Dependency Already Exists, skipping');  
                        createDependencyFlag = false;
                    }         
                }else{
                    createDependencyFlag = true;
                }

                if(options.containsKey('parentDemoComponentId') && createDependencyFlag){
                    System.debug('Creating new Package Dependency');
                    Component_Dependency__c packageDependency = new Component_Dependency__c();
                    
                    packageDependency.Demo_Component__c = parentDemoComponent[0].Id;
                    packageDependency.Dependent_Component__c = demoComponent.Id;
                    insert packageDependency;
                }
            }else{
                System.debug('Could not find parent demo component'); 
            }         
        }
    }

    //TODO: Check to see if Subscriber_Package_Id__c already exists
    public static void componentUpdateCheck(Id gpbuComponentId){
        System.debug('Start componentUpdateCheck');
        Boolean updateFlag = false;
        List<Demo_Component__c> demoComponent = [SELECT Id, Description__c, Latest_Commit_DateTime__c, Installation_Type__c, Package_Installed_Version_Number__c, Source_Installed_Commit_Hash__c, Source_Installed_Commit_DateTime__c, SFDX_Installed_Package_Alias__c, Package_Install_Type_Flag__c, Latest_SFDX_Package_Alias__c, Latest_Tag_Commit_Hash__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, Package_Installed_Subscriber_Version_Id__c, Installed__c  FROM Demo_Component__c WHERE Id = :gpbuComponentId LIMIT 1];
        if(demoComponent.size() > 0){
            system.debug('Found Demo Component');
            if(demoComponent[0].Installed__c){
                system.debug('It is installed');
                system.debug('Component Install Type is' + demoComponent[0].Installation_Type__c);
                system.debug('Component Version Tracking Method' + demoComponent[0].Installed_Version_Tracking_Method__c);

                if(demoComponent[0].Installed_Version_Tracking_Method__c == 'SFDX Project'){
                    if(demoComponent[0].Installation_Type__c == 'Package'){
                        if(demoComponent[0].Package_Installed_Subscriber_Version_Id__c != demoComponent[0].Latest_Subscriber_Package_Version_Id__c){
                            system.debug('Component Latest Subscriber Package Version ID of ' + demoComponent[0].Latest_Subscriber_Package_Version_Id__c + ' Is not the same as the installed version of ' + demoComponent[0].Package_Installed_Subscriber_Version_Id__c);
                            updateFlag = true;
                        }
                    }else if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Source' && demoComponent[0].Source_Installed_Tag_Hash__c != ''){
                        if(demoComponent[0].Source_Installed_Tag_DateTime__c < demoComponent[0].Latest_Tag_Commit_DateTime__c){
                            system.debug('Component Source Tag Installed date of ' + demoComponent[0].Source_Installed_Tag_DateTime__c + ' Is less than the latest tag commit date ' + demoComponent[0].Latest_Tag_Commit_DateTime__c);
                            updateFlag = true;
                        }
                    }else if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Source' && demoComponent[0].Source_Installed_Commit_Hash__c != ''){ 
                        if(demoComponent[0].Source_Installed_Commit_DateTime__c < demoComponent[0].Latest_Commit_DateTime__c){
                            system.debug('Component Source Tag Installed date of ' + demoComponent[0].Source_Installed_Tag_DateTime__c + ' Is less than the latest tag commit date ' + demoComponent[0].Latest_Tag_Commit_DateTime__c);
                            updateFlag = true;
                        }                     
                    }
                }
            }           
        }

        if(updateFlag){
            demoComponent[0].Update_Available__c = true;
            update demoComponent;
        }
    }


}