public class QueueUpdateComponentFromGithubUser implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    public final String JOBNAME = 'Update Component from GithubUser';
    Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueUpdateComponentFromPackageVersion.class.getName()};

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
        /*************STANDARD JOB ID SETTER*************/
        this.jobInfo.put('jobId', context.getJobId());        
    }
}
