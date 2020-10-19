public class QueueUpdateComponentFromGithubRepo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Update Component Info from Github Repo', 
        QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => QueueUpdateComponentFromGithubRepo.class.getName()
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
    public QueueUpdateComponentFromGithubRepo(String parentJobId, Id demoComponentId) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());  
        this.demoComponentId = demoComponentId;
        
    }

    public QueueUpdateComponentFromGithubRepo(Id demoComponentId) {
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

        doLater(this.jobInfo, demoComponentId);
    }
  
    @future(callout=true)
    @TestVisible 
    private static void doLater(Map<String, String> jobInfo, String demoComponentId) {
      System.debug('Running QueueUpdateComponentFromGithubRepo.execute');
      GithubRepository githubRepository = new GithubRepository();
      GithubUser githubUser = new GithubUser();

      List<Demo_Component__c> demoComponentLookup = [SELECT Id, Github_Repository_URL__c, Title__c, POC_Name__c, POC_Email__c, Description__c, Installed__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
      if(demoComponentLookup.size() > 0){
        Demo_Component__c demoComponent = demoComponentLookup[0];
        try {
            githubRepository = GithubAPIHelper.getGithubRepo(demoComponent.Github_Repository_URL__c);
            
            if(githubRepository != null){
                if(String.isBlank(demoComponent.Description__c)){
                    demoComponent.Description__c = githubRepository.description;  
                }

                githubUser = GithubAPIHelper.getGithubUser(githubRepository.githubRepoOwner.url);
                if(githubUser != null){
                    if(String.isBlank(demoComponent.POC_Name__c)){
                        demoComponent.POC_Name__c = githubUser.name;  
                    }
                    if(String.isBlank(demoComponent.POC_Email__c)){
                        demoComponent.POC_Email__c = githubUser.email;
                    }
                }

            }

            update demoComponent;
            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);     
            }catch (Exception e) {
                System.debug(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());
                jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_FAILED);
                QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Fail Notification',
                QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
                QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_ERROR});     
            }   
      }
    }
}