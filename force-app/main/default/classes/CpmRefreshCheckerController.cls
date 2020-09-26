public with sharing class CpmRefreshCheckerController {

    @AuraEnabled
    public static List<ID> runApex(String demoComponentId){ 
        System.debug('Running CMPRefreshCheckerController.runApex');
        List<ID> jobIds = new List<ID>();
        ID jobId;

        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){

            if(demoComponent[0].SFDX_Package_Enabled_Flag__c){
                QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(demoComponentId, demoComponent[0].Github_Repository_URL__c); 
                List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentFromSFDXJob.getJobInfo('ApexClassName') LIMIT 1];
                if (existingJobs.size() == 0){
                    jobId = System.enqueueJob(queueUpdateComponentFromSFDXJob);
                    jobIds.add(jobId);    
                           
                    EventBus.publish(new CPM_Async_Event__e(
                        ApexClass_Name__c = queueUpdateComponentFromSFDXJob.getJobInfo('ApexClassName'),
                        AsyncApexJob_Id__c = jobId,
                        AsyncApexJob_Name__c = queueUpdateComponentFromSFDXJob.getJobInfo('jobName'),
                        AsyncApexJob_Status__c = 'Queued',
                        Send_Toast__c = false
                    ));  
                }else{
                    jobIds.add(existingJobs[0].Id);

                    EventBus.publish(new CPM_Async_Event__e(
                        ApexClass_Name__c = queueUpdateComponentFromSFDXJob.getJobInfo('ApexClassName'),
                        AsyncApexJob_Id__c = existingJobs[0].Id,
                        AsyncApexJob_Name__c = queueUpdateComponentFromSFDXJob.getJobInfo('jobName'),
                        AsyncApexJob_Status__c = 'Processing',
                        Send_Toast__c = false
                    ));  
                }
            }

            if(demoComponent[0].Source_Install_Type_Flag__c){
                QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(demoComponentId, new Map<String,String>{});   
                List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentSourceCommitInfoJob.getJobInfo('ApexClassName') LIMIT 1];
                if (existingJobs.size() == 0){
                    jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
                    jobIds.add(jobId);    
                    
                    EventBus.publish(new CPM_Async_Event__e(
                        ApexClass_Name__c = queueUpdateComponentSourceCommitInfoJob.getJobInfo('ApexClassName'),
                        AsyncApexJob_Id__c = jobId,
                        AsyncApexJob_Name__c = queueUpdateComponentSourceCommitInfoJob.getJobInfo('jobName'),
                        AsyncApexJob_Status__c = 'Queued',
                        Send_Toast__c = false
                    ));  

                    jobIds.add(jobId); 
                }else{
                    jobIds.add(existingJobs[0].Id);

                    EventBus.publish(new CPM_Async_Event__e(
                        ApexClass_Name__c = queueUpdateComponentSourceCommitInfoJob.getJobInfo('ApexClassName'),
                        AsyncApexJob_Id__c = existingJobs[0].Id,
                        AsyncApexJob_Name__c = queueUpdateComponentSourceCommitInfoJob.getJobInfo('jobName'),
                        AsyncApexJob_Status__c = 'Processing',
                        Send_Toast__c = false
                    ));                      
                }
                
                QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(demoComponentId); 
                existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueUpdateComponentSourceTagInfoJob.getJobInfo('ApexClassName') LIMIT 1];
                if (existingJobs.size() == 0){
                    jobId = System.enqueueJob(queueUpdateComponentSourceTagInfoJob);
                    jobIds.add(jobId);    

                    EventBus.publish(new CPM_Async_Event__e(
                        ApexClass_Name__c = queueUpdateComponentSourceTagInfoJob.getJobInfo('ApexClassName'),
                        AsyncApexJob_Id__c = jobId,
                        AsyncApexJob_Name__c = queueUpdateComponentSourceTagInfoJob.getJobInfo('jobName'),
                        AsyncApexJob_Status__c = 'Queued',
                        Send_Toast__c = false
                    ));  
                }else{
                    jobIds.add(existingJobs[0].Id);

                    EventBus.publish(new CPM_Async_Event__e(
                        ApexClass_Name__c = queueUpdateComponentSourceTagInfoJob.getJobInfo('ApexClassName'),
                        AsyncApexJob_Id__c = existingJobs[0].Id,
                        AsyncApexJob_Name__c = queueUpdateComponentSourceTagInfoJob.getJobInfo('jobName'),
                        AsyncApexJob_Status__c = 'Processing',
                        Send_Toast__c = false
                    ));   
                }
            }
    
        }

        return jobIds;
    }
}
