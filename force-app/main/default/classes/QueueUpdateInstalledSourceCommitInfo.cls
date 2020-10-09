public class QueueUpdateInstalledSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'QueueUpdateInstalledSourceCommitInfo', 
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
    public QueueUpdateInstalledSourceCommitInfo(String parentJobId, Id demoComponentId, String commitHash) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId());  
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());        
        this.demoComponentId = demoComponentId;
        this.commitHash = commitHash;  
    }

    public QueueUpdateInstalledSourceCommitInfo(Id demoComponentId, String commitHash) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId());  
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED);   
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());   
        this.demoComponentId = demoComponentId;
        this.commitHash = commitHash;  
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_PROCESSING);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        
        System.debug('Processing QueueUpdateInstalledSourceCommitInfo');   
        doLater(this.jobInfo, this.demoComponentId, this.commitHash);

    }

    @future(callout=true)
    private static void doLater(Map<String, String> jobInfo, Id demoComponentId, String commitHash) {
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        try {
            System.debug('Running updateComponentSourceCommitInfo');  
            List<Demo_Component__c> demoComponentLookup = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c, Install_Date__c, Title__c, Installed_Version_Tracking_Method__c, Source_Installed_Commit_Hash__c, Installed__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
            if(demoComponentLookup.size() > 0){
                Demo_Component__c demoComponent = demoComponentLookup[0];
                System.debug('Processing ' + demoComponent.Github_Repository_URL__c);   
                githubCommit = GithubAPIHelper.getGithubCommit(demoComponent.Github_Repository_URL__c, new Map<String,String>{'commitHash' => commitHash});

                if(githubCommit != null){
                    demoComponent.Source_Installed_Commit_DateTime__c = githubCommit.commitInfo.committer.commitDate;
                    demoComponent.Source_Installed_Commit_Description__c = githubCommit.commitInfo.message;
                    demoComponent.Source_Installed_Commit_Hash__c = githubCommit.sha;
                    demoComponent.Installed__c = true;
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
                QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
                QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
                QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_ERROR
            });     
        }           
    }

}