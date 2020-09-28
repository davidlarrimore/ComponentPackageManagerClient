public class QueueProcessXTag implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformEventHelper.FIELD_JOB_NAME =>  'QueueProcessXTag', 
        QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => QueueProcessXTag.class.getName()
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
    String xTagJSON;

    /*************CONSTRUCTORS*************/
    public QueueProcessXTag(String parentJobId, String xTagJSON) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

        this.xTagJSON = xTagJSON;
    }

    public QueueProcessXTag(String xTagJSON) {
        this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

        this.xTagJSON = xTagJSON;
    }


    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
        /*************STANDARD EXECUTE STARTER*************/
        this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
        QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

        System.debug('Processing QueueGetInstalledXTags');   
        doLater(this.jobInfo, this.xTagJSON);
    }

    @future(callout=true)
    private static void doLater(Map<String, String> jobInfo, String xTagJSON) {
        try {

            XTagFile xTagFile = (XTagFile)System.JSON.deserialize(xTagJSON, XTagFile.class);

            List<Demo_Component__c> demoComponentSearch = [SELECT Id, Name, Github_Repository_URL__c, Title__c, Install_Date__c, Installed__c, Source_Installed_Commit_Hash__c, Source_Installed_Tag_Hash__c FROM Demo_Component__c WHERE Github_Repository_URL__c = :xTagFile.githubRepositoryUrl LIMIT 1];       
            if(demoComponentSearch.size() > 0){
                Demo_Component__c demoComponent = demoComponentSearch[0];
                xTagFile.demoComponentAlreadyExistsFlag = false;

                System.debug('Existing demo component ' + demoComponent.Title__c + ' Is a match to this XTag File');
                //Component was not installed, and now is....
                if(!demoComponent.Installed__c){
                    System.debug('Marking Demo Component as Installed');
                    demoComponent.Installed__c = true;
                    demoComponent.Install_Date__c = xTagFile.installDateTime;
                    demoComponent.Installation_Type__c = 'Source';
                    demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';  

                    update demoComponent;  

                    QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                        QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                        QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found Newly installed component, updating',
                        QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_INFO});  

                    QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                //Newer version was installed
                }else if (demoComponent.Installed__c && xTagFile.installDateTime > demoComponent.Install_Date__c){
                    System.debug('Component already installed and was probably updated');
                    demoComponent.Install_Date__c = xTagFile.installDateTime;
                    demoComponent.Installation_Type__c = 'Source';
                    demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';   

                    update demoComponent;  

                    QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                }else{
                    System.debug('XTag matches existing info, doing nothing');
                }

            }else{

                System.debug('Repository ' + xTagFile.githubRepositoryUrl + ' Does not match an existing component, creating a new one');

                QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                    QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                    QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found newly installed component!',
                    QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});  


                VersionHelper.AddGithubComponent(xTagFile.githubRepositoryUrl, new map<String,String>{'xTagFile'=>xTagJSON});
            }

            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
            QueuePlatformEventHelper.publishPlatformEvent(jobInfo);    

        }catch (Exception e) {
            System.debug(jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());   

            jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);

            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Failed Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(QueuePlatformEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_ERROR});                
        }  
    }
}
    