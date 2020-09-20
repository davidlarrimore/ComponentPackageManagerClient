public with sharing class CpmComponentController {

    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getDemoComponents(String recordId){
        return [SELECT Id, Title__c, Name, Description__c, Package_Name__c, Update_Available__c, Installed__c, POC_Email__c, POC_Name__c, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c];
    }    

    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getInstalledComponents(String recordId){
        return [SELECT Id, Title__c, Name, Description__c, Package_Name__c, Update_Available__c, Installed__c, POC_Email__c, POC_Name__c, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Installed__c = true];
    }

    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getAvailableComponents(String recordId){
        return [SELECT Id, Title__c, Name, Description__c, Package_Name__c, Update_Available__c, Installed__c, POC_Email__c, POC_Name__c, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Installed__c = false];
    }    
}
