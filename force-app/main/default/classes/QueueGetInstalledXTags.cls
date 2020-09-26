public class QueueGetInstalledXTags implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    public final String JOBNAME = 'QueueGetInstalledXTags';
    Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueGetInstalledXTags.class.getName()};

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



    /*************CONSTRUCTORS*************/
    public QueueGetInstalledXTags(ID parentJobId) {
        this.jobInfo.put('parentJobId', parentJobId);  
    }

    public QueueGetInstalledXTags() {
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.jobInfo.put('jobId', context.getJobId());
        QueuePlatformEventHelper.publishPlatformEvent(this.jobInfo,'Processing');

        System.debug('Processing QueueGetInstalledXTags');   
        doLater(this.jobInfo);

    }

    @future(callout=true)
    public static void doLater(Map<String, String> jobInfo) {
        try {
            List<StaticResource> staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'XTAG%'];
            List<String> githubRepositoryUrls = new List<String>();
            List<XTagFile> xTagFiles = new List<XTagFile>();

            if(staticResources.size() > 0){
                System.debug('Found' + staticResources.size() + ' static_resources');
                for (StaticResource staticResource: staticResources){
                    XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResource.Body.toString(), XTagFile.class);

                    System.debug('Found Static Resource ID: ' + staticResource.Id + ', with name: '+ xTagFile.name); 
                    githubRepositoryUrls.add(xTagFile.githubRepositoryUrl);
                    xTagFiles.add(xTagFile);
                }

                List<Demo_Component__c> demoComponents = [SELECT Id, Name, Github_Repository_URL__c, Installed__c, Source_Installed_Commit_Hash__c, Source_Installed_Tag_Hash__c FROM Demo_Component__c WHERE Github_Repository_URL__c IN: githubRepositoryUrls];       
                
                if(demoComponents.size() > 0){
                    System.debug('Found' + demoComponents.size() + ' Demo Components');
                    for (XTagFile xTagFile: xTagFiles){
                        xTagFile.demoComponentAlreadyExistsFlag = false;
                        xTagFile.demoComponentAlreadyInstalledFlag = false;
                        for (Demo_Component__c demoComponent: demoComponents){
                            if (xTagFile.githubRepositoryUrl == demoComponent.Github_Repository_URL__c){
                                System.debug('Existing demo component ' + demoComponent.Name + ' Is a match to this XTag File');
                                xTagFile.demoComponentId = demoComponent.Id;
                                xTagFile.demoComponentAlreadyExistsFlag = true;
                                if (demoComponent.Installed__c){
                                    System.debug('Component is already marked as installed');
                                    xTagFile.demoComponentAlreadyInstalledFlag = true;
                                }
                            }
                        }
                    }
                }

                for(XTagFile xTagFile: xTagFiles){
                    if(!xTagFile.demoComponentAlreadyExistsFlag){
                        System.debug('Repository ' + xTagFile.githubRepositoryUrl + ' Does not match an existing component, creating a new one');
                        VersionHelper.getComponentFromGithubURL(xTagFile.githubRepositoryUrl, new map<String,String>{'installDate'=>string.valueOfGmt(xTagFile.installDateTime), 'installedFlag'=>'true', 'installType' => xTagFile.installType, 'commitHash' => xTagFile.commitHash});
                    }
                }
            }


            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Completed', new Map<String,String>{
                'Toast_Title__c' => 'Job Completion Notification',
                'Toast_Message__c' => jobInfo.get('jobId') + ' - ' + jobInfo.get('jobName') + ' Completed Successfully',
                'Toast_Variant__c' => 'success'}) ;    

        }catch (Exception e) {
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Failed', new Map<String,String>{
                'Toast_Title__c' => 'Job Completion Notification',
                'Toast_Message__c' => 'QueueGetInstalledXTags Failed. Error: ' + e.getMessage(),
                'Toast_Variant__c' => 'error'}) ;    
        }  
            
    }
}
    