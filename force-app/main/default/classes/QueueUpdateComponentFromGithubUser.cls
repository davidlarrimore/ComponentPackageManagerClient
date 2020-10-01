public class QueueUpdateComponentFromGithubUser implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Update Component POC Info', 
        QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => QueueUpdateComponentFromGithubUser.class.getName()
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


    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentFromGithubUser(String parentJobId, Id demoComponentId) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());  
        this.demoComponentId = demoComponentId;
        
    }

    public QueueUpdateComponentFromGithubUser(Id demoComponentId) {
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

        jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);     
    }
}
