public with sharing class CPMInstallCheckerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<ID> JobIDs = new List<ID>();
        List<Demo_Component__c> demoComponent = new List<Demo_Component__c>([SELECT Id, Installed__c, Title__c, Source_Install_Type_Flag__c, Package_Install_Type_Flag__c, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Install_Key__c, Source_Install_Url__c, Package_Install_Url__c FROM Demo_Component__c WHERE Installed__c = true]);
        if(demoComponent.size() > 0){
            QueueGetInstalledPackages updateJob = new QueueGetInstalledPackages();
            JobIDs.add(System.enqueueJob(updateJob));
        }
        return JobIDs;
    }


}
