List<Cpm_Component_Package__c> demoComponents = [Select Id from Cpm_Component_Package__c WHERE Installed__c = false];
delete demoComponents;