public with sharing class CpmComponentInstallCheckerController {
    
    @AuraEnabled
    public static void runApex(){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<AsyncApexJob> existingJobs;

        QueueGetInstalledPackages queueGetInstalledPackagesJob = new QueueGetInstalledPackages();
        existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueGetInstalledPackagesJob.getJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME) LIMIT 1];
        if (existingJobs.size() == 0){
            System.debug('Running queueGetInstalledPackagesJob');
            System.enqueueJob(queueGetInstalledPackagesJob);
        }

        VersionHelper.getinstalledXTAGs(null);
    }
}