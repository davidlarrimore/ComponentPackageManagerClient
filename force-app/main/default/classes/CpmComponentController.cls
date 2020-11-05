public with sharing class CpmComponentController {

    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getDemoComponents(){
        return [SELECT Id, Title__c, Name, Description__c, Package_Name__c, Installation_Type__c, Install_Date__c, Update_Available__c, Installed__c, POC_Email__c, POC_Name__c, Github_Repository_URL__c, Installed_Version__c, Latest_Package_Version_Deprecated_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c];
    }    

    @AuraEnabled
    public static list<Demo_Component__c> getInstalledComponents(){
        return [SELECT Id, Title__c, Name, Description__c, Package_Name__c, Installation_Type__c, Install_Date__c, Update_Available__c, Installed__c, POC_Email__c, POC_Name__c, Github_Repository_URL__c, Installed_Version__c, Latest_Package_Version_Deprecated_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Installed__c = true];
    }

    @AuraEnabled
    public static list<Demo_Component__c> getAvailableComponents(){
        return [SELECT Id, Title__c, Name, Description__c, Package_Name__c, Installation_Type__c,  Install_Date__c, Update_Available__c, Installed__c, POC_Email__c, POC_Name__c, Github_Repository_URL__c, Latest_Package_Version_Deprecated_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Installed__c = false];
    }    
}