public class QueueUpdateComponentSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Update Component Source Commit Info', 
        QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => QueueUpdateComponentSourceCommitInfo.class.getName()
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
        this.jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, value);  
    }   

    /*************QUEUEABLE SPECIFIC VARIABLES / FUNCTIONS*************/
    Id demoComponentId = null;
    String commitHash;

    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentSourceCommitInfo(String parentJobId, Id demoComponentId) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId());  
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());        
        this.demoComponentId = demoComponentId;
    }

    public QueueUpdateComponentSourceCommitInfo(Id demoComponentId) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId());  
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED);   
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());   
        this.demoComponentId = demoComponentId;
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_PROCESSING);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        
        System.debug('Processing QueueUpdateComponentSourceCommitInfo');   
        doLater(this.jobInfo, this.demoComponentId);

    }

    @future(callout=true)
    @TestVisible 
    private static void doLater(Map<String, String> jobInfo, Id demoComponentId) {
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        try {
        System.debug('Running updateComponentSourceCommitInfo');  
        List<Cpm_Component_Package__c> demoComponentSearch = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c, Installed_Version_Tracking_Method__c, Source_Installed_Commit_Hash__c, Installed__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponentSearch.size() > 0){
            Cpm_Component_Package__c demoComponent = demoComponentSearch[0];
            System.debug('Processing ' + demoComponent.Github_Repository_URL__c);   
            githubCommit = CpmGithubCpmAPIHelper.getGithubCommit(demoComponent.Github_Repository_URL__c, new Map<String,String>());

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

        jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);    

    }catch (Exception e) {
        System.debug(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());   
        jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_FAILED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Failed Notification',
            QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
            QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_ERROR
        });     
    }           
    }

}