public class QueueUpdateComponentSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    Id demoComponentId = null;
    
    
    public QueueUpdateComponentSourceCommitInfo(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }


    public void execute(QueueableContext context) {
       System.debug('Running updateComponentSourceCommitInfo');  
        List<Demo_Component__c> gpbuPackage = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('Processing ' + gpbuPackage[0].Github_Repository_URL__c);   
            List<GithubRepoCommit> githubCommits = GithubAPIHelper.getGithubCommits(gpbuPackage[0].Github_Repository_URL__c);

            if(githubCommits != null && githubCommits.size() > 0){
                for(GithubRepoCommit thisCommit: githubCommits){
                    if (thisCommit.latestCommitFlag){
                        gpbuPackage[0].Latest_Commit_DateTime__c = thisCommit.commitInfo.committer.commitDate;
                        gpbuPackage[0].Latest_Commit_Description__c = thisCommit.commitInfo.message;
                        gpbuPackage[0].Latest_Commit_Hash__c = thisCommit.sha;

                        //If not an SFDX Based project, we assume POC information is not there, grabbing commit author info;
                        if (!gpbuPackage[0].SFDX_Package_Enabled_Flag__c){
                            GithubUser githubUser = GithubAPIHelper.getGithubUser(thisCommit.author.url);
                            gpbuPackage[0].POC_Name__c = githubUser.name;
                            gpbuPackage[0].POC_Email__c = githubUser.email;
                        }

                        update gpbuPackage[0];
                    }
                }
            }else{
                System.debug('No Commits found');  
            }
        }else{
            System.debug('Could not find Component ' + demoComponentId);   
        }

     }



}
