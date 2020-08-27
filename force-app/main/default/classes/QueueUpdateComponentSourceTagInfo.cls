public class QueueUpdateComponentSourceTagInfo implements Queueable, Database.AllowsCallouts  {
    Id demoComponentId = null;
    

    public QueueUpdateComponentSourceTagInfo(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }


    public void execute(QueueableContext context) {
        System.debug('Running QueueUpdateComponentSourceTagInfo');  
        List<Demo_Component__c> gpbuPackage = [SELECT Id, Github_Repository_URL__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('Processing ' + gpbuPackage[0].Github_Repository_URL__c);   
            List<GithubRepoTag> githubTags = GithubAPIHelper.getGithubTags(gpbuPackage[0].Github_Repository_URL__c);

            if(githubTags != null && githubTags.size() > 0){
                for(GithubRepoTag thisTag: githubTags){
                    if (thisTag.latestTagFlag){
                        gpbuPackage[0].Latest_Tag_Commit_DateTime__c = thisTag.tagDate;
                        gpbuPackage[0].Latest_Tag_Commit_Description__c = thisTag.githubCommit.commitInfo.message;
                        gpbuPackage[0].Latest_Tag_Commit_Hash__c = thisTag.githubCommit.sha;
                        gpbuPackage[0].Latest_Tag_Version_Name__c = thisTag.name;
                        update gpbuPackage[0];
                    }
                }
            }else{
                System.debug('No Commits found');  
            }
        }else{
            System.debug('Could not find Component ' + gpbuPackage[0].Id);   
        }
 
      }
 




}
