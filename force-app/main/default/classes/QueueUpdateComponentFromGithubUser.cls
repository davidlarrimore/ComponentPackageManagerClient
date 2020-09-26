public class QueueUpdateComponentFromGithubUser implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    public final String JOBNAME = 'QueueUpdateComponentFromGithubUser';
    Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueUpdateComponentFromGithubUser.class.getName()};

    public String getJobName() {
    return this.JOBNAME;
    }

    public String getJobInfo(String key) {
    return this.jobInfo.get(key);
    }

    public Map<String,String> getJobInfo() {
    return this.jobInfo;
    }    

    /*************QUEUEABLE SPECIFIC VARIABLES / FUNCTIONS*************/
    Id demoComponentId = null;


    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentFromGithubUser(ID parentJobId, Id demoComponentId) {
        this.jobInfo.put('parentJobId', parentJobId);  
        this.demoComponentId = demoComponentId;
    }

    public QueueUpdateComponentFromGithubUser(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.jobInfo.put('jobId', context.getJobId());
        QueuePlatformEventHelper.publishPlatformEvent(this.jobInfo,'Processing');
        
        QueuePlatformEventHelper.publishPlatformEvent(this.jobInfo,'Completed', new Map<String,String>{
            'Toast_Title__c' => 'Job Completion Notification',
            'Toast_Message__c' => this.getJobInfo('jobId') + ' - ' + this.getJobInfo('jobName') + ' Completed Successfully',
            'Toast_Variant__c' => 'success'}) ;    
    }
}
