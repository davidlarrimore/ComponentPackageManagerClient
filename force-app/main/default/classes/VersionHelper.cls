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

    public static void AddGithubComponent(String githubUrl, Map<String,String> options){
        String jobId = QueuePlatformAsyncEventHelper.generateId();

        System.debug('VersionHelper.AddGithubComponent.runApex');  
        System.debug('Processing ' + githubUrl);

        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Add Demo Component from Github Repository', 
            QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformAsyncEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformAsyncEventHelper.STAGE_PROCESSING
        };
        QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);

        System.debug('Seeing if Package already exists');
        List<Demo_Component__c> existingPackageLookup = [SELECT Id, Source_Install_Type_Flag__c, Latest_Subscriber_Package_Version_Id__c, Package_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Github_Repository_URL__c = :githubUrl LIMIT 1];
        if(existingPackageLookup.size() == 0){

            System.debug('Nope....Inserting New Package');
            Demo_Component__c demoComponent = new Demo_Component__c();
            demoComponent.Github_Repository_URL__c = githubUrl;

            String tempName = githubUrl.substring(githubUrl.lastIndexOf('/')+1, githubUrl.length());
            tempName = tempName.replace('_', ' ');
            tempName = tempName.replace('-', ' ');
            demoComponent.Title__c = tempName;
            demoComponent.Source_Install_Type_Flag__c = true;


            //XTAG file was included, meaning it was installed, Updating
            if(options.containsKey('xTagFile')){
                XTagFile xTagFile = (XTagFile)System.JSON.deserialize(options.get('xTagFile'), XTagFile.class);
                System.debug('Existing demo component ' + demoComponent.Title__c + ' Is a match to this XTag File');
                demoComponent.Installed__c = true;
                demoComponent.Install_Date__c = xTagFile.installDateTime;
                demoComponent.Installation_Type__c = 'Source';
                demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';   
                
                
            }                              
 
            demoComponent.Last_Fetched__c = datetime.now();

            insert demoComponent;   

            if(options.containsKey('xTagFile')){
              XTagFile xTagFile = (XTagFile)System.JSON.deserialize(options.get('xTagFile'), XTagFile.class);
              QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
              System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob);   
            }

            QueueUpdateComponentFromGithubUser queueUpdateComponentFromGithubUserJob = new QueueUpdateComponentFromGithubUser(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            System.enqueueJob(queueUpdateComponentFromGithubUserJob);

            QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id); 
            System.enqueueJob(queueUpdateComponentFromSFDXJob);
            
            QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id, new Map<String,String>{});   
            System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);

            QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
            
            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Added new Demo Component "' + demoComponent.Title__c + '". performing Post Processing!',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS
            });                

            QueueComponentUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
              QueueComponentUpdateEventHelper.FIELD_UPDATE_FLAG => QueueComponentUpdateEventHelper.FLAG_TRUE,
              QueueComponentUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
            });               
        }else{
            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component already exists',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_INFO});               
        }

    }


    public static void RefreshComponent(String demoComponentId){
        System.debug('Running VersionHelper.RefreshComponent');

        String jobId = QueuePlatformAsyncEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Refresh Demo Component Info', 
            QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformAsyncEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformAsyncEventHelper.STAGE_PROCESSING
        };
        QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);


        //FIRST THING WE DO IS CHECK TO SEE IF PACKAGES WERE ALREADY INSTALLED
        QueueGetInstalledPackages queueGetInstalledPackagesJob = new QueueGetInstalledPackages();
        List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueGetInstalledPackagesJob.getJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME) LIMIT 1];
        if (existingJobs.size() == 0){
            System.debug('Running queueGetInstalledPackagesJob');
            System.enqueueJob(queueGetInstalledPackagesJob);
        }

        VersionHelper.getinstalledXTAGs();




        List<Demo_Component__c> demoComponentSearch = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponentSearch.size() > 0){
            Demo_Component__c demoComponent = demoComponentSearch[0];

            QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(jobId, demoComponentId); 
            existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentFromSFDXJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
            if (existingJobs.size() == 0){
                jobId = System.enqueueJob(queueUpdateComponentFromSFDXJob);
            }


            if(demoComponent.Source_Install_Type_Flag__c){
                QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(jobId, demoComponentId, new Map<String,String>{});   
                jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
                
                QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(jobId, demoComponentId); 
                jobId = System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
            }
            demoComponent.Last_Fetched__c = datetime.now();
            update demoComponent;
        }
        jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);    
    }    
    

    public static void getinstalledXTAGs(){
        String jobId = QueuePlatformAsyncEventHelper.generateId();

        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformAsyncEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformAsyncEventHelper.STAGE_PROCESSING
        };

        QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);

        try {
            List<StaticResource> staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'XTAG%'];
            List<XTagFile> xTagFiles = new List<XTagFile>();

            if(staticResources.size() > 0){
                System.debug('Found' + staticResources.size() + ' static_resources');
                for (StaticResource staticResource: staticResources){
                    XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResource.Body.toString(), XTagFile.class);
                    System.debug('Found Static Resource ID: ' + staticResource.Id + ', with name: '+ xTagFile.name); 
                    xTagFiles.add(xTagFile);
                }

                for (XTagFile xTagFile: xTagFiles){
                    VersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile)); 
                }
            }

            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);    
            
        }catch (Exception e) {
            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_FAILED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
            QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
            QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_ERROR});                
        }  
    }

    
   private static void processXTag(Map<String, String> jobInfo, String xTagJSON){
       try {

            XTagFile xTagFile = (XTagFile)System.JSON.deserialize(xTagJSON, XTagFile.class);

            List<Demo_Component__c> demoComponentSearch = [SELECT Id, Name, Github_Repository_URL__c, Title__c, Update_Available__c, Install_Date__c, Installed__c, Source_Installed_Commit_Hash__c, Source_Installed_Tag_Hash__c FROM Demo_Component__c WHERE Github_Repository_URL__c = :xTagFile.githubRepositoryUrl LIMIT 1];       
            if(demoComponentSearch.size() > 0){
                Demo_Component__c demoComponent = demoComponentSearch[0];
                xTagFile.demoComponentAlreadyExistsFlag = false;

                System.debug('Existing demo component ' + demoComponent.Title__c + ' Is a match to this XTag File');
                //Component was not installed, and now is....
                if(!demoComponent.Installed__c){
                    System.debug('Marking Demo Component as Installed');
                    demoComponent.Installed__c = true;
                    demoComponent.Install_Date__c = xTagFile.installDateTime;
                    demoComponent.Installation_Type__c = 'Source';
                    demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';  
                    demoComponent.Update_Available__c = false;

                    update demoComponent;  

                    QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                      QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                      QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component ' + demoComponent.Title__c + ' was installed. Updating',
                      QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS
                    });  

                    QueueComponentUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
                      QueueComponentUpdateEventHelper.FIELD_UPDATE_FLAG => QueueComponentUpdateEventHelper.FLAG_TRUE,
                      QueueComponentUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
                    });
                        
                    QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                //Newer version was installed
                }else if (demoComponent.Installed__c && xTagFile.installDateTime > demoComponent.Install_Date__c){
                    System.debug('Component already installed and was probably updated. Component Install Date: ' + demoComponent.Install_Date__c + ', XTag InstallDate: ' + xTagFile.installDateTime);
                    demoComponent.Install_Date__c = xTagFile.installDateTime;
                    demoComponent.Installation_Type__c = 'Source';
                    demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';   
                    demoComponent.Update_Available__c = false;
                    
                    update demoComponent;  

                    QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                      QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                      QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'It looks like Demo Component ' + demoComponent.Title__c + ' was updated! Congratulations.',
                      QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS
                    });  

                    QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                }else{
                    System.debug('XTag matches existing info, doing nothing');
                }

            }else{

                System.debug('Repository ' + xTagFile.githubRepositoryUrl + ' Does not match an existing component, creating a new one');

                QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                    QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                    QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found newly installed component!',
                    QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS});  


                VersionHelper.AddGithubComponent(xTagFile.githubRepositoryUrl, new map<String,String>{'xTagFile'=>xTagJSON});
            }

            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);    

        }catch (Exception e) {
            System.debug(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());   

            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_FAILED);

            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Failed Notification',
            QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
            QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_ERROR});                
        }  
    }







}