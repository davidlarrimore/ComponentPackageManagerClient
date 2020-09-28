
public class QueueUpdateInstalledSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'QueueUpdateInstalledSourceCommitInfo', 
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
    String commitHash;   

    /*************CONSTRUCTORS*************/    
    public QueueUpdateInstalledSourceCommitInfo(String parentJobId, Id demoComponentId, String commitHash) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId());  
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());        
        this.demoComponentId = demoComponentId;
        this.commitHash = commitHash;  
    }

    public QueueUpdateInstalledSourceCommitInfo(Id demoComponentId, String commitHash) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId());  
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED);   
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());   
        this.demoComponentId = demoComponentId;
        this.commitHash = commitHash;  
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
        
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
            List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c, Install_Date__c, Title__c, Installed_Version_Tracking_Method__c, Source_Installed_Commit_Hash__c, Installed__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
            if(demoComponent.size() > 0){
                System.debug('Processing ' + demoComponent[0].Github_Repository_URL__c);   
                githubCommit = GithubAPIHelper.getGithubCommit(demoComponent[0].Github_Repository_URL__c, new Map<String,String>{'commitHash' => commitHash});

                if(githubCommit != null){
                    demoComponent[0].Latest_Commit_DateTime__c = githubCommit.commitInfo.committer.commitDate;
                    demoComponent[0].Latest_Commit_Description__c = githubCommit.commitInfo.message;
                    demoComponent[0].Latest_Commit_Hash__c = githubCommit.sha;

                    if(demoComponent[0].Installed__c){
                        System.debug('Checking to see if update is available');
                        if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Github_Commit' && demoComponent[0].Source_Installed_Commit_Hash__c != githubCommit.sha){
                            System.debug('Update Available');
                            demoComponent[0].Update_Available__c = true;
                        }else{
                            demoComponent[0].Update_Available__c = false;
                        }
                    }

                    update demoComponent[0];  
                }else{
                    System.debug('No Commits found');  
                }
            }else{
                System.debug('Could not find Component ' + demoComponentId);   
            }

            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    

        }catch (Exception e) {
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
                QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
                QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});     
        }           
    }

}
