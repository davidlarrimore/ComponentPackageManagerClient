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
    public static list<AsyncApexJob> getJobsByDate(Datetime inDate, List<String> recordIds){
        System.debug('Running CpmAsyncJobMonitorController.getJobsByDate, with inDate: ' + inDate);
        Datetime expirationDate = Datetime.valueOf(inDate);
        expirationDate.addSeconds(-30);
        return [SELECT Id, ApexClass.Name, Status, ApexClassId, MethodName, ExtendedStatus, JobType, NumberOfErrors FROM AsyncApexJob WHERE CompletedDate > :expirationDate OR Id in :recordIds OR Status IN ('Holding','Queued','Preparing','Processing')];
    }

}
    