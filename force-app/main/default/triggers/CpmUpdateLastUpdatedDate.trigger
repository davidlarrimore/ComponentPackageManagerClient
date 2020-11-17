trigger CpmUpdateLastUpdatedDate on Cpm_Component_Package__c (before insert, before update) {
    for(Cpm_Component_Package__c demoComponent : Trigger.New) {
        demoComponent.Last_Modified_Date__c = System.Now();
    }
}