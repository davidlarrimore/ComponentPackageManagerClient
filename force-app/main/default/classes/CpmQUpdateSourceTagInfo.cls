public class CpmQUpdateSourceTagInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Update Component Source Tag Info', 
        CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmQUpdateSourceTagInfo.class.getName()
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
    public CpmQUpdateSourceTagInfo(String parentJobId, Id demoComponentId) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId());  
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);    
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());       
        this.demoComponentId = demoComponentId;
    }

    public CpmQUpdateSourceTagInfo(Id demoComponentId) {
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

        System.debug('Processing CpmQUpdateSourceCommitInfo');   
        doLater(this.jobInfo, this.demoComponentId);

    }


    @future(callout=true)
    @TestVisible 
    private static void doLater(Map<String, String> jobInfo, Id demoComponentId) {
        Boolean triggerPackageUpdate = false;
        List<GithubRepoTag> githubTags = new List<GithubRepoTag>();

        try {
        System.debug('Running CpmQUpdateSourceTagInfo');  
        List<Cpm_Component_Package__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Installed_Version_Tracking_Method__c, Installed__c, Update_Available__c, Source_Installed_Tag_Hash__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){
            System.debug('Processing ' + demoComponent[0].Github_Repository_URL__c);   
            githubTags = CpmGithubAPIHelper.getGithubTags(demoComponent[0].Github_Repository_URL__c);

            if(githubTags != null && githubTags.size() > 0){
                for(GithubRepoTag thisTag: githubTags){
                    if (thisTag.latestTagFlag != null && thisTag.latestTagFlag){
                        demoComponent[0].Latest_Tag_Commit_DateTime__c = thisTag.tagDate;
                        demoComponent[0].Latest_Tag_Commit_Description__c = thisTag.githubCommit.commitInfo.message;
                        demoComponent[0].Latest_Tag_Commit_Hash__c = thisTag.githubCommit.sha;
                        demoComponent[0].Latest_Tag_Version_Name__c = thisTag.name;

                        if(demoComponent[0].Installed__c){
                            System.debug('Checking to see if update is available');
                            if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Github_Tag' && demoComponent[0].Source_Installed_Tag_Hash__c != thisTag.githubCommit.sha){
                                System.debug('Update Available');
                                demoComponent[0].Update_Available__c = true;
                            }
                        }

                        update demoComponent[0];
                    }
                    
                }
            }else{
                System.debug('No Tags found');  
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