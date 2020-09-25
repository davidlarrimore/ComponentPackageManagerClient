public with sharing class CpmComponentInstallCheckerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CPMInstallCheckerController.runApex');
        List<ID> JobIDs = new List<ID>();

        List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = 'QueueGetInstalledPackages' LIMIT 1];
        if (existingJobs.size() == 0){
            QueueGetInstalledPackages updateJob = new QueueGetInstalledPackages();
            JobIDs.add(System.enqueueJob(updateJob));

            EventBus.publish(new CPM_Async_Event__e(
                ApexClass_Name__c = QueueGetInstalledPackages.class.getName(),
                AsyncApexJob_Id__c = JobIDs[0],
                AsyncApexJob_Name__c = updateJob.getJobName(),
                AsyncApexJob_Status__c = 'Queued',
                Send_Toast__c = false
            ));  
        }else{
            JobIDs.add(existingJobs[0].Id);
        }
    
        doLater();

        return JobIDs;
    }

    @future(callout=true)
    public static void doLater(){
        VersionHelper.updateComponentFromXTag();
    }
}
