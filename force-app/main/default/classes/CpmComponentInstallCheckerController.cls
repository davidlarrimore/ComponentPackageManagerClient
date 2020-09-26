public with sharing class CpmComponentInstallCheckerController {
    
    @AuraEnabled
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<ID> jobIds = new List<ID>();
        ID jobId;
        List<AsyncApexJob> existingJobs;

        QueueGetInstalledPackages updateJob = new QueueGetInstalledPackages();
        existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :updateJob.getJobInfo('ApexClassName') LIMIT 1];
        if (existingJobs.size() == 0){
            jobId = System.enqueueJob(updateJob);
            jobIds.add(jobId);
            
            EventBus.publish(new CPM_Async_Event__e(
                ApexClass_Name__c = updateJob.getJobInfo('ApexClassName'),
                AsyncApexJob_Id__c = jobId,
                AsyncApexJob_Name__c = updateJob.getJobInfo('jobName'),
                AsyncApexJob_Status__c = 'Queued',
                Send_Toast__c = false
            ));  



        }else{
            jobIds.add(existingJobs[0].Id);

            EventBus.publish(new CPM_Async_Event__e(
                ApexClass_Name__c = updateJob.getJobInfo('ApexClassName'),
                AsyncApexJob_Id__c = existingJobs[0].Id,
                AsyncApexJob_Name__c = updateJob.getJobInfo('jobName'),
                AsyncApexJob_Status__c = 'Processing',
                Send_Toast__c = false
            ));                  
        }
    


        QueueGetInstalledXTags updateXTAGJob = new QueueGetInstalledXTags();
        existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :updateXTAGJob.getJobInfo('ApexClassName') LIMIT 1];
        if (existingJobs.size() == 0){
            jobId = System.enqueueJob(updateXTAGJob);
            jobIds.add(jobId);
            
            EventBus.publish(new CPM_Async_Event__e(
                ApexClass_Name__c = updateXTAGJob.getJobInfo('ApexClassName'),
                AsyncApexJob_Id__c = jobId,
                AsyncApexJob_Name__c = updateXTAGJob.getJobInfo('jobName'),
                AsyncApexJob_Status__c = 'Queued',
                Send_Toast__c = false
            ));  



        }else{
            jobIds.add(existingJobs[0].Id);

            EventBus.publish(new CPM_Async_Event__e(
                ApexClass_Name__c = updateXTAGJob.getJobInfo('ApexClassName'),
                AsyncApexJob_Id__c = existingJobs[0].Id,
                AsyncApexJob_Name__c = updateXTAGJob.getJobInfo('jobName'),
                AsyncApexJob_Status__c = 'Processing',
                Send_Toast__c = false
            ));                  
        }
        return jobIds;
    }
}
