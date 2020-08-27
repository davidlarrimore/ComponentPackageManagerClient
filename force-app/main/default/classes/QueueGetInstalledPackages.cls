public class QueueGetInstalledPackages implements Queueable, Database.AllowsCallouts {

    public QueueGetInstalledPackages() {
    }

    public void execute(QueueableContext context) {
        System.debug('Start QueueGetInstalledPackages.execute');    
        List<String> recordsToProcess = new List<String>();
        List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = MetadataAPIHelper.getInstalledPackages();
        if(metadataInstalledPackageResponseRecords != null){
            system.debug('Found ' + metadataInstalledPackageResponseRecords.size() + ' Installed Packages. Processing...');
            for(MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord: metadataInstalledPackageResponseRecords){
                recordsToProcess.add(metadataInstalledPackageResponseRecord.subscriberPackageVersion.id);
            }
            QueueUpdateComponentFromPackageVersion updateJob = new QueueUpdateComponentFromPackageVersion(recordsToProcess, new Map<String,String>{'installedFlag' => 'true'}); 
            ID JobId = System.enqueueJob(updateJob);      
        }
    }
}
