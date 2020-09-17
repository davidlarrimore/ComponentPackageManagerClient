public with sharing class CpmComponentInstallerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getDependentPackages(String searchKey){
        List<Component_Dependency__c> packageDependencies = new List<Component_Dependency__c>([SELECT Dependent_Component__c FROM Component_Dependency__c WHERE Demo_Component__c = :searchKey ]);
        Set<Id> Ids = new Set<Id>();
        for(Component_Dependency__c packageDependency:packageDependencies){
            Ids.add(packageDependency.Dependent_Component__c);
        }   
        List<Demo_Component__c> dependentPackages = new List<Demo_Component__c>([SELECT Id, Installed__c, Title__c, Source_Install_Type_Flag__c, Package_Install_Type_Flag__c, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Install_Key__c, Source_Install_Url__c, Package_Install_Url__c FROM Demo_Component__c WHERE Id in :Ids]);
        system.debug('found the following packages');
        system.debug(dependentPackages);
        return dependentPackages;
    }

}
