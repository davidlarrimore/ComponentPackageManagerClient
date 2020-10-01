public class QueueUpdateComponentSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Update Component Source Commit Info', 
        QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => QueueUpdateComponentSourceCommitInfo.class.getName()
    };

    public Map<String,String> GetJobInfo() {
        return this.jobInfo;
    }    

    public String GetJobInfo(String key) {
        return this.jobInfo.get(key);
    }

    public void SetJobInfo(String key, String value) {
        this.jobInfo.put(key, value);
    }

    public void SetJobStage(String value) {
        this.jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, value);  
    }   

    /*************QUEUEABLE SPECIFIC VARIABLES / FUNCTIONS*************/
    Id demoComponentId = null;
    Map<String,String> options = new Map<String,String>();   

    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentSourceCommitInfo(String parentJobId, Id demoComponentId, Map<String,String> options) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId());  
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());        
        this.demoComponentId = demoComponentId;
        this.options = options;  
    }

    public QueueUpdateComponentSourceCommitInfo(Id demoComponentId, Map<String,String> options) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId());  
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED);   
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());   
        this.demoComponentId = demoComponentId;
        this.options = options;  
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
        
        System.debug('Processing QueueUpdateComponentSourceCommitInfo');   
        doLater(this.jobInfo, this.demoComponentId, this.options);

    }

    @future(callout=true)
    private static void doLater(Map<String, String> jobInfo, Id demoComponentId, Map<String,String> options) {
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        try {
        System.debug('Running updateComponentSourceCommitInfo');  
        List<Demo_Component__c> demoComponentSearch = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c, Installed_Version_Tracking_Method__c, Source_Installed_Commit_Hash__c, Installed__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponentSearch.size() > 0){
            Demo_Component__c demoComponent = demoComponentSearch[0];
            System.debug('Processing ' + demoComponent.Github_Repository_URL__c);   
            githubCommit = GithubAPIHelper.getGithubCommit(demoComponent.Github_Repository_URL__c, new Map<String,String>());

            if(githubCommit != null){
                demoComponent.Latest_Commit_DateTime__c = githubCommit.commitInfo.committer.commitDate;
                demoComponent.Latest_Commit_Description__c = githubCommit.commitInfo.message;
                demoComponent.Latest_Commit_Hash__c = githubCommit.sha;


                if(demoComponent.Installed__c){
                    System.debug('Checking to see if update is available');
                    System.debug('Source_Installed_Commit_Hash__c: ' + demoComponent.Source_Installed_Commit_Hash__c + ', githubCommit.sha: ' + githubCommit.sha);
                    if(demoComponent.Installed_Version_Tracking_Method__c == 'Github_Commit' && demoComponent.Source_Installed_Commit_Hash__c != null && demoComponent.Source_Installed_Commit_Hash__c != githubCommit.sha){
                        
                        System.debug('Update Available');
                        demoComponent.Update_Available__c = true;
                    }else{
                        demoComponent.Update_Available__c = false;
                    }
                }

                update demoComponent;  
            }else{
                System.debug('No Commits found');  
            }
        }else{
            System.debug('Could not find Component ' + demoComponentId);   
        }

        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    

    }catch (Exception e) {
        System.debug(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());   

        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Failed Notification',
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
          QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});     
    }           
    }

}
