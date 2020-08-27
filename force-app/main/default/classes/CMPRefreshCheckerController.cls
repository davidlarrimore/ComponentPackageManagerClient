public with sharing class CMPRefreshCheckerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static List<ID> runApex(String searchKey){ 
        System.debug('Running CMPRefreshCheckerController.runApex');
        List<ID> JobIDs = new List<ID>();
        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :searchKey LIMIT 1];
        if(demoComponent.size() > 0){
            if(demoComponent[0].SFDX_Package_Enabled_Flag__c){
                QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(searchKey); 
                JobIDs.add(System.enqueueJob(queueUpdateComponentFromSFDXJob));  
            }

            if(demoComponent[0].Source_Install_Type_Flag__c){
                QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(searchKey); 
                JobIDs.add(System.enqueueJob(queueUpdateComponentSourceCommitInfoJob));    
        
                QueueUpdateComponentSourceTagInfo queueUpdateComponentSourceTagInfoJob = new QueueUpdateComponentSourceTagInfo(searchKey); 
                JobIDs.add(System.enqueueJob(queueUpdateComponentSourceTagInfoJob));    
            }

            QueueComponentUpdateCheck queueComponentUpdateCheckJob = new QueueComponentUpdateCheck(searchKey); 
            JobIDs.add(System.enqueueJob(queueComponentUpdateCheckJob));  
                        
        }

        return JobIDs;
    }
}
