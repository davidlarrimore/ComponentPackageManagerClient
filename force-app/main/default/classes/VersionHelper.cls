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
        String jobId = QueuePlatformEventHelper.generateId();

        System.debug('VersionHelper.AddGithubComponent.runApex');  
        System.debug('Processing ' + githubUrl);

        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Add Demo Component from Github Repository', 
            QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformEventHelper.STAGE_PROCESSING
        };
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);

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


            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_PROCESSING);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Created new Demo Component, and performing post processing!',
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});     


            if(options.containsKey('xTagFile')){
                QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID), demoComponent.Id, options.get('xTagFile')); 
                System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 
            }

            QueueUpdateComponentFromGithubUser queueUpdateComponentFromGithubUserJob = new QueueUpdateComponentFromGithubUser(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            System.enqueueJob(queueUpdateComponentFromGithubUserJob);

            QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id); 
            System.enqueueJob(queueUpdateComponentFromSFDXJob);
            
            QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id, new Map<String,String>{});   
            System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);

            QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
                 
        }else{
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component already exists',
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_INFO});               
        }

    }


    @future(callout=true)
    public static void getInstalledSalesforcePackages(){
      System.debug('Running VersionHelper.getInstalledSalesforcePackages');
        String jobId = QueuePlatformEventHelper.generateId();
        
        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Get Installed Salesforce Packages', 
            QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformEventHelper.STAGE_PROCESSING
        };

        List<String> recordsToProcess = new List<String>();
        List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = MetadataAPIHelper.getInstalledPackages();
        if (metadataInstalledPackageResponseRecords != null) {
          system.debug('Found ' + metadataInstalledPackageResponseRecords.size() + ' Installed Packages. Processing...');
          for (MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord : metadataInstalledPackageResponseRecords) {
            VersionHelper.processInstalledSalesforcePackages(jobInfo, JSON.serialize(metadataInstalledPackageResponseRecord));
          }
        }
    
        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);   
    }
    


    public static void processInstalledSalesforcePackages(Map<String,String> jobInfo, String metadataInstalledPackageResponseRecordJSON){
      System.debug('Running VersionHelper.processInstalledSalesforcePackages');
      MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = (MetadataInstalledPackageResponseRecord)System.JSON.deserialize(metadataInstalledPackageResponseRecordJSON, MetadataInstalledPackageResponseRecord.class);
      Demo_Component__c demoComponent = new Demo_Component__c();
      List<Demo_Component__c> demoComponentLookup = [
        SELECT
          Id,
          Latest_Subscriber_Package_Version_Id__c,
          Title__c,
          Installed__c,
          Package_Installed_Subscriber_Version_Id__c,
          Subscriber_Package_Id__c,
          Package_Install_Type_Flag__c
        FROM Demo_Component__c
        WHERE
          Subscriber_Package_Id__c = :metadataInstalledPackageResponseRecord.subscriberPackage.Id
        LIMIT 1
      ];
  
        //TODO:GET INSTALL DATE FROM METADATA API.....

        Boolean existsFlag = false;
        if(demoComponentLookup.size() > 0){
          demoComponent = demoComponentLookup[0];
          System.debug('Found the Demo_Component__c that matches the MetadataInstalledPackageResponseRecord...Proessing');

          System.debug('Found the Demo_Component__c that matches the MetadataInstalledPackageResponseRecord...Proessing');
          existsFlag = true;
          if(!demoComponent.Installed__c){
            System.debug('Demo Component was not installed previously, marking as installed');
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Newly Installed Demo Component Found...',
            QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});   


            demoComponent.Installed__c = true;
            demoComponent.Package_Installed_Subscriber_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
            demoComponent.Package_Installed_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
            demoComponent.Package_Installed_Version_Number__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
            demoComponent.Installation_Type__c = 'Package';
            demoComponent.Installed_Version_Tracking_Method__c = 'None';
            update demoComponent;
            
          }else if(demoComponent.Installed__c && demoComponent.Package_Installed_Subscriber_Version_Id__c != metadataInstalledPackageResponseRecord.subscriberPackageVersion.id){
            System.debug('Demo Component was previously installed and it appears to be updated....');

            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found Updated Demo Component.',
            QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});   

            demoComponent.Package_Installed_Subscriber_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
            demoComponent.Package_Installed_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
            demoComponent.Package_Installed_Version_Number__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
            update demoComponent;
          }else{
            System.debug('Everything matches up, we dont need to do anything');
          }

        }else{

          System.debug('No Demo Component found for ' + metadataInstalledPackageResponseRecord.subscriberPackage.name + ' installed package, creating a new one...');
          demoComponent.Package_Install_Type_Flag__c = true;
          demoComponent.Title__c = metadataInstalledPackageResponseRecord.subscriberPackage.name;
          demoComponent.Description__c = metadataInstalledPackageResponseRecord.subscriberPackage.description;
          demoComponent.Installed__c = true;
          demoComponent.Package_Installed_Subscriber_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
          demoComponent.Package_Installed_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
          demoComponent.Package_Installed_Version_Number__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
          demoComponent.Installation_Type__c = 'Package';
          demoComponent.Installed_Version_Tracking_Method__c = 'None';

          demoComponent.Subscriber_Package_Id__c = metadataInstalledPackageResponseRecord.subscriberPackage.id;
          demoComponent.Package_Name__c = metadataInstalledPackageResponseRecord.subscriberPackage.name;
          demoComponent.Latest_Subscriber_Package_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
          demoComponent.Latest_Package_Version__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
          demoComponent.Latest_Package_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
          demoComponent.Last_Fetched__c = Datetime.Now();

          insert demoComponent;


          QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found New Demo Component Installed.',
          QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});       

        }

        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);   
    }







    public static void RefreshComponent(String demoComponentId){
        System.debug('Running VersionHelper.RefreshComponent');

        String jobId = QueuePlatformEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Refresh Demo Component Info', 
            QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformEventHelper.STAGE_PROCESSING
        };
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);


        List<Demo_Component__c> demoComponentSearch = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponentSearch.size() > 0){
            Demo_Component__c demoComponent = demoComponentSearch[0];

            QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(jobId, demoComponentId); 
            List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentFromSFDXJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
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
        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    
    }    
    

    public static void getinstalledXTAGs(){
        String jobId = QueuePlatformEventHelper.generateId();

        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformEventHelper.STAGE_PROCESSING
        };

        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);

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

            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    
            
        }catch (Exception e) {
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
            QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});                
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

                    QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                        QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                        QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found Newly installed component, updating',
                        QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_INFO});  

                    QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                //Newer version was installed
                }else if (demoComponent.Installed__c && xTagFile.installDateTime > demoComponent.Install_Date__c){
                    System.debug('Component already installed and was probably updated. Component Install Date: ' + demoComponent.Install_Date__c + ', XTag InstallDate: ' + xTagFile.installDateTime);
                    demoComponent.Install_Date__c = xTagFile.installDateTime;
                    demoComponent.Installation_Type__c = 'Source';
                    demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';   
                    demoComponent.Update_Available__c = false;
                    
                    update demoComponent;  

                    QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                }else{
                    System.debug('XTag matches existing info, doing nothing');
                }

            }else{

                System.debug('Repository ' + xTagFile.githubRepositoryUrl + ' Does not match an existing component, creating a new one');

                QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                    QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                    QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found newly installed component!',
                    QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});  


                VersionHelper.AddGithubComponent(xTagFile.githubRepositoryUrl, new map<String,String>{'xTagFile'=>xTagJSON});
            }

            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    

        }catch (Exception e) {
            System.debug(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());   

            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);

            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Failed Notification',
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
            QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});                
        }  
    }







}