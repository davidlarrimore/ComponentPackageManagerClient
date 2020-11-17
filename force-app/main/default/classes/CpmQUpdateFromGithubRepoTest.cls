@isTest
public with sharing class CpmQUpdateFromGithubRepoTest {
    public static final String OLD_COMMIT = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81';
    public static final String CURRENT_COMMIT = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81';

    @testSetup 
    static void setup() {
        List<Cpm_Component_Package__c> demoComponents = new List<Cpm_Component_Package__c>();
        demoComponents.add(new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.RTA_GITHUB_REPO_URL,
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
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c();
        
        demoComponent = [SELECT Id, Github_Repository_URL__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        CpmQUpdateFromGithubRepo CpmQUpdateFromGithubRepoJob = new CpmQUpdateFromGithubRepo(demoComponent.Id);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(CpmQUpdateFromGithubRepoJob);
        CpmQUpdateFromGithubRepo.doLater(CpmQUpdateFromGithubRepoJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest(); 
        
        
        Cpm_Component_Package__c updatedDemoComponent = [SELECT Id, POC_Name__c, Description__c FROM Cpm_Component_Package__c where Id =:demoComponent.Id LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals('David Larrimore', updatedDemoComponent.POC_Name__c);
        System.assertEquals(jobId, jobInfo.Id);
        System.assertNotEquals(null, updatedDemoComponent.Description__c);
        System.assertNotEquals(null, CpmQUpdateFromGithubRepoJob.GetJobInfo());
    }

    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c();
        
        demoComponent = [SELECT Id, Github_Repository_URL__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        String ParentJobId = CpmAsyncEventHelper.generateId();

        CpmQUpdateFromGithubRepo CpmQUpdateFromGithubRepoJob = new CpmQUpdateFromGithubRepo(ParentJobId, demoComponent.Id);
        
        Test.startTest();        
            System.enqueueJob(CpmQUpdateFromGithubRepoJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, CpmQUpdateFromGithubRepoJob.GetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

}