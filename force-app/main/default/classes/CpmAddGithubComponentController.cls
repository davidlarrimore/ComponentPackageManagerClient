public with sharing class CpmAddGithubComponentController {
    @AuraEnabled
    public String githubUrl { get; set; }

    @AuraEnabled
    public static Demo_Component__c runApex(string githubUrl){ 
        return VersionHelper.getComponentFromGithubURL(githubUrl, new map<String,String>{});
    }


}
