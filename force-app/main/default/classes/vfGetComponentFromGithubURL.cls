public with sharing class vfGetComponentFromGithubURL {
    @InvocableMethod
    public static List<Demo_Component__c> vfGetComponentFromGithubURL(List<String> githubUrls){
        List<Demo_Component__c> gpbuPackages = new List<Demo_Component__c>();
        Demo_Component__c gpbuPackage = new Demo_Component__c();
        for(String githubUrl: githubUrls){
            gpbuPackages.add(VersionHelper.getComponentFromGithubURL(githubUrl));
        }
        return gpbuPackages; 
    }
    
}
