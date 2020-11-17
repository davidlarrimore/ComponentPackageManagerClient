public class QueueGetInstalledPackages implements Queueable, Database.AllowsCallouts {
  /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
  Map<String,String> jobInfo = new Map<String,String>{
    QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Salesforce Packages', 
    QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => QueueGetInstalledPackages.class.getName()
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



  /*************CONSTRUCTORS*************/
  public QueueGetInstalledPackages() {
    this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId()); 
    this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
    QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
    system.debug(this.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  
  }

  public QueueGetInstalledPackages(String parentJobId) {
    this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID, QueuePlatformAsyncEventHelper.generateId()); 
    this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_QUEUED); 
    this.SetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);  
    QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
    system.debug(this.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' has been Queued');  
  }

/*************EXECUTE METHOD*************/   
public void execute(QueueableContext context) {
  /*************STANDARD EXECUTE STARTER*************/
  this.SetJobStage(QueuePlatformAsyncEventHelper.STAGE_PROCESSING);
  QueuePlatformAsyncEventHelper.publishPlatformEvent(this.GetJobInfo());
  system.debug(this.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME)+' is now processing');  

  doLater(this.jobInfo);
}

@future(callout=true)
@TestVisible 
private static void doLater(Map<String, String> jobInfo) {
  System.debug('Running QueueGetInstalledPackages.doLater');
  
  List<String> recordsToProcess = new List<String>();
  List<Cpm_Component_Package__c> demoComponents = new List<Cpm_Component_Package__c>();
  List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = CpmMetadataAPIHelper.getInstalledPackages();
  List<MetadataPackageInstallRequestRecord> metadataPackageInstallRequestRecords = CpmMetadataAPIHelper.getInstallRequests();

  if (metadataInstalledPackageResponseRecords != null && metadataInstalledPackageResponseRecords.size() > 0) {
    system.debug('Found ' + metadataInstalledPackageResponseRecords.size() + ' Installed Packages. Processing...');
    for (MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord : metadataInstalledPackageResponseRecords) {
      if(metadataInstalledPackageResponseRecord.subscriberPackageVersion != null){
        MetadataSubscriberPackageVersion subscriberPackageVersion = metadataInstalledPackageResponseRecord.subscriberPackageVersion;
        MetadataSubscriberPackage subscriberpackage = metadataInstalledPackageResponseRecord.subscriberPackage;
        system.debug('subscriberPackageVersion:' + subscriberPackageVersion);
        system.debug('subscriberpackage:' + subscriberpackage);
        //Getting Pacakge Install Request Records for the Install Date
        if (metadataPackageInstallRequestRecords != null) {
          for (MetadataPackageInstallRequestRecord metadataPackageInstallRequestRecord: metadataPackageInstallRequestRecords){
            //system.debug('Trying to see if Package Version ID: ' + metadataInstalledPackageResponseRecord.subscriberPackageVersion.Id + ' Is the same as the SubscriberPackageVersionKey:' + metadataPackageInstallRequestRecord.SubscriberPackageVersionKey);
            if(metadataInstalledPackageResponseRecord.subscriberPackageVersion.Id.contains(metadataPackageInstallRequestRecord.SubscriberPackageVersionKey)){
              system.debug('Found the Install Request that matches the Demo Package');
              metadataInstalledPackageResponseRecord.packageInstallRequest = metadataPackageInstallRequestRecord;
            }
          }
        }

        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c();
        List<Cpm_Component_Package__c> demoComponentLookup = [SELECT Id, Latest_Subscriber_Package_Version_Id__c, Title__c, Installed__c, Package_Installed_Subscriber_Version_Id__c, Subscriber_Package_Id__c, Package_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Cpm_Component_Package__c WHERE Subscriber_Package_Id__c = :metadataInstalledPackageResponseRecord.subscriberPackage.Id LIMIT 1];

        Boolean existsFlag = false;
        if(demoComponentLookup.size() > 0){
          demoComponent = demoComponentLookup[0];
          System.debug('Found the Cpm_Component_Package__c that matches the MetadataInstalledPackageResponseRecord...Proessing');

          existsFlag = true;
          if(!demoComponent.Installed__c){
            System.debug('Demo Component was not installed previously, marking as installed');
            /*
             * QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
             * QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
             * QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Newly Installed Demo Component Found...',
             * QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS}); 
             */  

            demoComponent.Installed__c = true;
            demoComponent.Package_Installed_Subscriber_Version_Id__c = subscriberPackageVersion.id;
            demoComponent.Package_Installed_Version_Name__c = subscriberPackageVersion.name;
            demoComponent.Package_Installed_Version_Number__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();
            demoComponent.Latest_Package_Version_Deprecated_Flag__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.IsDeprecated;

            demoComponent.Installation_Type__c = 'Package';

            if(null != metadataInstalledPackageResponseRecord.packageInstallRequest){
              demoComponent.Install_date__c =  metadataInstalledPackageResponseRecord.packageInstallRequest.LastModifiedDate;
            }


            if(demoComponent.SFDX_Package_Enabled_Flag__c){
              demoComponent.Installed_Version_Tracking_Method__c = 'SFDX_Project';    
              //TODO:UPDATE SFDX INSTALLED INFO        
            }else{
              demoComponent.Installed_Version_Tracking_Method__c = 'None';                  
            }

            demoComponents.add(demoComponent);

            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Newly Installed Demo Component Found...',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS
            });   

            QueueComponentUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
              QueueComponentUpdateEventHelper.FIELD_UPDATE_FLAG => QueueComponentUpdateEventHelper.FLAG_TRUE,
              QueueComponentUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
            });

            
          }else if(demoComponent.Installed__c && demoComponent.Package_Installed_Subscriber_Version_Id__c != subscriberPackageVersion.id){
            System.debug('Demo Component was previously installed and it appears to be updated....');

            demoComponent.Package_Installed_Subscriber_Version_Id__c = subscriberPackageVersion.id;
            demoComponent.Package_Installed_Version_Name__c = subscriberPackageVersion.name;
            demoComponent.Package_Installed_Version_Number__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();
            demoComponent.Latest_Package_Version_Deprecated_Flag__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.IsDeprecated;
			
            if(null != metadataInstalledPackageResponseRecord.packageInstallRequest){
              demoComponent.Install_date__c =  metadataInstalledPackageResponseRecord.packageInstallRequest.LastModifiedDate;
            }
            
            demoComponents.add(demoComponent);

            jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
            QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component "' + demoComponent.Title__c +'" has been updated.',
              QueuePlatformAsyncEventHelper.FIELD_EVENT_LEVEL => QueuePlatformAsyncEventHelper.EVENT_LEVEL_SUCCESS
            });   


            QueueComponentUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
              QueueComponentUpdateEventHelper.FIELD_UPDATE_FLAG => QueueComponentUpdateEventHelper.FLAG_TRUE,
              QueueComponentUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
            });
          }else{
            System.debug('Everything matches up, we dont need to do anything');   
          }

        }else{

          System.debug('No Demo Component found for ' + subscriberPackage.name + ' installed package, creating a new one...');
          demoComponent.Package_Install_Type_Flag__c = true;
          demoComponent.Title__c = subscriberPackage.name;
          demoComponent.Description__c = subscriberPackage.description;
          demoComponent.Installed__c = true;
          demoComponent.Package_Installed_Subscriber_Version_Id__c = subscriberPackageVersion.id;
          demoComponent.Package_Installed_Version_Name__c = subscriberPackageVersion.name;
          demoComponent.Package_Installed_Version_Number__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();
          demoComponent.Latest_Package_Version_Deprecated_Flag__c = metadataInstalledPackageResponseRecord.subscriberPackageVersion.IsDeprecated;

          demoComponent.Installation_Type__c = 'Package';
          demoComponent.Installed_Version_Tracking_Method__c = 'None';

          demoComponent.Subscriber_Package_Id__c = subscriberPackage.id;
          demoComponent.Package_Name__c = subscriberPackage.name;
          demoComponent.Latest_Subscriber_Package_Version_Id__c = subscriberPackageVersion.id;
          demoComponent.Latest_Package_Version__c = subscriberPackageVersion.getSubscriberPackageVersionNumberText();
          demoComponent.Latest_Package_Version_Name__c = subscriberPackageVersion.name;
          demoComponent.Last_Fetched__c = Datetime.Now();

          demoComponents.add(demoComponent);

    //TODO PLATFORM EVENT FOR MANY COMPONENTS
        }
      }
      if(demoComponents.size() > 100){
        System.debug('Batch Upsert of ' + demoComponents.size() + ' demoComponents');
        upsert demoComponents;
        demoComponents = new List<Cpm_Component_Package__c>();
      }
    }
    System.debug('Final Upserting of ' + demoComponents.size() + ' demoComponents');
    upsert demoComponents;
  }
  jobInfo.put(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, QueuePlatformAsyncEventHelper.STAGE_COMPLETED);
  QueuePlatformAsyncEventHelper.publishPlatformEvent(jobInfo);     
}
}