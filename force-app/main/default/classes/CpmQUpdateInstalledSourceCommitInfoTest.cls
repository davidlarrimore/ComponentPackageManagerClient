@isTest
public with sharing class CpmQUpdateInstalledSourceCommitInfoTest {
    public static final DateTime RTA_CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime RTA_PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);


    @testSetup 
    static void setup() {
        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.RTA_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextAreaFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = CpmApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = RTA_CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Source_installed_Commit_DateTime__c = RTA_PREVIOUS_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = CpmApiCalloutMock.RTA_GITHUB_PREVIOUS_COMMIT_HASH
        );

        insert demoComponent;
    }
    
    static testmethod void testJobCurrentCommit() {
        Cpm_Component_Package__c demoComponent = [SELECT Id, Github_Repository_URL__c, Source_installed_Commit_DateTime__c, Source_Installed_Commit_Hash__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        
        CpmQUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new CpmQUpdateInstalledSourceCommitInfo(demoComponent.Id, CpmApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob);
        CpmQUpdateInstalledSourceCommitInfo.doLater(queueUpdateInstalledSourceCommitInfoJob.GetJobInfo(), demoComponent.Id, CpmApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH);
        Test.stopTest(); 

        Cpm_Component_Package__c updatedDemoComponent = [SELECT Id, Github_Repository_URL__c, Source_installed_Commit_DateTime__c, Source_Installed_Commit_Hash__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(CpmApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH, updatedDemoComponent.Source_Installed_Commit_Hash__c);
        System.assertEquals(jobId, jobInfo.Id);
    }
 

    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c();
        
        demoComponent = [SELECT Id, Github_Repository_URL__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        String ParentJobId = CpmAsyncEventHelper.generateId();

        CpmQUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new CpmQUpdateInstalledSourceCommitInfo(ParentJobId, demoComponent.Id, CpmApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH);
        
        Test.startTest();        
            System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueUpdateInstalledSourceCommitInfoJob.GetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

}