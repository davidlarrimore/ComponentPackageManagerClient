public class QueueUpdateComponentFromPackageVersion implements Queueable, Database.AllowsCallouts {
    List<String> subscriberPackageVersionIds = new List<String>();
    Map<String,String> options = new Map<String,String>();


    public QueueUpdateComponentFromPackageVersion(List<String> subscriberPackageVersionIds, Map<String,String> options) {
        this.subscriberPackageVersionIds = subscriberPackageVersionIds;
        this.options = options;
    }

    public void execute(QueueableContext context) {
       
        List<MetadataInstalledPackageResponseRecord> recordsToProcess = new List<MetadataInstalledPackageResponseRecord>();
        System.debug('Start QueueUpdateComponentFromPackageVersion.execute');
        for(String subscriberPackageVersionId: subscriberPackageVersionIds){
            MetadataSubscriberPackageVersion subscriberPackageVersion = MetadataAPIHelper.getSubscriberPackageVersion(subscriberPackageVersionId);
            if(subscriberPackageVersion != null){
                System.debug('Successfully found Subscriber Package Version Info from Tooling API');
                MetadataSubscriberPackage subscriberPackage = MetadataAPIHelper.getSubscriberPackage(subscriberPackageVersion.subscriberPackageId);
                if(subscriberPackage != null){
                    MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = new MetadataInstalledPackageResponseRecord();
                    metadataInstalledPackageResponseRecord.subscriberpackage = subscriberPackage;
                    metadataInstalledPackageResponseRecord.subscriberPackageVersion = subscriberPackageVersion;
                    recordsToProcess.add(metadataInstalledPackageResponseRecord);
                    System.debug('Successfully found Subscriber Package Info from Tooling API');
                } else{
                    System.debug('ERROR: Could not find Subscriber Package Version Info from Tooling API');
                }
            }
        }

        for(MetadataInstalledPackageResponseRecord record: recordsToProcess){
            VersionHelper.updateComponentFromPackageVersion(record.subscriberPackage, record.subscriberPackageVersion, options);
        }
    }
}

