public with sharing class CpmJobStatusController {

    @AuraEnabled
    public static list<AsyncApexJob> getJobInfo(String recordId){
        return [SELECT Id, Status, ApexClassId, MethodName, ExtendedStatus, JobType, NumberOfErrors FROM AsyncApexJob WHERE Id =: recordId LIMIT 1];
    }
}
