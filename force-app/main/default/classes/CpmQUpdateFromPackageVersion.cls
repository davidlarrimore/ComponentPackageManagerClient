public class CpmQUpdateFromPackageVersion implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
      CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Update Component Package Info', 
      CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmQUpdateFromPackageVersion.class.getName()
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
  String subscriberPackageVersionId;

  /*************CONSTRUCTORS*************/      
  public CpmQUpdateFromPackageVersion(String parentJobId, Id demoComponentId, String subscriberPackageVersionId) {
    this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId()); 
    this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
    this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);    
    CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
    this.demoComponentId = demoComponentId;
    this.subscriberPackageVersionId = subscriberPackageVersionId;
  }

  public CpmQUpdateFromPackageVersion(Id demoComponentId, String subscriberPackageVersionId) {
    this.SetJobInfo(CpmAsyncEventHelper.FIELD_JOB_ID, CpmAsyncEventHelper.generateId()); 
    this.SetJobStage(CpmAsyncEventHelper.STAGE_QUEUED); 
    CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
    this.demoComponentId = demoComponentId;
    this.subscriberPackageVersionId = subscriberPackageVersionId;
  }

  /*************EXECUTE METHOD*************/   
  public void execute(QueueableContext context) {
      /*************STANDARD EXECUTE STARTER*************/
      System.debug('Running ' + CpmQUpdateFromPackageVersion.class.getName() );
      this.SetJobStage(CpmAsyncEventHelper.STAGE_PROCESSING);
      CpmAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());

    doLater(this.jobInfo, this.demoComponentId, subscriberPackageVersionId);
  }

  @future(callout=true)
  @TestVisible 
  private static void doLater(Map<String, String> jobInfo,Id demoComponentId, String subscriberPackageVersionId) {
    List<Cpm_Component_Package__c> demoComponentLookup = [SELECT Id, Github_Repository_URL__c, Installed__c, Latest_Package_Version__c, Package_Installed_Version_Number__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];  
    if (demoComponentLookup.size() > 0) {
      System.debug('Successfully found Demo Component');
      Boolean toolingAPISuccessFlag = false;

      MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = new MetadataInstalledPackageResponseRecord();
      MetadataSubscriberPackageVersion metadataSubscriberPackageVersion = new MetadataSubscriberPackageVersion();
      MetadataSubscriberPackage metadataSubscriberPackage = new MetadataSubscriberPackage();


      metadataSubscriberPackageVersion = CpmMetadataAPIHelper.getSubscriberPackageVersion(subscriberPackageVersionId);
      if (metadataSubscriberPackageVersion != null) {
        System.debug('Successfully found Subscriber Package Version Info from Tooling API');
        metadataSubscriberPackage = CpmMetadataAPIHelper.getSubscriberPackage(metadataSubscriberPackageVersion.subscriberPackageId);
        if (metadataSubscriberPackage != null) {
          System.debug('Successfully found Subscriber Package Info from Tooling API');
          metadataInstalledPackageResponseRecord.subscriberPackageId = subscriberPackageVersionId;
          metadataInstalledPackageResponseRecord.subscriberpackage = metadataSubscriberPackage;
          metadataInstalledPackageResponseRecord.subscriberPackageVersion = metadataSubscriberPackageVersion;
          toolingAPISuccessFlag = true;
        }else{
          System.debug('Could not find Subscriber Package Version Info from Tooling API');
        }
      }else{
        System.debug('Could not find Subscriber Package Version Info from Tooling API');
      }

      if(toolingAPISuccessFlag){
        System.debug('Tooling API was a success, Updating Component');
        Cpm_Component_Package__c demoComponent = demoComponentLookup[0];
        demoComponent.Subscriber_Package_Id__c = metadataInstalledPackageResponseRecord.subscriberPackage.id;
        demoComponent.Package_Name__c = metadataInstalledPackageResponseRecord.subscriberPackage.name;
        demoComponent.Latest_Subscriber_Package_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
        demoComponent.Latest_Package_Version__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
        demoComponent.Latest_Package_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
        demoComponent.Latest_Package_Version_Deprecated_Flag__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.IsDeprecated;

        if(demoComponent.Installed__c ){
          if(metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumber() > CpmVersionHelper.getVersionNumberFromText(demoComponent.Package_Installed_Version_Number__c)){
            System.debug('Package Can be Updated from version ' + demoComponent.Package_Installed_Version_Number__c + ' to version ' + metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText() + '.....Setting Flag');
            demoComponent.Update_Available__c = true;
          }
        }

        update demoComponent;


        if(null != metadataInstalledPackageResponseRecord.subscriberPackageVersion.dependencies){
          if(metadataInstalledPackageResponseRecord.subscriberPackageVersion.dependencies.ids.size() > 0){
            List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();
            for(Map<String,String> dependency: metadataInstalledPackageResponseRecord.subscriberPackageVersion.dependencies.ids){
              dependentPackageSubscriberPackageVersionIds.add(dependency.get('subscriberPackageVersionId'));
            }
            CpmQProcessDependentPackages queueProcessDependentPackagesJob = new CpmQProcessDependentPackages(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id, dependentPackageSubscriberPackageVersionIds); 
            System.enqueueJob(queueProcessDependentPackagesJob);
          }
        }

      }
    }

    jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
    CpmAsyncEventHelper.publishPlatformEvent(jobInfo);   
  }
}