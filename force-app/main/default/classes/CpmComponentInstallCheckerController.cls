public with sharing class CpmComponentInstallCheckerController {
    
    @AuraEnabled
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<ID> jobIds = new List<ID>();
        ID jobId;
        List<AsyncApexJob> existingJobs;

        QueueGetInstalledPackages queueGetInstalledPackagesJob = new QueueGetInstalledPackages();
        existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueGetInstalledPackagesJob.getJobInfo(QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME) LIMIT 1];
        if (existingJobs.size() == 0){
            System.debug('Running queueGetInstalledPackagesJob');
            jobId = System.enqueueJob(queueGetInstalledPackagesJob);
            jobIds.add(jobId);    

        }else{
            jobIds.add(existingJobs[0].Id);              
        }
    


        QueueGetInstalledXTags queueGetInstalledXTagsJob = new QueueGetInstalledXTags();
        existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueGetInstalledXTagsJob.getJobInfo(QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME) LIMIT 1];
        if (existingJobs.size() == 0){
            System.debug('Running queueGetInstalledXTagsJob');
            jobId = System.enqueueJob(queueGetInstalledXTagsJob);
            jobIds.add(jobId);    
        }else{
            jobIds.add(existingJobs[0].Id);              
        }
        return jobIds;
    }
}
