public with sharing class CpmRefreshCheckerController {

    @AuraEnabled
    public static void runApex(String demoComponentId, boolean forcedRefresh){ 
        System.debug('Running CMPRefreshCheckerController.runApex');
        System.debug('Demo Component ID ' + demoComponentId);
        System.debug('Forced Refresh is ' + forcedRefresh);

        //TODO: CHECK TO SEE IF COMPONENT IS INSTALLED AND REFRESH
        List<Demo_Component__c> demoComponent = [SELECT Id, Last_Fetched__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        DateTime now = datetime.now();
        DateTime yesterday = now.addDays(-1);
        if(demoComponent.size() > 0){
            System.debug('Found Demo Component!');
            if(demoComponent[0].Last_Fetched__c < yesterday || demoComponent[0].Last_Fetched__c == null || forcedRefresh){
                System.debug('Running Refresh!');
                VersionHelper.RefreshComponent(demoComponentId);                   
            }
        }
    }
}