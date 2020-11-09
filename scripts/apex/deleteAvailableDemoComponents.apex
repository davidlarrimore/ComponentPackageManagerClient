List<Demo_Component__c> demoComponents = [Select Id from Demo_Component__c WHERE Installed__c = false];
delete demoComponents;