public with sharing class vfGetPackageFromGithubURL {
    @InvocableMethod
    public static List<GPBU_Package__c> vfGetPackageFromGithubURL(List<String> githubUrls){
        List<GPBU_Package__c> gpbuPackages = new List<GPBU_Package__c>();
        GPBU_Package__c gpbuPackage = new GPBU_Package__c();
        for(String githubUrl: githubUrls){
            gpbuPackages.add(VersionHelper.addGithubPackage(githubUrl));
        }
        return gpbuPackages; 
    }
    
}
