public with sharing class CpmComponentInstallerController {

    @AuraEnabled(cacheable=true)
    public static list<Cpm_Component_Package__c> getDependentPackages(String demoComponentId){
        System.debug('Running CpmComponentInstallerController.runApex');
        List<Cpm_Component_Package_Dependency__c> packageDependencies = new List<Cpm_Component_Package_Dependency__c>([SELECT Dependent_Component_Package__c FROM Cpm_Component_Package_Dependency__c WHERE Cpm_Component_Package__c = :demoComponentId ]);
        Set<Id> Ids = new Set<Id>();
        for(Cpm_Component_Package_Dependency__c packageDependency:packageDependencies){
            Ids.add(packageDependency.Dependent_Component_Package__c);
        }   
        List<Cpm_Component_Package__c> dependentPackages = new List<Cpm_Component_Package__c>([SELECT Id, Installed__c, Title__c, Source_Install_Type_Flag__c, Package_Install_Type_Flag__c, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Install_Key__c, Source_Install_Url__c, Subscriber_Package_Id__c, Latest_Package_Version_Deprecated_Flag__c, Package_Install_Url__c FROM Cpm_Component_Package__c WHERE Id in :Ids]);
        system.debug('found the following packages');
        system.debug(dependentPackages);
        return dependentPackages;
    }

}