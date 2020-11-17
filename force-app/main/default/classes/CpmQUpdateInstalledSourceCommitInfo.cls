public class CpmQUpdateInstalledSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        CpmAsyncEventHelper.FIELD_JOB_NAME =>  'CpmQUpdateInstalledSourceCommitInfo', 
        CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmQUpdateSourceCommitInfo.class.getName()
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
        this.jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, value);  
    }   

    /*************QUEUEABLE SPECIFIC VARIABLES / FUNCTIONS*************/
    Id demoComponentId = null;
    String commitHash;   

    /*************CONSTRUCTORS*************/    
    public CpmQUpdateInstalledSourceCommitInfo(String parentJobId, Id demoComponentId, String commitHash) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId());  
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());        
        this.demoComponentId = demoComponentId;
        this.commitHash = commitHash;  
    }

    public CpmQUpdateInstalledSourceCommitInfo(Id demoComponentId, String commitHash) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId());  
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED);   
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());   
        this.demoComponentId = demoComponentId;
        this.commitHash = commitHash;  
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(CpmAsyncEventHelper.STAGE_PROCESSING);
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        
        System.debug('Processing CpmQUpdateInstalledSourceCommitInfo');   
        doLater(this.jobInfo, this.demoComponentId, this.commitHash);

    }

    @future(callout=true)
    @TestVisible 
    private static void doLater(Map<String, String> jobInfo, String demoComponentId, String commitHash) {
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        try {
            System.debug('Running updateComponentSourceCommitInfo');  
            List<Cpm_Component_Package__c> demoComponentLookup = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c, Install_Date__c, Title__c, Installed_Version_Tracking_Method__c, Source_Installed_Commit_Hash__c, Installed__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];
            if(demoComponentLookup.size() > 0){
                Cpm_Component_Package__c demoComponent = demoComponentLookup[0];
                System.debug('Processing ' + demoComponent.Github_Repository_URL__c);   
                githubCommit = CpmGithubAPIHelper.getGithubCommit(demoComponent.Github_Repository_URL__c, new Map<String,String>{'commitHash' => commitHash});

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

            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo);    

        }catch (Exception e) {
            System.debug(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());
            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_FAILED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
                CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
                CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_ERROR
            });     
        }           
    }

}