public class QueueUpdateComponentSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    Id demoComponentId = null;
    
    
    public QueueUpdateComponentSourceCommitInfo(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }


    public void execute(QueueableContext context) {
       System.debug('Running updateComponentSourceCommitInfo');  
        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c, Installed_Version_Tracking_Method__c, Source_Installed_Commit_Hash__c, Installed__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){
            System.debug('Processing ' + demoComponent[0].Github_Repository_URL__c);   
            List<GithubRepoCommit> githubCommits = GithubAPIHelper.getGithubCommits(demoComponent[0].Github_Repository_URL__c);

            if(githubCommits != null && githubCommits.size() > 0){
                for(GithubRepoCommit thisCommit: githubCommits){
                    if (thisCommit.latestCommitFlag){
                        demoComponent[0].Latest_Commit_DateTime__c = thisCommit.commitInfo.committer.commitDate;
                        demoComponent[0].Latest_Commit_Description__c = thisCommit.commitInfo.message;
                        demoComponent[0].Latest_Commit_Hash__c = thisCommit.sha;

                        //If not an SFDX Based project, we assume POC information is not there, grabbing commit author info;
                        if (!demoComponent[0].SFDX_Package_Enabled_Flag__c){
                            GithubUser githubUser = GithubAPIHelper.getGithubUser(thisCommit.author.url);
                            demoComponent[0].POC_Name__c = githubUser.name;
                            demoComponent[0].POC_Email__c = githubUser.email;
                        }

                        if(demoComponent[0].Installed__c){
                            System.debug('Checking to see if update is available');
                            if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Github_Commit' && demoComponent[0].Source_Installed_Commit_Hash__c != thisCommit.sha){
                                System.debug('Update Available');
                                demoComponent[0].Update_Available__c = true;
                            }
                        }
                        update demoComponent[0];
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
