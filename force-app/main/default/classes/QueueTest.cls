@isTest
public with sharing class QueueTest {
    public static final String richTextAreaFSCGithubUrl = 'https://github.com/davidlarrimore/richTextInputFSC';

    @testSetup 
    static void setup() {
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>();
        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = QueueTest.richTextAreaFSCGithubUrl,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'richTextAreaFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81',
            Latest_Commit_DateTime__c = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class)
        ));

        insert demoComponents;
    }
    
    static testmethod void testQueueable() {
        Test.setMock(HttpCalloutMock.class, new GithubApiGetRepoCalloutMock()); 
        
        Demo_Component__C demoComponent = [SELECT Id FROM Demo_Component__c where Github_Repository_URL__c =:QueueTest.richTextAreaFSCGithubUrl LIMIT 1];
        QueueUpdateComponentFromGithubRepo queueUpdateComponentFromGithubRepoJob = new QueueUpdateComponentFromGithubRepo(demoComponent.Id);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateComponentFromGithubRepoJob);
        Test.stopTest(); 
        
        
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];
        
        //System.debug('Demo Component: ' + updatedDemoComponent);
        //System.assertEquals('David Larrimore', updatedDemoComponent.POC_Name__c);
        System.assertEquals(jobId, jobInfo.Id);
    }

}