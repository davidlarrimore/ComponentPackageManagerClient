@isTest
public with sharing class QueueUpdateComponentSourceCommitInfoTest {
    public static final DateTime CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);


    @testSetup
    static void setup() {
    }

    static testmethod void testJobCurrentCommit() {
        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextAreaFSC',
            Installed_Version_Tracking_Method__c = 'Github_Commit',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.GITHUB_CURRENT_COMMIT_HASH, //Current Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = false,
            Source_installed_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.GITHUB_CURRENT_COMMIT_HASH
        );
        insert demoComponent;

        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(demoComponent.Id);

        Test.startTest();
        Id jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
        QueueUpdateComponentSourceCommitInfo.doLater(queueUpdateComponentSourceCommitInfoJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest();

        Demo_Component__c updatedDemoComponent = [SELECT Id, Github_Repository_URL__c, Latest_Commit_Hash__c, Update_Available__c, Source_installed_Commit_DateTime__c, Source_Installed_Commit_Hash__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.GITHUB_REPO_URL LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(ApiCalloutMock.GITHUB_CURRENT_COMMIT_HASH, updatedDemoComponent.Latest_Commit_Hash__c);
        System.assertEquals(false, updatedDemoComponent.Update_Available__c);
        System.assertEquals(jobId, jobInfo.Id);
    }

    static testmethod void testJobPreviousCommit() {
        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextAreaFSC',
            Installed_Version_Tracking_Method__c = 'Github_Commit',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.GITHUB_PREVIOUS_COMMIT_HASH, //Previous Commit
            Latest_Commit_DateTime__c = PREVIOUS_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = false,
            Source_installed_Commit_DateTime__c = PREVIOUS_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.GITHUB_PREVIOUS_COMMIT_HASH
        );
        insert demoComponent;

        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(demoComponent.Id);

        Test.startTest();
        Id jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
        QueueUpdateComponentSourceCommitInfo.doLater(queueUpdateComponentSourceCommitInfoJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest();

        Demo_Component__c updatedDemoComponent = [SELECT Id, Github_Repository_URL__c, Latest_Commit_Hash__c, Update_Available__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.GITHUB_REPO_URL LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(ApiCalloutMock.GITHUB_CURRENT_COMMIT_HASH, updatedDemoComponent.Latest_Commit_Hash__c);
        System.assertEquals(true, updatedDemoComponent.Update_Available__c);
        System.assertEquals(jobId, jobInfo.Id);
    }



    static testmethod void testJobDifferentTrackingMethod() {
        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextAreaFSC',
            Installed_Version_Tracking_Method__c = 'Github_Tag',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.GITHUB_PREVIOUS_COMMIT_HASH, //Previous Commit
            Latest_Commit_DateTime__c = PREVIOUS_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = false,
            Source_installed_Commit_DateTime__c = PREVIOUS_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.GITHUB_PREVIOUS_COMMIT_HASH
        );
        insert demoComponent;

        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(demoComponent.Id);

        Test.startTest();
        Id jobId = System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
        QueueUpdateComponentSourceCommitInfo.doLater(queueUpdateComponentSourceCommitInfoJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest();

        Demo_Component__c updatedDemoComponent = [SELECT Id, Github_Repository_URL__c, Latest_Commit_Hash__c, Update_Available__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.GITHUB_REPO_URL LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(ApiCalloutMock.GITHUB_CURRENT_COMMIT_HASH, updatedDemoComponent.Latest_Commit_Hash__c);
        System.assertEquals(false, updatedDemoComponent.Update_Available__c);
        System.assertEquals(jobId, jobInfo.Id);
    }

    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextAreaFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = false,
            Source_installed_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.GITHUB_PREVIOUS_COMMIT_HASH
        );
        insert demoComponent;
        String ParentJobId = QueuePlatformAsyncEventHelper.generateId();

        QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(ParentJobId, demoComponent.Id);

        Test.startTest();
            System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
        Test.stopTest();

        System.assertEquals(ParentJobId, queueUpdateComponentSourceCommitInfoJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

    static testmethod void testNoJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextAreaFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = false,
            Source_installed_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.GITHUB_PREVIOUS_COMMIT_HASH
        );
        insert demoComponent;
        String ParentJobId = QueuePlatformAsyncEventHelper.generateId();

        QueueUpdateComponentSourceCommitInfo queueUpdateComponentSourceCommitInfoJob = new QueueUpdateComponentSourceCommitInfo(demoComponent.Id);

        Test.startTest();
            System.enqueueJob(queueUpdateComponentSourceCommitInfoJob);
        Test.stopTest();

        System.assertNotEquals(null, queueUpdateComponentSourceCommitInfoJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_ID));
    }


}