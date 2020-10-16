public class QueueProcessDependentPackages implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Salesforce Packages', 
        QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => QueueProcessDependentPackages.class.getName()
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
        this.jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, value);  
    }   

    /*************QUEUEABLE SPECIFIC VARIABLES / FUNCTIONS*************/
    String parentDemoComponentId;
    List<String> dependentPackageVersionIds = new List<String>();


    /*************CONSTRUCTORS*************/
    public QueueProcessDependentPackages(String parentDemoComponentId, List<String> dependentPackageVersionIds) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        system.debug(this.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  
    }

    public QueueProcessDependentPackages(String parentJobId, String parentDemoComponentId, List<String> dependentPackageVersionIds) {
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId()); 
        this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        system.debug(this.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  

        this.parentDemoComponentId = parentDemoComponentId;
        this.dependentPackageVersionIds = dependentPackageVersionIds;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
    /*************STANDARD EXECUTE STARTER*************/
    this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_PROCESSING);
    QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
    system.debug(this.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' has been is now processing');  

    doLater(this.jobInfo, this.parentDemoComponentId, this.dependentPackageVersionIds);
    }

    @future(callout=true)
    private static void doLater(Map<String, String> jobInfo, String parentDemoComponentId, List<String> dependentPackageVersionIds) {
        system.debug(jobInfo.get(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' is now processing doLater');  

        List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = new List<MetadataInstalledPackageResponseRecord>();
        List<Demo_Component__c> parentDemoComponentLookup = [SELECT Id from Demo_Component__c WHERE Id = :parentDemoComponentId];
        //TODO: Add Logic to check to see if Parent Demo Component Exists....
        Demo_Component__c parentDemoComponent = parentDemoComponentLookup[0];

        for(String dependentPackageVersionId: dependentPackageVersionIds){
            MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = new MetadataInstalledPackageResponseRecord();
            MetadataSubscriberPackageVersion metadataSubscriberPackageVersion = new MetadataSubscriberPackageVersion();
            MetadataSubscriberPackage metadataSubscriberPackage = new MetadataSubscriberPackage();

            metadataSubscriberPackageVersion = MetadataAPIHelper.getSubscriberPackageVersion(dependentPackageVersionId);
            if (metadataSubscriberPackageVersion != null) {
                System.debug('Successfully found Subscriber Package Version Info from Tooling API');
                metadataSubscriberPackage = MetadataAPIHelper.getSubscriberPackage(metadataSubscriberPackageVersion.subscriberPackageId);
                if (metadataSubscriberPackage != null) {
                    System.debug('Successfully found Subscriber Package Info from Tooling API');
                    metadataInstalledPackageResponseRecord.subscriberPackageId = dependentPackageVersionId;
                    metadataInstalledPackageResponseRecord.subscriberpackage = metadataSubscriberPackage;
                    metadataInstalledPackageResponseRecord.subscriberPackageVersion = metadataSubscriberPackageVersion;
                    metadataInstalledPackageResponseRecords.add(metadataInstalledPackageResponseRecord);
                }else{
                    System.debug('Could not find Subscriber Package Version Info from Tooling API');
                }
            }else{
                System.debug('Could not find Subscriber Package Version Info from Tooling API');
            }
        }


        for(MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord: metadataInstalledPackageResponseRecords){
            Demo_Component__c demoComponent = new Demo_Component__c();
            List<Demo_Component__c> demoComponentLookup = [
                SELECT
                Id,
                Latest_Subscriber_Package_Version_Id__c,
                Title__c,
                Installed__c,
                Package_Installed_Subscriber_Version_Id__c,
                Subscriber_Package_Id__c,
                Package_Install_Type_Flag__c,
                SFDX_Package_Enabled_Flag__c
                FROM Demo_Component__c
                WHERE
                Subscriber_Package_Id__c = :metadataInstalledPackageResponseRecord.subscriberPackage.Id
                LIMIT 1
            ];
            
            MetadataSubscriberPackageVersion subscriberPackageVersion = metadataInstalledPackageResponseRecord.subscriberPackageVersion;
            MetadataSubscriberPackage subscriberpackage = metadataInstalledPackageResponseRecord.subscriberpackage;

            //TODO:GET INSTALL DATE FROM METADATA API.....

            if(demoComponentLookup.size() == 0){
                System.debug('Demo_Component__c Did not previously exist, updating');

                System.debug('No Demo Component found for ' + metadataInstalledPackageResponseRecord.subscriberPackage.name + ' installed package, creating a new one...');
                demoComponent.Package_Install_Type_Flag__c = true;
                demoComponent.Title__c = subscriberPackage.name;
                demoComponent.Description__c = subscriberPackage.description;
                demoComponent.Package_Installed_Subscriber_Version_Id__c = subscriberPackageVersion.id;
                demoComponent.Package_Installed_Version_Name__c = subscriberPackageVersion.name;
                demoComponent.Package_Installed_Version_Number__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();
                demoComponent.Installation_Type__c = 'Package';
                demoComponent.Installed_Version_Tracking_Method__c = 'None';

                demoComponent.Subscriber_Package_Id__c = subscriberPackage.id;
                demoComponent.Package_Name__c = subscriberPackage.name;
                demoComponent.Latest_Subscriber_Package_Version_Id__c = subscriberPackageVersion.id;
                demoComponent.Latest_Package_Version__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();
                demoComponent.Latest_Package_Version_Name__c = subscriberPackageVersion.name;
                demoComponent.Last_Fetched__c = Datetime.Now();

                insert demoComponent;

                jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
                QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                    QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                    QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Created new Demo Component named , "' + demoComponent.Title__c +'" That is a dependency of another package',
                    QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS
                });  

                QueueComponentUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
                    QueueComponentUpdateEventHelper.FIELD_UPDATE_FLAG => QueueComponentUpdateEventHelper.FLAG_TRUE,
                    QueueComponentUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
                });
            }else{
                demoComponent = demoComponentLookup[0];
            }

                //Look for existing demo component dependency...
            List<Component_Dependency__c> dependentComponentLookup = [SELECT Id FROM Component_Dependency__c WHERE Demo_Component__c =:parentDemoComponent.Id AND Dependent_Component__c =:demoComponent.Id];
            if(dependentComponentLookup.size() == 0){
                System.debug('Component Dependency Not found, Creating New record');
                insert new Component_Dependency__c(
                    Dependent_Component__c = demoComponent.Id,
                    Demo_Component__c = parentDemoComponent.Id
                );
            }else{
                System.debug('Existing Component Dependency ' + dependentComponentLookup[0].Id + ' Found, Ignoring.');
            }
        }

        jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
        QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);   
    }
}