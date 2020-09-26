public class QueueUpdateComponentSourceTagInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'QueueUpdateComponentSourceTagInfo', 
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
    Map<String,String> options = new Map<String,String>();   

    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentSourceTagInfo(ID parentJobId, Id demoComponentId) {
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);           
        this.demoComponentId = demoComponentId;
    }

    public QueueUpdateComponentSourceTagInfo(Id demoComponentId) {
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED);          
        this.demoComponentId = demoComponentId;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, context.getJobId());
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

        System.debug('Processing QueueUpdateComponentSourceCommitInfo');   
        doLater(this.jobInfo, this.demoComponentId, this.options);

    }


    @future(callout=true)
    public static void doLater(Map<String, String> jobInfo, Id demoComponentId, Map<String,String> options) {
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();

        try {
        System.debug('Running QueueUpdateComponentSourceTagInfo');  
        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Installed_Version_Tracking_Method__c, Installed__c, Update_Available__c, Source_Installed_Tag_Hash__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){
            System.debug('Processing ' + demoComponent[0].Github_Repository_URL__c);   
            List<GithubRepoTag> githubTags = GithubAPIHelper.getGithubTags(demoComponent[0].Github_Repository_URL__c);

            if(githubTags.size() > 0 && githubTags != null){
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
 
        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID) + ' - ' + jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Completed Successfully',
          QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});    

    }catch (Exception e) {
        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
          QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
          QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});    
    }  

      }
 




}
