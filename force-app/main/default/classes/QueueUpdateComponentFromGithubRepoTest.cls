@isTest
public with sharing class QueueUpdateComponentFromGithubRepoTest {
    public static final String OLD_COMMIT = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81';
    public static final String CURRENT_COMMIT = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81';

    @testSetup 
    static void setup() {
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>();
        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.RTA_GITHUB_REPO_URL,
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
    
    static testmethod void testJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        Demo_Component__C demoComponent = new Demo_Component__C();
        
        demoComponent = [SELECT Id, Github_Repository_URL__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        QueueUpdateComponentFromGithubRepo queueUpdateComponentFromGithubRepoJob = new QueueUpdateComponentFromGithubRepo(demoComponent.Id);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateComponentFromGithubRepoJob);
        QueueUpdateComponentFromGithubRepo.doLater(queueUpdateComponentFromGithubRepoJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest(); 
        
        
        Demo_Component__C updatedDemoComponent = [SELECT Id, POC_Name__c, Description__c FROM Demo_Component__c where Id =:demoComponent.Id LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals('David Larrimore', updatedDemoComponent.POC_Name__c);
        System.assertEquals(jobId, jobInfo.Id);
        System.assertNotEquals(null, updatedDemoComponent.Description__c);
        System.assertNotEquals(null, queueUpdateComponentFromGithubRepoJob.GetJobInfo());
    }

    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        Demo_Component__C demoComponent = new Demo_Component__C();
        
        demoComponent = [SELECT Id, Github_Repository_URL__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        String ParentJobId = QueuePlatformAsyncEventHelper.generateId();

        QueueUpdateComponentFromGithubRepo queueUpdateComponentFromGithubRepoJob = new QueueUpdateComponentFromGithubRepo(ParentJobId, demoComponent.Id);
        
        Test.startTest();        
            System.enqueueJob(queueUpdateComponentFromGithubRepoJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueUpdateComponentFromGithubRepoJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

}