public with sharing class CpmAsyncJobMonitorController {

    @AuraEnabled
    public static AsyncApexJob getJobById(String recordId){
        return [SELECT Id, Status, ApexClassId, MethodName, ExtendedStatus, JobType, NumberOfErrors FROM AsyncApexJob WHERE Id =: recordId LIMIT 1];
    }

    @AuraEnabled
    public static list<AsyncApexJob> getJobs(List<String> recordIds){
        System.debug('Running CpmAsyncJobMonitorController' + recordIds);
        System.debug('Received the following RecordIds' + recordIds);
        return [SELECT Id, Status, ApexClassId, MethodName, ExtendedStatus, JobType, NumberOfErrors FROM AsyncApexJob WHERE Id in :recordIds];
    }

}
    