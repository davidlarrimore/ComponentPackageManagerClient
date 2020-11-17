public with sharing class CpmRefreshCheckerController {

    @AuraEnabled
    public static void runApex(String demoComponentId, boolean forcedRefresh){ 
        System.debug('Running CpmRefreshCheckerController.runApex');
        System.debug('Demo Component ID ' + demoComponentId);
        System.debug('Forced Refresh is ' + forcedRefresh);

        //TODO: CHECK TO SEE IF COMPONENT IS INSTALLED AND REFRESH
        List<Cpm_Component_Package__c> demoComponent = [SELECT Id, Last_Fetched__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];
        DateTime now = datetime.now();
        DateTime yesterday = now.addDays(-1);
        if(demoComponent.size() > 0){
            System.debug('Found Demo Component!');
            if(demoComponent[0].Last_Fetched__c < yesterday || demoComponent[0].Last_Fetched__c == null || forcedRefresh){
                System.debug('Running Refresh!');
                CpmVersionHelper.RefreshComponent(demoComponentId);                   
            }
        }
    }
}