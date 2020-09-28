public class QueueGetInstalledXTags implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'QueueGetInstalledXTags', 
        QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => QueueGetInstalledXTags.class.getName()
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



    /*************CONSTRUCTORS*************/
    public QueueGetInstalledXTags(ID parentJobId) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
    }

    public QueueGetInstalledXTags() {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

        System.debug('Processing QueueGetInstalledXTags');   
        doLater(this.jobInfo);
    }

    @future(callout=true)
    private static void doLater(Map<String, String> jobInfo) {
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
                    System.debug('Found ' + demoComponents.size() + ' Demo Components');
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
                update demoComponents;

                for(XTagFile xTagFile: xTagFiles){
                    if(!xTagFile.demoComponentAlreadyExistsFlag){
                        System.debug('Repository ' + xTagFile.githubRepositoryUrl + ' Does not match an existing component, creating a new one');
                        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);

                        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                          QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                          QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found newly installed component!',
                          QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_INFO});  

                        VersionHelper.AddGithubComponent(xTagFile.githubRepositoryUrl, new map<String,String>{'installDate'=>string.valueOfGmt(xTagFile.installDateTime), 'installedFlag'=>'true', 'installType' => xTagFile.installType, 'commitHash' => xTagFile.commitHash});
                    }
                }
            }


            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    

        }catch (Exception e) {
            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});                
        }  
    }
}
    