public class QueueUpdateComponentFromPackageVersion implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
      QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Update Component Package Info', 
      QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => QueueUpdateComponentFromPackageVersion.class.getName()
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
  String subscriberPackageVersionId;

  /*************CONSTRUCTORS*************/      
  public QueueUpdateComponentFromPackageVersion(String parentJobId, Id demoComponentId, String subscriberPackageVersionId) {
    this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
    this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
    this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);    
    QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
    this.demoComponentId = demoComponentId;
    this.subscriberPackageVersionId = subscriberPackageVersionId;
  }

  public QueueUpdateComponentFromPackageVersion(Id demoComponentId, String subscriberPackageVersionId) {
    this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
    this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
    QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
    this.demoComponentId = demoComponentId;
    this.subscriberPackageVersionId = subscriberPackageVersionId;
  }

  /*************EXECUTE METHOD*************/   
  public void execute(QueueableContext context) {
      /*************STANDARD EXECUTE STARTER*************/
      System.debug('Running ' + QueueUpdateComponentFromPackageVersion.class.getName() );
      this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
      QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());

    doLater(this.jobInfo, this.demoComponentId, subscriberPackageVersionId);
  }

  @future(callout=true)
  private static void doLater(Map<String, String> jobInfo,Id demoComponentId,String subscriberPackageVersionId) {
    List<Demo_Component__c> demoComponentLookup = [SELECT Id, Github_Repository_URL__c, Installed__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];  
    if (demoComponentLookup.size() > 0) {
      System.debug('Successfully found Demo Component');
      Boolean toolingAPISuccessFlag = false;

      MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = new MetadataInstalledPackageResponseRecord();
      MetadataSubscriberPackageVersion metadataSubscriberPackageVersion = new MetadataSubscriberPackageVersion();
      MetadataSubscriberPackage metadataSubscriberPackage = new MetadataSubscriberPackage();


      metadataSubscriberPackageVersion = MetadataAPIHelper.getSubscriberPackageVersion(subscriberPackageVersionId);
      if (metadataSubscriberPackageVersion != null) {
        System.debug('Successfully found Subscriber Package Version Info from Tooling API');
        metadataSubscriberPackage = MetadataAPIHelper.getSubscriberPackage(metadataSubscriberPackageVersion.subscriberPackageId);
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
        Demo_Component__c demoComponent = demoComponentLookup[0];
        demoComponent.Subscriber_Package_Id__c = metadataInstalledPackageResponseRecord.subscriberPackage.id;
        demoComponent.Package_Name__c = metadataInstalledPackageResponseRecord.subscriberPackage.name;
        demoComponent.Latest_Subscriber_Package_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
        demoComponent.Latest_Package_Version__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
        demoComponent.Latest_Package_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
        update demoComponent;

        //TODO:FIX DEPENDENCIES

      }
    }

        jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo);   
  }
}
