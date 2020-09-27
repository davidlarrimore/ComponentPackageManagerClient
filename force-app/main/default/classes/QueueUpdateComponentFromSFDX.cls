public class QueueUpdateComponentFromSFDX implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'QueueUpdateComponentFromSFDX', 
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
    String githubUrl = null;

    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentFromSFDX(ID parentJobId, Id demoComponentId, String githubUrl) {
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);         
        this.demoComponentId = demoComponentId;
        this.githubUrl = githubUrl;       
    }

    public QueueUpdateComponentFromSFDX(Id demoComponentId, String githubUrl) {
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 

        this.demoComponentId = demoComponentId;
        this.githubUrl = githubUrl;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, context.getJobId());
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

        System.debug('Processing ' + this.githubUrl);   
        doLater(this.jobInfo, this.demoComponentId, this.githubUrl);

    }

    @future(callout=true)
    private static void doLater(Map<String, String> jobInfo, Id demoComponentId, String githubUrl) {
        ID newJobId;
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
            
        try {
            githubSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(githubUrl);

            if(githubSFDXProjectDotJSON != null){
                if(githubSFDXProjectDotJSON.packageDirectories != null && githubSFDXProjectDotJSON.packageDirectories.size() > 0){
                    for(GithubPackageDirectory thisPackageDirectory: (List<GithubPackageDirectory>) githubSFDXProjectDotJSON.packageDirectories){
                        if(thisPackageDirectory.defaultDirectory == true){
                            System.debug('Found the default package directory, this is an SFDX Enabled Project!');

                            demoComponent[0].Package_Install_Type_Flag__c = true;
                            demoComponent[0].SFDX_Package_Enabled_Flag__c = true;
                            demoComponent[0].SFDX_Package_Name__c = thisPackageDirectory.packageName;
                            demoComponent[0].Latest_SFDX_Package_Version_Name__c = thisPackageDirectory.versionName;
                            demoComponent[0].Latest_SFDX_Package_Version_Description__c = thisPackageDirectory.versionDescription;

                            //Processing Dependencies
                            if(thisPackageDirectory.dependencies != null && thisPackageDirectory.dependencies.size() > 0){
                                List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();
                                for(Map<String,String> thisDependency: (List<map<string,string>>) thisPackageDirectory.dependencies){
                                    if(thisDependency.containsKey('packageName')){
                                        dependentPackageSubscriberPackageVersionIds.add((String)thisDependency.get('packageName'));
                                    }
                                }
                                System.debug('Found some dependent Packages in SFDX-Project.json, will address later: ' + dependentPackageSubscriberPackageVersionIds);
                            }
                        }else{
                            System.debug('This is not the default package directory, skipping');
                        }
                    }

                    if(demoComponent[0].Latest_Subscriber_Package_Version_Id__c != githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()){
                        System.debug('Package Versions are different, QueueUpdateComponentFromPackageVersion');
                        demoComponent[0].Latest_SFDX_Package_Alias__c = githubSFDXProjectDotJSON.getLatestVersionAlias();
                        demoComponent[0].Latest_Subscriber_Package_Version_Id__c = githubSFDXProjectDotJSON.getLatestVersionPackageVersionId();
                        triggerPackageUpdate = true;

                        if(demoComponent[0].Installed__c){
                            System.debug('Checking to see if update is available');
                            if(demoComponent[0].Installed_Version_Tracking_Method__c == 'SFDX Project' ){
                                System.debug('Update Available');
                                demoComponent[0].Update_Available__c = true;
                            }
                        }

                    }
                }

                update demoComponent;

                jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
                QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                  QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
                  QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID) + ' - ' + jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Completed Successfully',
                  QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});                  

                if(triggerPackageUpdate){
                    QueueUpdateComponentFromPackageVersion queueUpdateComponentFromPackageVersionJob = new QueueUpdateComponentFromPackageVersion(new List<String>{githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()}, new Map<String,String>()); 
                    newJobId = System.enqueueJob(queueUpdateComponentFromPackageVersionJob);
                    queueUpdateComponentFromPackageVersionJob.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, newJobId);  
                    QueuePlatformEventHelper.publishPlatformEvent(queueUpdateComponentFromPackageVersionJob.GetJobInfo());                     
                    
                }

            }else{
                System.debug('sfdx-project.json not found');  
            }
 
    
        }catch (Exception e) {
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});     
        }   

    
    }

}    
