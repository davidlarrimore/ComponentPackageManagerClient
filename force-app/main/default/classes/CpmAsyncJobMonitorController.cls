public with sharing class CpmAsyncJobMonitorController {

    @AuraEnabled
    public static AsyncApexJob getJobById(String recordId){
        return [SELECT Id, ApexClass.Name, Status, ApexClassId, MethodName, ExtendedStatus, JobType, NumberOfErrors FROM AsyncApexJob WHERE Id =: recordId LIMIT 1];
    }

    @AuraEnabled
    public static list<AsyncApexJob> getJobs(List<String> recordIds){
        System.debug('Running CpmAsyncJobMonitorController.getJobs, with RecordIds: ' + recordIds);
        return [SELECT Id, ApexClass.Name, Status, ApexClassId, MethodName, ExtendedStatus, JobType, NumberOfErrors FROM AsyncApexJob WHERE Id in :recordIds];
    }


    @AuraEnabled
    public static list<AsyncApexJob> getAllJobs(List<String> recordIds){
        System.debug('Running CpmAsyncJobMonitorController.getAllJobs, with RecordIds: ' + recordIds + ' with size ' +  + recordIds.size());
        return [SELECT Id, ApexClass.Name, Status, ApexClassId, MethodName, ExtendedStatus, JobType, NumberOfErrors FROM AsyncApexJob WHERE Id in :recordIds OR Status IN ('Holding','Queued','Preparing','Processing')];
    }

}
    