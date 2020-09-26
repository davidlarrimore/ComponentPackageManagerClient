public with sharing class CpmComponentInstallCheckerController {
    
    @AuraEnabled
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<ID> jobIds = new List<ID>();
        ID jobId;
        List<AsyncApexJob> existingJobs;

        QueueGetInstalledPackages updateJob = new QueueGetInstalledPackages();
        existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :updateJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
        if (existingJobs.size() == 0){
            jobId = System.enqueueJob(updateJob);
            QueuePlatformEventHelper.publishPlatformEvent(updateJob.GetJobInfo());
            jobIds.add(jobId);    

        }else{
            jobIds.add(existingJobs[0].Id);              
        }
    


        QueueGetInstalledXTags updateXTAGJob = new QueueGetInstalledXTags();
        existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :updateXTAGJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
        if (existingJobs.size() == 0){
            jobId = System.enqueueJob(updateXTAGJob);
            QueuePlatformEventHelper.publishPlatformEvent(updateXTAGJob.GetJobInfo());
            jobIds.add(jobId);    
        }else{
            jobIds.add(existingJobs[0].Id);              
        }
        return jobIds;
    }
}
