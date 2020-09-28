public with sharing class CpmAddGithubComponentController {
    @AuraEnabled
    public String githubUrl { get; set; }

    @AuraEnabled
    public static List<ID> runApex(string githubUrl){ 
        List<ID> jobIds = new List<ID>();
        System.debug('CpmAddGithubComponentController.runApex');  
        System.debug('Processing ' + githubUrl);

        VersionHelper.AddGithubComponent(githubUrl, new Map<String,String>());

        return jobIds;
    }


}
