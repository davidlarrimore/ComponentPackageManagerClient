public with sharing class CpmComponentInstallCheckerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<ID> JobIDs = new List<ID>();

        List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = 'QueueGetInstalledPackages'];
        if (existingJobs.size() == 0){
            QueueGetInstalledPackages updateJob = new QueueGetInstalledPackages();
            JobIDs.add(System.enqueueJob(updateJob));
        }

        
        VersionHelper.updateComponentFromXTag();

        return JobIDs;
    }


}
