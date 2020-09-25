public class QueueGetInstalledPackages implements Queueable, Database.AllowsCallouts {
  /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
  public final String JOBNAME = 'All Demo Components - Package Fetch';
  Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueUpdateComponentFromPackageVersion.class.getName()};

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
  public QueueGetInstalledPackages() {
  }

  public QueueGetInstalledPackages(ID parentJobId) {
    this.jobInfo.put('parentJobId', parentJobId);  
  }

  /*************EXECUTE METHOD*************/   
  public void execute(QueueableContext context) {
    /*************STANDARD JOB ID SETTER*************/
    this.jobInfo.put('jobId', context.getJobId());

    System.debug('Start QueueGetInstalledPackages.execute');
    EventBus.publish(
      new CPM_Async_Event__e(
        ApexClass_Name__c = this.getJobInfo('ApexClassName'),
        AsyncApexJob_Id__c = this.getJobInfo('jobId'),
        AsyncApexJob_Name__c = this.getJobInfo('jobName'),
        AsyncApexJob_Status__c = 'Processing',
        Send_Toast__c = false
      )
    );

    doLater(context.getJobId(), this.JOBNAME);
  }

  @future(callout=true)
  public static void doLater(ID jobId, String jobName) {
    CPM_Async_Event__e asyncApexJobEvent = new CPM_Async_Event__e();

    List<String> recordsToProcess = new List<String>();
    List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = MetadataAPIHelper.getInstalledPackages();
    if (metadataInstalledPackageResponseRecords != null) {
      system.debug(
        'Found ' +
        metadataInstalledPackageResponseRecords.size() +
        ' Installed Packages. Processing...'
      );
      for (MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord : metadataInstalledPackageResponseRecords) {
        recordsToProcess.add(metadataInstalledPackageResponseRecord.subscriberPackageVersion.id);
      }

      QueueUpdateComponentFromPackageVersion updateJob = new QueueUpdateComponentFromPackageVersion(jobId, recordsToProcess,new Map<String, String>{ 'installedFlag' => 'true' });

      ID newJobId = System.enqueueJob(updateJob);

      EventBus.publish(
        new CPM_Async_Event__e(
          ApexClass_Name__c = QueueUpdateComponentFromPackageVersion.class.getName(),
          AsyncApexJob_Parent_Id__c = jobId,
          AsyncApexJob_Id__c = newJobId,
          AsyncApexJob_Name__c = updateJob.getJobName(),
          AsyncApexJob_Status__c = 'Queued',
          Send_Toast__c = false
        )
      );

      EventBus.publish(
        new CPM_Async_Event__e(
          ApexClass_Name__c = QueueGetInstalledPackages.class.getName(),
          AsyncApexJob_Id__c = jobId,
          AsyncApexJob_Name__c = jobName,
          AsyncApexJob_Status__c = 'Completed',
          Send_Toast__c = true,
          Toast_Title__c = 'Job Completion Notification',
          Toast_Message__c = jobId +
            ':QueueGetInstalledPackages Completed Successfully',
          Toast_Variant__c = 'success'
        )
      );
    }
  }
}
