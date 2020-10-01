  public class QueueGetInstalledPackages implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    Map<String,String> jobInfo = new Map<String,String>{
      QueuePlatformEventHelper.FIELD_JOB_NAME =>  'Checking for installed Salesforce Packages', 
      QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME => QueueGetInstalledPackages.class.getName()
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
    public QueueGetInstalledPackages() {
      this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
      this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
      QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
      system.debug(this.GetJobInfo(QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  
    }

    public QueueGetInstalledPackages(ID parentJobId) {
      this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_ID, QueuePlatformEventHelper.generateId()); 
      this.SetJobStage(QueuePlatformEventHelper.STAGE_QUEUED); 
      this.SetJobInfo(QueuePlatformEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
      QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
      system.debug(this.GetJobInfo(QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  
    }

  /*************EXECUTE METHOD*************/   
  public void execute(QueueableContext context) {
    /*************STANDARD EXECUTE STARTER*************/
    this.SetJobStage(QueuePlatformEventHelper.STAGE_PROCESSING);
    QueuePlatformEventHelper.publishPlatformEvent(this.GetJobInfo());
    system.debug(this.GetJobInfo(QueuePlatformEventHelper.FIELD_APEX_CLASS_NAME)+' has been is now processing');  

    doLater(this.jobInfo);
  }

  @future(callout=true)
  private static void doLater(Map<String, String> jobInfo) {
    System.debug('Running VersionHelper.getInstalledSalesforcePackages');
    
    List<String> recordsToProcess = new List<String>();
    List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = MetadataAPIHelper.getInstalledPackages();
    if (metadataInstalledPackageResponseRecords != null) {
      system.debug('Found ' + metadataInstalledPackageResponseRecords.size() + ' Installed Packages. Processing...');
      for (MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord : metadataInstalledPackageResponseRecords) {
        Demo_Component__c demoComponent = new Demo_Component__c();
        List<Demo_Component__c> demoComponentLookup = [
          SELECT
            Id,
            Latest_Subscriber_Package_Version_Id__c,
            Title__c,
            Installed__c,
            Package_Installed_Subscriber_Version_Id__c,
            Subscriber_Package_Id__c,
            Package_Install_Type_Flag__c
          FROM Demo_Component__c
          WHERE
            Subscriber_Package_Id__c = :metadataInstalledPackageResponseRecord.subscriberPackage.Id
          LIMIT 1
        ];
    
          //TODO:GET INSTALL DATE FROM METADATA API.....

          Boolean existsFlag = false;
          if(demoComponentLookup.size() > 0){
            demoComponent = demoComponentLookup[0];
            System.debug('Found the Demo_Component__c that matches the MetadataInstalledPackageResponseRecord...Proessing');

            System.debug('Found the Demo_Component__c that matches the MetadataInstalledPackageResponseRecord...Proessing');
            existsFlag = true;
            if(!demoComponent.Installed__c){
              System.debug('Demo Component was not installed previously, marking as installed');
              jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_FAILED);
              QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Newly Installed Demo Component Found...',
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});   


              demoComponent.Installed__c = true;
              demoComponent.Package_Installed_Subscriber_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
              demoComponent.Package_Installed_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
              demoComponent.Package_Installed_Version_Number__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
              demoComponent.Installation_Type__c = 'Package';
              demoComponent.Installed_Version_Tracking_Method__c = 'None';
              update demoComponent;
              
            }else if(demoComponent.Installed__c && demoComponent.Package_Installed_Subscriber_Version_Id__c != metadataInstalledPackageResponseRecord.subscriberPackageVersion.id){
              System.debug('Demo Component was previously installed and it appears to be updated....');

              QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
              QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found Updated Demo Component.',
              QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});   

              demoComponent.Package_Installed_Subscriber_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
              demoComponent.Package_Installed_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
              demoComponent.Package_Installed_Version_Number__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
              update demoComponent;
            }else{
              System.debug('Everything matches up, we dont need to do anything');
            }

          }else{

            System.debug('No Demo Component found for ' + metadataInstalledPackageResponseRecord.subscriberPackage.name + ' installed package, creating a new one...');
            demoComponent.Package_Install_Type_Flag__c = true;
            demoComponent.Title__c = metadataInstalledPackageResponseRecord.subscriberPackage.name;
            demoComponent.Description__c = metadataInstalledPackageResponseRecord.subscriberPackage.description;
            demoComponent.Installed__c = true;
            demoComponent.Package_Installed_Subscriber_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
            demoComponent.Package_Installed_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
            demoComponent.Package_Installed_Version_Number__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
            demoComponent.Installation_Type__c = 'Package';
            demoComponent.Installed_Version_Tracking_Method__c = 'None';

            demoComponent.Subscriber_Package_Id__c = metadataInstalledPackageResponseRecord.subscriberPackage.id;
            demoComponent.Package_Name__c = metadataInstalledPackageResponseRecord.subscriberPackage.name;
            demoComponent.Latest_Subscriber_Package_Version_Id__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.id;
            demoComponent.Latest_Package_Version__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.getSubscriberPackageVersionNumberText();
            demoComponent.Latest_Package_Version_Name__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.name;
            demoComponent.Last_Fetched__c = Datetime.Now();

            insert demoComponent;


            QueuePlatformEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
            QueuePlatformEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found New Demo Component Installed.',
            QueuePlatformEventHelper.FIELD_EVENT_LEVEL => QueuePlatformEventHelper.EVENT_LEVEL_SUCCESS});       
          }
        }
      }

      jobInfo.put(QueuePlatformEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformEventHelper.STAGE_COMPLETED);
      QueuePlatformEventHelper.publishPlatformEvent(jobInfo);     
  }
}
