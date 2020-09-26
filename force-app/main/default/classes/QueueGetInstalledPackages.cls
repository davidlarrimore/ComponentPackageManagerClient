  public class QueueGetInstalledPackages implements Queueable, Database.AllowsCallouts {
    /*************STANDARD HELPER VARIABLES / FUNCTIONS*************/
    public final String JOBNAME = 'QueueGetInstalledPackages';
    Map<String,String> jobInfo = new Map<String,String>{'jobName' => JOBNAME, 'ApexClassName' => QueueGetInstalledPackages.class.getName()};

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
    /*************STANDARD EXECUTE STARTER*************/
    this.jobInfo.put('jobId', context.getJobId());
    QueuePlatformEventHelper.publishAsyncPlatformEvent(this.jobInfo,'Processing');

    doLater(this.jobInfo);
  }

  @future(callout=true)
  public static void doLater(Map<String, String> jobInfo) {
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

      QueueUpdateComponentFromPackageVersion updateJob = new QueueUpdateComponentFromPackageVersion(jobInfo.get('jobId'), recordsToProcess, new Map<String, String>{ 'installedFlag' => 'true' });
      ID newJobId = System.enqueueJob(updateJob);


      EventBus.publish(
        new CPM_Async_Event__e(
            ApexClass_Name__c = updateJob.getJobInfo('ApexClassName'),
            AsyncApexJob_Id__c = newJobId,
            AsyncApexJob_Parent_Id__c = updateJob.getJobInfo('jobId'),
            AsyncApexJob_Name__c = updateJob.getJobInfo('jobName'),
            AsyncApexJob_Status__c = 'Queued',
            Send_Toast__c = false
        )
        );     
      
        QueuePlatformEventHelper.publishPlatformEvent(jobInfo,'Completed', new Map<String,String>{
        'Toast_Title__c' => 'Job Completion Notification',
        'Toast_Message__c' => jobInfo.get('jobId') + ' - ' + jobInfo.get('jobName') + ' Completed Successfully',
        'Toast_Variant__c' => 'success'});     
    }
  }
}
