public class QueueUpdateComponentFromSFDX implements Queueable, Database.AllowsCallouts  {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    public final String JOBNAME = 'QueueUpdateComponentFromSFDX';
    Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueUpdateComponentFromSFDX.class.getName()};

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
    String githubUrl = null;

    /*************CONSTRUCTORS*************/    
    public QueueUpdateComponentFromSFDX(ID parentJobId, Id demoComponentId, String githubUrl) {
        this.demoComponentId = demoComponentId;
        this.githubUrl = githubUrl;       
        this.jobInfo.put('parentJobId', parentJobId);
    }

    public QueueUpdateComponentFromSFDX(Id demoComponentId, String githubUrl) {
        this.demoComponentId = demoComponentId;
        this.githubUrl = githubUrl;
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.jobInfo.put('jobId', context.getJobId());
        QueuePlatformEventHelper.publishAsyncPlatformEvent(this.jobInfo,'Processing');

        System.debug('Processing ' + this.githubUrl);   
        doLater(this.jobInfo, this.demoComponentId, this.githubUrl);

    }

    @future(callout=true)
    public static void doLater(Map<String, String> jobInfo, Id demoComponentId, String githubUrl) {
        Boolean triggerPackageUpdate = false;
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();

        try {
            githubSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(githubUrl);

            List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
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

                QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Completed', new Map<String,String>{
                    'Toast_Title__c' => 'Job Completion Notification',
                    'Toast_Message__c' => jobInfo.get('jobId') + ' - ' + jobInfo.get('jobName') + ' Completed Successfully',
                    'Toast_Variant__c' => 'success'}) ;                  

                if(triggerPackageUpdate){
                    QueueUpdateComponentFromPackageVersion queueUpdateComponentFromPackageVersionJob = new QueueUpdateComponentFromPackageVersion(new List<String>{githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()}, new Map<String,String>()); 
                    ID JobID = System.enqueueJob(queueUpdateComponentFromPackageVersionJob);    
                }

            }else{
                System.debug('sfdx-project.json not found');  
            }
        }catch (Exception e) {
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Failed', new Map<String,String>{
                'Toast_Title__c' => 'Job Completion Notification',
                'Toast_Message__c' => 'QueueUpdateComponentFromSFDX Failed. Error: ' + e.getMessage(),
                'Toast_Variant__c' => 'error'}) ;    
        }  

    
    }

}    
