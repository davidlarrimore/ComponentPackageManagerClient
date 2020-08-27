public with sharing class CMPRefreshCheckerController {
    @AuraEnabled
    public String recordId { get; set; }

    @AuraEnabled(cacheable=true)
    public static Demo_Component__c runApex(String searchKey){ 

        System.debug('Running CMPRefreshCheckerController.runApex');

        QueueComponentUpdateCheck updateJob = new QueueComponentUpdateCheck(searchKey); 
        ID updateJobbID = System.enqueueJob(updateJob);   

        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>([SELECT Id, Title__c FROM Demo_Component__c WHERE Id = :searchKey LIMIT 1]);
        if(demoComponents.size() > 0){
            system.debug('found Demo Component: ' + demoComponents[0].Title__c);
            //VersionHelper.componentUpdateCheck(demoComponents[0].Id);
            return demoComponents[0];
        }else{
            system.debug('Did not find the component');
        }
        return null;
        
    }
}
