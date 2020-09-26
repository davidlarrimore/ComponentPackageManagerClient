public class QueueUpdateComponentFromGithubUser implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'QueueUpdateComponentFromGithubUser', 
        QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => QueueGetInstalledPackages.class.getName()
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


    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentFromGithubUser(ID parentJobId, Id demoComponentId) {
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        this.demoComponentId = demoComponentId;
    }

    public QueueUpdateComponentFromGithubUser(Id demoComponentId) {
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED);  
        this.demoComponentId = demoComponentId;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, context.getJobId());
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
        
        
        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID) + ' - ' + jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Completed Successfully',
          QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});     
    }
}
