public with sharing class CpmComponentInstallCheckerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<ID> JobIDs = new List<ID>();

        QueueGetInstalledPackages updateJob = new QueueGetInstalledPackages();
        JobIDs.add(System.enqueueJob(updateJob));
        

        VersionHelper.updateComponentFromXTag();

        return JobIDs;
    }


}
