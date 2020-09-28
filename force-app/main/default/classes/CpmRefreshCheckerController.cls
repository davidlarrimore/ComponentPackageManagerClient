public with sharing class CpmRefreshCheckerController {

    @AuraEnabled
    public static void runApex(String demoComponentId){ 
        System.debug('Running CMPRefreshCheckerController.runApex');

        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){
            VersionHelper.RefreshComponent(demoComponentId);
        }

    }
}
