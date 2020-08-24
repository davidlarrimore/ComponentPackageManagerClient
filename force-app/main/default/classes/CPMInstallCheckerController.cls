public with sharing class CPMInstallCheckerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getInstalledComponents(){ 
        System.debug('Running CPMInstallCheckerController.getInstalledComponents');
        
        VersionHelper.getInstalledPackages();
        List<Demo_Component__c> installedPackages = new List<Demo_Component__c>([SELECT Id, Installed__c, Title__c, Source_Install_Type_Flag__c, Package_Install_Type_Flag__c, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Install_Key__c, Source_Install_Url__c, Package_Install_Url__c FROM Demo_Component__c WHERE Installed__c = true]);
        if(installedPackages.size() > 0){
            system.debug('found the following installed packages: ' + installedPackages);
            return installedPackages;
        }else{
            system.debug('Did not find any installed pakages');
        }
        return null;
    }


}
