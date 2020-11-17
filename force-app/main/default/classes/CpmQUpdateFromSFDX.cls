public class CpmQUpdateFromSFDX implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Update Component SFDX Info', 
        CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmQUpdateFromSFDX.class.getName()
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
    public CpmQUpdateFromSFDX(String parentJobId, Id demoComponentId) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId());   
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());       
        this.demoComponentId = demoComponentId;     
    }

    public CpmQUpdateFromSFDX(Id demoComponentId) {
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

        doLater(this.jobInfo, this.demoComponentId);

    }

    @future(callout=true)
    @TestVisible 
    private static void doLater(Map<String, String> jobInfo, Id demoComponentId) {
        String newJobId;
        Boolean triggerPackageUpdate = false;
        List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        List<Cpm_Component_Package__c> demoComponentSearch = [SELECT Id, Github_Repository_URL__c, Installed__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponentSearch.size() > 0){
            Cpm_Component_Package__c demoComponent = demoComponentSearch[0];
            if(String.isNotEmpty(demoComponent.Github_Repository_URL__c)){
                try {
                    githubSFDXProjectDotJSON = CpmGithubAPIHelper.getGithubSFDXProjectDotJSON(demoComponent.Github_Repository_URL__c);

                    if(null != githubSFDXProjectDotJSON){
                        if(githubSFDXProjectDotJSON.packageDirectories != null && githubSFDXProjectDotJSON.packageDirectories.size() > 0){
                            for(GithubPackageDirectory thisPackageDirectory: (List<GithubPackageDirectory>) githubSFDXProjectDotJSON.packageDirectories){
                                if(thisPackageDirectory.defaultDirectory == true && thisPackageDirectory.packageName != null){
                                    System.debug('Found the default package directory, this is an SFDX Enabled Project!, Named: ' + thisPackageDirectory.packageName);

                                    demoComponent.Package_Install_Type_Flag__c = true;
                                    demoComponent.SFDX_Package_Enabled_Flag__c = true;
                                    demoComponent.Title__c = thisPackageDirectory.packageName;
                                    //TODO: ENABLE MERGING WHEN A COMPONENT DOESN'T HAVE A GITHUB PROJECT, BUT YOU ADD IT
                                    demoComponent.SFDX_Package_Name__c = thisPackageDirectory.packageName;
                                    demoComponent.Latest_SFDX_Package_Version_Name__c = thisPackageDirectory.versionName;
                                    demoComponent.Latest_SFDX_Package_Version_Description__c = thisPackageDirectory.versionDescription;

                                    //Processing Dependencies
                                    if(thisPackageDirectory.dependencies != null && thisPackageDirectory.dependencies.size() > 0){
                                        for(Map<String,String> thisDependency: (List<map<string,string>>) thisPackageDirectory.dependencies){
                                            if(thisDependency.containsKey('packageName')){
                                                dependentPackageSubscriberPackageVersionIds.add((String)thisDependency.get('packageName'));
                                            }
                                        }
                                        //TODO: NEED TO FIGURE OUT HOW TO ADD DEPENDENCIES THAT ARE SFDX DEPENDENCIES, vs Package...
                                        System.debug('Found some dependent Packages in SFDX-Project.json, will address later: ' + dependentPackageSubscriberPackageVersionIds);
                                    }
                                }else{
                                    System.debug('This is not the default package directory, skipping');
                                }
                            }
                            
                            if(demoComponent.SFDX_Package_Enabled_Flag__c && demoComponent.Latest_Subscriber_Package_Version_Id__c != githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()){
                                System.debug('Package Versions are different, CpmQUpdateFromPackageVersion');
                                demoComponent.Latest_SFDX_Package_Alias__c = githubSFDXProjectDotJSON.getLatestVersionAlias();
                                demoComponent.Latest_Subscriber_Package_Version_Id__c = githubSFDXProjectDotJSON.getLatestVersionPackageVersionId();
                                triggerPackageUpdate = true;
                                if(demoComponent.Installed__c){
                                    System.debug('Checking to see if update is available');
                                    if(demoComponent.Installed_Version_Tracking_Method__c == 'SFDX_Project'){
                                        System.debug('Update Available');
                                        demoComponent.Update_Available__c = true;
                                    }
                                }

                            }
                        }

                        jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
                        CpmAsyncEventHelper.publishPlatformEvent(jobInfo);                  

                        update demoComponent;

                        if(triggerPackageUpdate){
                
                            CpmQUpdateFromPackageVersion CpmQUpdateFromPackageVersionJob = new CpmQUpdateFromPackageVersion(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id, githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()); 
                            System.enqueueJob(CpmQUpdateFromPackageVersionJob);
                        }

                    }else{
                        System.debug('sfdx-project.json not found');
                        demoComponent.SFDX_Package_Enabled_Flag__c = false;  
                        update demoComponent;
                    }
        
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
            }else{
                jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
                CpmAsyncEventHelper.publishPlatformEvent(jobInfo);   
            }
        }else{
            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_FAILED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo);   
        }
    }

}