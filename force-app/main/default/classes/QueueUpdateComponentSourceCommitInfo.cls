public class QueueUpdateComponentSourceCommitInfo implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    public final String JOBNAME = 'QueueUpdateComponentSourceCommitInfo';
    Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueUpdateComponentSourceCommitInfo.class.getName()};

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
    public QueueUpdateComponentSourceCommitInfo(ID parentJobId, Id demoComponentId, Map<String,String> options) {
        this.demoComponentId = demoComponentId;
        this.options = options;  
        this.jobInfo.put('parentJobId', parentJobId);
    }

    public QueueUpdateComponentSourceCommitInfo(Id demoComponentId, Map<String,String> options) {
        this.demoComponentId = demoComponentId;
        this.options = options;  
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
        System.debug('Running updateComponentSourceCommitInfo');  
        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c, Installed_Version_Tracking_Method__c, Source_Installed_Commit_Hash__c, Installed__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){
            System.debug('Processing ' + demoComponent[0].Github_Repository_URL__c);   
            GithubRepoCommit githubCommit = GithubAPIHelper.getGithubCommit(demoComponent[0].Github_Repository_URL__c, new Map<String,String>());

            if(githubCommit != null){
                demoComponent[0].Latest_Commit_DateTime__c = githubCommit.commitInfo.committer.commitDate;
                demoComponent[0].Latest_Commit_Description__c = githubCommit.commitInfo.message;
                demoComponent[0].Latest_Commit_Hash__c = githubCommit.sha;

                //If not an SFDX Based project, we assume POC information is not there, grabbing commit author info;
                if (!demoComponent[0].SFDX_Package_Enabled_Flag__c){
                    System.debug('This project is not SFDX Package Enabled, grabbing github info');  
                    GithubUser githubUser = GithubAPIHelper.getGithubUser(githubCommit.author.url);
                    demoComponent[0].POC_Name__c = githubUser.name;
                    demoComponent[0].POC_Email__c = githubUser.email;
                }

                if(options.get('installedFlag') != null && options.get('commitHash') != null && options.get('installType') != null && options.get('installDate') != null){
                    if(options.get('installedFlag') == 'true' && options.get('installType') == 'Github Commit'){
                        System.debug('This was an install request, updating appropriatley');
                        demoComponent[0].Installed__c = true;
                        demoComponent[0].Installation_Type__c = 'Source';
                        demoComponent[0].Install_Date__c = DateTime.valueOf(options.get('installDate'));
                        demoComponent[0].Installed_Version_Tracking_Method__c = 'Github_Commit'; //Using API Name!

                        System.debug('This was marked as installed, updating');
                        if(githubCommit.sha.equals(options.get('commitHash'))){
                            System.debug('The same hash was installed, Leveraging it');
                            demoComponent[0].Source_Installed_Commit_Hash__c = githubCommit.sha;
                            demoComponent[0].Source_Installed_Commit_Description__c = githubCommit.commitInfo.message;
                            demoComponent[0].Source_Installed_Commit_DateTime__c = githubCommit.commitInfo.committer.commitDate;
                                                                
                        }else{
                            System.debug('Installed hash ('+options.get('commitHash')+') does not match latest hash ('+githubCommit.sha+'), We assume Prior version was installed, grabbing that hash info');
                            GithubRepoCommit installedGithubCommit = GithubAPIHelper.getGithubCommit(demoComponent[0].Github_Repository_URL__c, options);
                            demoComponent[0].Source_Installed_Commit_Hash__c = installedGithubCommit.sha;
                            demoComponent[0].Source_Installed_Commit_Description__c = installedGithubCommit.commitInfo.message;
                            demoComponent[0].Source_Installed_Commit_DateTime__c = installedGithubCommit.commitInfo.committer.commitDate;
                        }
                        
                    }
                    
                }

                if(demoComponent[0].Installed__c){
                    System.debug('Checking to see if update is available');
                    if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Github Commit' && demoComponent[0].Source_Installed_Commit_Hash__c != githubCommit.sha){
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


        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Completed', new Map<String,String>{
            'Toast_Title__c' => 'Job Completion Notification',
            'Toast_Message__c' => jobInfo.get('jobId') + ' - ' + jobInfo.get('jobName') + ' Completed Successfully',
            'Toast_Variant__c' => 'success'}) ;    

    }
    catch (Exception e) {
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Failed', new Map<String,String>{
            'Toast_Title__c' => 'Job Completion Notification',
            'Toast_Message__c' => 'QueueUpdateComponentSourceCommitInfo Failed. Error: ' + e.getMessage(),
            'Toast_Variant__c' => 'error'}) ;    
    }           
    }

}
