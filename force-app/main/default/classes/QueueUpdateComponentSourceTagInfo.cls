public class QueueUpdateComponentSourceTagInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    public final String JOBNAME = 'QueueUpdateComponentSourceTagInfo';
    Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueUpdateComponentSourceTagInfo.class.getName()};

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
    Map<String,String> options = new Map<String,String>();   

    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentSourceTagInfo(ID parentJobId, Id demoComponentId) {
        this.demoComponentId = demoComponentId;
        this.jobInfo.put('parentJobId', parentJobId);
    }

    public QueueUpdateComponentSourceTagInfo(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.jobInfo.put('jobId', context.getJobId());
        QueuePlatformEventHelper.publishAsyncPlatformEvent(this.jobInfo,'Processing');

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
 
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Completed', new Map<String,String>{
            'Toast_Title__c' => 'Job Completion Notification',
            'Toast_Message__c' => jobInfo.get('jobId') + ' - ' + jobInfo.get('jobName') + ' Completed Successfully',
            'Toast_Variant__c' => 'success'}) ;    

    }
    catch (Exception e) {
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Failed', new Map<String,String>{
            'Toast_Title__c' => 'Job Completion Notification',
            'Toast_Message__c' => 'QueueUpdateComponentSourceTagInfo Failed. Error: ' + e.getMessage(),
            'Toast_Variant__c' => 'error'}) ;    
    }  

      }
 




}
