public with sharing class CpmAddGithubComponentController {
    @AuraEnabled
    public String githubUrl { get; set; }

    @AuraEnabled
    public static void runApex(string githubUrl){ 
        System.debug('CpmAddGithubComponentController.runApex');  
        System.debug('Processing ' + githubUrl);

        VersionHelper.AddGithubComponent(githubUrl, new Map<String,String>());

    }


}
