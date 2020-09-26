public with sharing class CpmRefreshCheckerController {

    @AuraEnabled
    public static List<ID> runApex(String demoComponentId){ 
        System.debug('Running CMPRefreshCheckerController.runApex');
        List<ID> jobIds = new List<ID>();
        ID jobId;

        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){

            if(demoComponent[0].SFDX_Package_Enabled_Flag__c){
                QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(demoComponentId, demoComponent[0].Github_Repository_URL__c); 
                List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentFromSFDXJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
                if (existingJobs.size() == 0){
                    jobId = System.enqueueJob(queueUpdateComponentFromSFDXJob);
                    queueUpdateComponentFromSFDXJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);
                    QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentFromSFDXJob.GetJobInfo());
                    jobIds.add(jobId);    
                }else{
                    jobIds.add(existingJobs[0].Id); 
                }
            }

            if(demoComponent[0].Source_Install_Type_Flag__c){
                QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(demoComponentId, new Map<String,String>{});   
                List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentSourceCommitInfoJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
                if (existingJobs.size() == 0){
                    jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
                    queueUpdateComponentSourceCommitInfoJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);                    
                    QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentSourceCommitInfoJob.GetJobInfo());
                    jobIds.add(jobId);    
                }else{
                    jobIds.add(existingJobs[0].Id);                  
                }
                
                QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(demoComponentId); 
                existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentSourceTagInfoJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
                if (existingJobs.size() == 0){
                    jobId = System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
                    queueUpdateComponentSourceTagInfoJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, jobId);                   
                    QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentSourceTagInfoJob.GetJobInfo());
                    jobIds.add(jobId);    
                }else{
                    jobIds.add(existingJobs[0].Id);
                }
            }
    
        }

        return jobIds;
    }
}
