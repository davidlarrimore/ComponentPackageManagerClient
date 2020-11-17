public class CpmQProcessDependentPackages implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
        CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Processing Dependent Salesforce Packages', 
        CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmQProcessDependentPackages.class.getName()
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
    String parentDemoComponentId;
    List<String> dependentPackageVersionIds = new List<String>();


    /*************CONSTRUCTORS*************/
    public CpmQProcessDependentPackages(String parentDemoComponentId, List<String> dependentPackageVersionIds) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId()); 
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        system.debug(this.GetJobInfo(CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  
    }

    public CpmQProcessDependentPackages(String parentJobId, String parentDemoComponentId, List<String> dependentPackageVersionIds) {
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId()); 
        this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
        this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
        CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
        system.debug(this.GetJobInfo(CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  

        this.parentDemoComponentId = parentDemoComponentId;
        this.dependentPackageVersionIds = dependentPackageVersionIds;
    }

    /*************EXECUTE METHOD*************/   
    public void execute(QueueableContext context) {
    /*************STANDARD EXECUTE STARTER*************/
    this.SetJobStage(CpmAsyncEventHelper.STAGE_PROCESSING);
    CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
    system.debug(this.GetJobInfo(CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' is now processing');  

    doLater(this.jobInfo, this.parentDemoComponentId, this.dependentPackageVersionIds);
    }

    @future(callout=true)
    @TestVisible 
    private static void doLater(Map<String, String> jobInfo, String parentDemoComponentId, List<String> dependentPackageVersionIds) {
        system.debug(jobInfo.get(CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' is now processing doLater');  

        List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = new List<MetadataInstalledPackageResponseRecord>();
        List<Cpm_Component_Package__c> parentDemoComponentLookup = [SELECT Id from Cpm_Component_Package__c WHERE Id = :parentDemoComponentId];
        //TODO: Add Logic to check to see if Parent Demo Component Exists....
        if(parentDemoComponentLookup.size() > 0){

            Cpm_Component_Package__c parentDemoComponent = parentDemoComponentLookup[0];

            for(String dependentPackageVersionId: dependentPackageVersionIds){
                MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = new MetadataInstalledPackageResponseRecord();
                MetadataSubscriberPackageVersion metadataSubscriberPackageVersion = new MetadataSubscriberPackageVersion();
                MetadataSubscriberPackage metadataSubscriberPackage = new MetadataSubscriberPackage();

                metadataSubscriberPackageVersion = CpmMetadataAPIHelper.getSubscriberPackageVersion(dependentPackageVersionId);
                if (metadataSubscriberPackageVersion != null) {
                    System.debug('Successfully found Subscriber Package Version Info from Tooling API');
                    metadataSubscriberPackage = CpmMetadataAPIHelper.getSubscriberPackage(metadataSubscriberPackageVersion.subscriberPackageId);
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
                Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c();
                List<Cpm_Component_Package__c> demoComponentLookup = [
                    SELECT
                    Id,
                    Latest_Subscriber_Package_Version_Id__c,
                    Title__c,
                    Installed__c,
                    Package_Installed_Subscriber_Version_Id__c,
                    Subscriber_Package_Id__c,
                    Package_Install_Type_Flag__c,
                    SFDX_Package_Enabled_Flag__c
                    FROM Cpm_Component_Package__c
                    WHERE
                    Subscriber_Package_Id__c = :metadataInstalledPackageResponseRecord.subscriberPackage.Id
                    LIMIT 1
                ];
                
                MetadataSubscriberPackageVersion subscriberPackageVersion = metadataInstalledPackageResponseRecord.subscriberPackageVersion;
                MetadataSubscriberPackage subscriberpackage = metadataInstalledPackageResponseRecord.subscriberpackage;

                //TODO:GET INSTALL DATE FROM METADATA API.....

                if(demoComponentLookup.size() == 0){
                    System.debug('Cpm_Component_Package__c Did not previously exist, updating');

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

                    jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
                    CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                        CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                        CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Created new Demo Component named , "' + demoComponent.Title__c +'" That is a dependency of another package',
                        CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_SUCCESS
                    });  

                    CpmComponentPackageUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
                        CpmComponentPackageUpdateEventHelper.FIELD_UPDATE_FLAG => CpmComponentPackageUpdateEventHelper.FLAG_TRUE,
                        CpmComponentPackageUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
                    });
                }else{
                    demoComponent = demoComponentLookup[0];
                }

                    //Look for existing demo component dependency...
                List<Cpm_Component_Package_Dependency__c> dependentComponentLookup = [SELECT Id FROM Cpm_Component_Package_Dependency__c WHERE Cpm_Component_Package__c =:parentDemoComponent.Id AND Dependent_Component_Package__c =:demoComponent.Id];
                if(dependentComponentLookup.size() == 0){
                    System.debug('Component Dependency Not found, Creating New record');
                    insert new Cpm_Component_Package_Dependency__c(
                        Dependent_Component_Package__c = demoComponent.Id,
                        Cpm_Component_Package__c = parentDemoComponent.Id
                    );
                    parentDemoComponent.Dependencies_Met__c = false;
                    update parentDemoComponent;
                }else{
                    System.debug('Existing Component Dependency ' + dependentComponentLookup[0].Id + ' Found');
                    if(!dependentComponentLookup[0].Installed__c){
                        System.debug('Demo Component is not installed, thereforce depedendencies on parent dependent is not met');
                        parentDemoComponent.Dependencies_Met__c = false;
                        update parentDemoComponent;
                    }
                }
            }

            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo);   
        }else{
            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_FAILED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo);               
        }
    }
}