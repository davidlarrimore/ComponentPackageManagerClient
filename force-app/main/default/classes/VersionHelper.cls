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

    public static Demo_Component__c getComponentFromGithubURL(String githubUrl, Map<String,String> options){
        System.debug('Running VersionHelper.getComponentFromGithubURL');  
        System.debug('Processing ' + githubUrl);
        List<ID> jobIds = new List<ID>();
        ID jobId;

        List<String> versions = new List<String>();
        
        Boolean demoConfigFileFlag = false;
        Boolean subRepoFlag = githubUrl.contains('master') ? true : false;


        Demo_Component__c gpbuPackage = new Demo_Component__c();


        System.debug('Seeing if Package already exists');
        List<Demo_Component__c> existingPackageLookup = [SELECT Id from Demo_Component__c WHERE Github_Repository_URL__c = :githubUrl LIMIT 1];
        if(existingPackageLookup.size() > 0){
            System.debug('Package already exists, adding Id and updating');
            gpbuPackage = existingPackageLookup[0];
        }else{
            System.debug('Nope....Inserting New Package: ' + gpbuPackage);
        }

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
        jobId = System.enqueueJob(processDependenciesJob);
        processDependenciesJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);  
        QueuePlatformEventHelper.publishPlatformEvent(processDependenciesJob.GetJobInfo());
        jobIds.add(jobId);    

        //Updating Package Info
        if(gpbuPackage.Package_Install_Type_Flag__c){
            System.debug('This is Package Install Enabled, using Tooling api to grab info');
            QueueUpdateComponentFromPackageVersion updateJob = new QueueUpdateComponentFromPackageVersion(new List<String>{gpbuPackage.Latest_Subscriber_Package_Version_Id__c},new Map<String,String>{}); 
            jobId = System.enqueueJob(processDependenciesJob);
            updateJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);  
            QueuePlatformEventHelper.publishPlatformEvent(updateJob.GetJobInfo());
            jobIds.add(jobId);           
        }

        //Updating Source Info
        if(gpbuPackage.Source_Install_Type_Flag__c && !subRepoFlag){
            System.debug('This is Source Install Enabled, using Github api to grab Commit/tag info');
            QueueUpdateComponentSourceCommitInfo commitUpdateJob = new QueueUpdateComponentSourceCommitInfo(gpbuPackage.Id, options); 
            jobId = System.enqueueJob(commitUpdateJob);
            commitUpdateJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);  
            QueuePlatformEventHelper.publishPlatformEvent(commitUpdateJob.GetJobInfo());
            jobIds.add(jobId);     
            
            QueueUpdateComponentSourceTagInfo tagUpdateJob = new QueueUpdateComponentSourceTagInfo(gpbuPackage.Id); 
            jobId = System.enqueueJob(tagUpdateJob);
            tagUpdateJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);  
            QueuePlatformEventHelper.publishPlatformEvent(tagUpdateJob.GetJobInfo());
            jobIds.add(jobId);       
            
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

    public static void updateComponentFromXTag(){
        System.debug('Running VersionHelper.getStaticResource');        
        List<StaticResource> staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'XTAG%'];
        List<String> githubRepositoryUrls = new List<String>();
        List<XTagFile> xTagFiles = new List<XTagFile>();

        if(staticResources.size() > 0){
            System.debug('Found' + staticResources.size() + ' static_resources');
            for (StaticResource staticResource: staticResources){
                XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResource.Body.toString(), XTagFile.class);

                System.debug('Found Static Resource ID: ' + staticResource.Id + ', with name: '+ xTagFile.name); 
                githubRepositoryUrls.add(xTagFile.githubRepositoryUrl);
                xTagFiles.add(xTagFile);
            }

            List<Demo_Component__c> demoComponents = [SELECT Id, Name, Github_Repository_URL__c, Title__c, Installed__c, Source_Installed_Commit_Hash__c, Source_Installed_Tag_Hash__c FROM Demo_Component__c WHERE Github_Repository_URL__c IN: githubRepositoryUrls];       
            
            if(demoComponents.size() > 0){
                System.debug('Found' + demoComponents.size() + ' Demo Components');
                for (XTagFile xTagFile: xTagFiles){
                    xTagFile.demoComponentAlreadyExistsFlag = false;
                    xTagFile.demoComponentAlreadyInstalledFlag = false;
                    for (Demo_Component__c demoComponent: demoComponents){
                        if (xTagFile.githubRepositoryUrl == demoComponent.Github_Repository_URL__c){
                            System.debug('Existing demo component ' + demoComponent.Title__c + ' Is a match to this XTag File');
                            xTagFile.demoComponentAlreadyExistsFlag = true;
                            if (demoComponent.Installed__c){
                                System.debug('Component is already marked as installed');
                                xTagFile.demoComponentAlreadyInstalledFlag = true;
                            }
                        }
                    }
                }
            }

            for(XTagFile xTagFile: xTagFiles){
                if(!xTagFile.demoComponentAlreadyExistsFlag){
                    System.debug('Repository ' + xTagFile.githubRepositoryUrl + ' Does not match an existing component, creating a new one');
                    getComponentFromGithubURL(xTagFile.githubRepositoryUrl, new map<String,String>{'installDate'=>string.valueOfGmt(xTagFile.installDateTime), 'installedFlag'=>'true', 'installType' => xTagFile.installType, 'commitHash' => xTagFile.commitHash});
                }
            }
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
}