public with sharing class PackageInstallerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static list<GPBU_Package__c> getDependentPackages(String searchKey){
        List<Package_Dependency__c> packageDependencies = new List<Package_Dependency__c>([SELECT Dependent_Package__c FROM Package_Dependency__c WHERE GPBU_Package__c = :searchKey ]);
        Set<Id> Ids = new Set<Id>();
        for(Package_Dependency__c packageDependency:packageDependencies){
            Ids.add(packageDependency.Dependent_Package__c);
        }   
        List<GPBU_Package__c> dependentPackages = new List<GPBU_Package__c>([SELECT Id, Installed__c, Title__c, Source_Install_Type_Flag__c, Package_Install_Type_Flag__c, Github_Repository__c, Latest_Subscriber_Package_Version_Id__c, Install_Key__c, Source_Install_Url__c, Package_Install_Url__c FROM GPBU_Package__c WHERE Id in :Ids]);
        system.debug('found the following packages');
        system.debug(dependentPackages);
        return dependentPackages;
    }

}
