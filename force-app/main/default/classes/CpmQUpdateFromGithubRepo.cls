public class CpmQUpdateFromGithubRepo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Update Component Info from Github Repo', 
        CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmQUpdateFromGithubRepo.class.getName()
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


    /*************CONSTRUCTORS*************/    
    public CpmQUpdateFromGithubRepo(String parentJobId, Id demoComponentId) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId()); 
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());  
        this.demoComponentId = demoComponentId;
        
    }

    public CpmQUpdateFromGithubRepo(Id demoComponentId) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId()); 
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED);  
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        this.demoComponentId = demoComponentId;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(CpmAsyncEventHelper.STAGE_PROCESSING);
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());

        doLater(this.jobInfo, demoComponentId);
    }
  
    @future(callout=true)
    @TestVisible 
    private static void doLater(Map<String, String> jobInfo, String demoComponentId) {
      System.debug('Running CpmQUpdateFromGithubRepo.execute');
      GithubRepository githubRepository = new GithubRepository();
      GithubUser githubUser = new GithubUser();

      List<Cpm_Component_Package__c> demoComponentLookup = [SELECT Id, Github_Repository_URL__c, Title__c, POC_Name__c, POC_Email__c, Description__c, Installed__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];
      if(demoComponentLookup.size() > 0){
        Cpm_Component_Package__c demoComponent = demoComponentLookup[0];
        try {
            githubRepository = CpmGithubAPIHelper.getGithubRepo(demoComponent.Github_Repository_URL__c);
            
            if(githubRepository != null){
                if(String.isBlank(demoComponent.Description__c)){
                    demoComponent.Description__c = githubRepository.description;  
                }

                githubUser = CpmGithubAPIHelper.getGithubUser(githubRepository.githubRepoOwner.url);
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
            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo);     
            }catch (Exception e) {
                System.debug(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());
                jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_FAILED);
                CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Fail Notification',
                CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
                CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_ERROR});     
            }   
      }
    }
}