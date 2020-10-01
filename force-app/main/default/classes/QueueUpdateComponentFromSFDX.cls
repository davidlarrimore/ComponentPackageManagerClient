public class QueueUpdateComponentFromSFDX implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Update Component SFDX Info', 
        QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => QueueUpdateComponentFromSFDX.class.getName()
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

    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentFromSFDX(String parentJobId, Id demoComponentId) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId());   
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());       
        this.demoComponentId = demoComponentId;     
    }

    public QueueUpdateComponentFromSFDX(Id demoComponentId) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId());   
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
        this.demoComponentId = demoComponentId;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

        doLater(this.jobInfo, this.demoComponentId);

    }

    @future(callout=true)
    private static void doLater(Map<String, String> jobInfo, Id demoComponentId) {
        String newJobId;
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        List<Demo_Component__c> demoComponentSearch = [SELECT Id, Github_Repository_URL__c, Installed__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponentSearch.size() > 0){
            Demo_Component__c demoComponent = demoComponentSearch[0];
            try {
                githubSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(demoComponent.Github_Repository_URL__c);

                if(githubSFDXProjectDotJSON != null){
                    if(githubSFDXProjectDotJSON.packageDirectories != null && githubSFDXProjectDotJSON.packageDirectories.size() > 0){
                        for(GithubPackageDirectory thisPackageDirectory: (List<GithubPackageDirectory>) githubSFDXProjectDotJSON.packageDirectories){
                            if(thisPackageDirectory.defaultDirectory == true && thisPackageDirectory.packageName != null){
                                System.debug('Found the default package directory, this is an SFDX Enabled Project!, Named: ' + thisPackageDirectory.packageName);

                                demoComponent.Package_Install_Type_Flag__c = true;
                                demoComponent.SFDX_Package_Enabled_Flag__c = true;
                                demoComponent.Title__c = thisPackageDirectory.packageName;
                                demoComponent.SFDX_Package_Name__c = thisPackageDirectory.packageName;
                                demoComponent.Latest_SFDX_Package_Version_Name__c = thisPackageDirectory.versionName;
                                demoComponent.Latest_SFDX_Package_Version_Description__c = thisPackageDirectory.versionDescription;

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
                        
                        if(demoComponent.SFDX_Package_Enabled_Flag__c && demoComponent.Latest_Subscriber_Package_Version_Id__c != githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()){
                            System.debug('Package Versions are different, QueueUpdateComponentFromPackageVersion');
                            demoComponent.Latest_SFDX_Package_Alias__c = githubSFDXProjectDotJSON.getLatestVersionAlias();
                            demoComponent.Latest_Subscriber_Package_Version_Id__c = githubSFDXProjectDotJSON.getLatestVersionPackageVersionId();
                            triggerPackageUpdate = true;

                            if(demoComponent.Installed__c){
                                System.debug('Checking to see if update is available');
                                if(demoComponent.Installed_Version_Tracking_Method__c == 'SFDX Project' ){
                                    System.debug('Update Available');
                                    demoComponent.Update_Available__c = true;
                                }
                            }

                        }
                    }

                    update demoComponent;

                    jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
                    QueuePlatformEventHelper.publishPlatformEvent(jobInfo);                  

                    if(triggerPackageUpdate){
                        QueueUpdateComponentFromPackageVersion queueUpdateComponentFromPackageVersionJob = new QueueUpdateComponentFromPackageVersion(demoComponent.Id, githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()); 
                        System.enqueueJob(queueUpdateComponentFromPackageVersionJob);            
                        
                    }

                }else{
                    System.debug('sfdx-project.json not found');
                    demoComponent.SFDX_Package_Enabled_Flag__c = false;  
                    update demoComponent;
                }
    
        
            }catch (Exception e) {
                jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
                QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Fail Notification',
                QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
                QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});     
            }   
        }
        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    
    }

}    
