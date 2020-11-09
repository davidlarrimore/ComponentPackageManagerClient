trigger UpdateLastUpdatedDate on Demo_Component__c (before insert, before update) {
    for(Demo_Component__c demoComponent : Trigger.New) {
        demoComponent.Last_Modified_Date__c = System.Now();
    }
}