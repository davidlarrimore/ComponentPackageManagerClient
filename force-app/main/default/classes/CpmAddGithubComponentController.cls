public with sharing class CpmAddGithubComponentController {

    @AuraEnabled
    public static void runApex(string githubUrl){ 
        System.debug('CpmAddGithubComponentController.runApex');  
        System.debug('Processing ' + githubUrl);

        CpmVersionHelper.AddGithubComponent(githubUrl, new Map<String,String>());

    }


}