@isTest
public with sharing class QueueUpdateInstalledSourceCommitInfoTest {
    public static final DateTime RTA_CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime RTA_PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);


    @testSetup 
    static void setup() {
        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.RTA_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextAreaFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = RTA_CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Source_installed_Commit_DateTime__c = RTA_PREVIOUS_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.RTA_GITHUB_PREVIOUS_COMMIT_HASH
        );

        insert demoComponent;
    }
    
    static testmethod void testJobCurrentCommit() {
        Demo_Component__c demoComponent = [SELECT Id, Github_Repository_URL__c, Source_installed_Commit_DateTime__c, Source_Installed_Commit_Hash__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        
        QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(demoComponent.Id, ApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob);
        QueueUpdateInstalledSourceCommitInfo.doLater(queueUpdateInstalledSourceCommitInfoJob.GetJobInfo(), demoComponent.Id, ApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH);
        Test.stopTest(); 

        Demo_Component__c updatedDemoComponent = [SELECT Id, Github_Repository_URL__c, Source_installed_Commit_DateTime__c, Source_Installed_Commit_Hash__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(ApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH, updatedDemoComponent.Source_Installed_Commit_Hash__c);
        System.assertEquals(jobId, jobInfo.Id);
    }
 

    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        Demo_Component__C demoComponent = new Demo_Component__C();
        
        demoComponent = [SELECT Id, Github_Repository_URL__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        String ParentJobId = QueuePlatformAsyncEventHelper.generateId();

        QueueUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new QueueUpdateInstalledSourceCommitInfo(ParentJobId, demoComponent.Id, ApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH);
        
        Test.startTest();        
            System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueUpdateInstalledSourceCommitInfoJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

}