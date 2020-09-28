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
        ID jobId = QueuePlatformEventHelper.generateId();

        System.debug('CpmAddGithubComponentController.runApex');  
        System.debug('Processing ' + githubUrl);

        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformEventHelper.FIELD_JOB_NAME =>  'VersionHelper', 
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

            insert demoComponent;

            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_PROCESSING);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Created new Demo Component, and performing post processing!',
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});     


            QueueUpdateComponentFromGithubUser queueUpdateComponentFromGithubUserJob = new QueueUpdateComponentFromGithubUser(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            jobId = System.enqueueJob(queueUpdateComponentFromGithubUserJob);

            QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id, githubUrl); 
            jobId = System.enqueueJob(queueUpdateComponentFromSFDXJob);
            
            QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id, new Map<String,String>{});   
            jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);

            QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            jobId = System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
                 
        }else{
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component already exists',
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_INFO});               
        }

    }


    public static void RefreshComponent(String demoComponentId){
        ID jobId = QueuePlatformEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformEventHelper.FIELD_JOB_NAME =>  'VersionHelper', 
            QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformEventHelper.STAGE_PROCESSING
        };
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);


        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){

            if(demoComponent[0].SFDX_Package_Enabled_Flag__c){
                QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(jobId, demoComponentId, demoComponent[0].Github_Repository_URL__c); 
                List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentFromSFDXJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
                if (existingJobs.size() == 0){
                    jobId = System.enqueueJob(queueUpdateComponentFromSFDXJob);
                }
            }

            if(demoComponent[0].Source_Install_Type_Flag__c){
                QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(jobId, demoComponentId, new Map<String,String>{});   
                jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
                
                QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(jobId, demoComponentId); 
                jobId = System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
            }
    
        }

        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    
    }    
    
}