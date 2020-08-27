public with sharing class CMPRefreshCheckerController {
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static Demo_Component__c runApex(String searchKey){ 
        System.debug('Running CMPRefreshCheckerController.runApex');

        
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>([SELECT Id, Installed__c, Title__c, Source_Install_Type_Flag__c, Package_Install_Type_Flag__c, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Install_Key__c, Source_Install_Url__c, Package_Install_Url__c FROM Demo_Component__c WHERE Id = :searchKey LIMIT 1]);
        if(demoComponents.size() > 0){
            VersionHelper.componentUpdateCheck(demoComponents[0].Id);
            system.debug('found Demo Component: ' + demoComponents[0]);
            return demoComponents[0];
        }else{
            system.debug('Did not find the component');
        }
        return null;
    }
}
