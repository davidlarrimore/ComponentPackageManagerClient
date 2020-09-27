public with sharing class CpmAddGithubComponentController {
    @AuraEnabled
    public String githubUrl { get; set; }

    @AuraEnabled
    public static List<ID> runApex(string githubUrl){ 
        List<ID> jobIds = new List<ID>();
        ID jobId;
        System.debug('CpmAddGithubComponentController.runApex');  
        System.debug('Processing ' + githubUrl);

        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformEventHelper.FIELD_JOB_NAME =>  'CpmAddGithubComponentController', 
            QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => CpmAddGithubComponentController.class.getName(),
            QueuePlatformEventHelper.FIELD_JOB_ID => QueuePlatformEventHelper.generateId(),
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
            queueUpdateComponentFromGithubUserJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId); 
            QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentFromGithubUserJob.GetJobInfo());


            QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id, githubUrl); 
            jobId = System.enqueueJob(queueUpdateComponentFromSFDXJob);
            queueUpdateComponentFromSFDXJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);
            QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentFromSFDXJob.GetJobInfo());
   
            
            QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id, new Map<String,String>{});   
            jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
            queueUpdateComponentSourceCommitInfoJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);  
            QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentSourceCommitInfoJob.GetJobInfo());
             

            QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            jobId = System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
            queueUpdateComponentSourceTagInfoJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);  
            QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentSourceTagInfoJob.GetJobInfo());
                 
        }else{
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component already exists',
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_INFO});               
        }


        return jobIds;
    }


}
