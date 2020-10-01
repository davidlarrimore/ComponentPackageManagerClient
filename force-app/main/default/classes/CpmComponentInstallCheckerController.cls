public with sharing class CpmComponentInstallCheckerController {
    
    @AuraEnabled
    public static void runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<AsyncApexJob> existingJobs;

        VersionHelper.getInstalledSalesforcePackages();
    
        VersionHelper.getinstalledXTAGs();

    }
}
