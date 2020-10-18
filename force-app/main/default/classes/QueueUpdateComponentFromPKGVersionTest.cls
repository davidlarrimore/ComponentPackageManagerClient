@isTest
public with sharing class QueueUpdateComponentFromPKGVersionTest {
    public static final DateTime CURRENT_PACKAGE_VERSION_INSTALL_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_PACKAGE_VERSION_INSTALL_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);

    @testSetup 
    static void setup() {

    }
    
    static testmethod void testJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.RTA_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Package_Name__c = 'Visitor Management Demo Scenario',
            Latest_Package_Version_Name__c = '',
            Latest_Package_Version__c = '0.1.1-1',
            Subscriber_Package_Id__c = ApiCalloutMock.SUBSCRIBER_PACKAGE_ID,
            Latest_Subscriber_Package_Version_Id__c = '',
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );
        insert demoComponent;


        QueueUpdateComponentFromPackageVersion queueUpdateComponentFromPackageVersionJob = new QueueUpdateComponentFromPackageVersion(demoComponent.Id, ApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateComponentFromPackageVersionJob);
        QueueUpdateComponentFromPackageVersion.doLater(queueUpdateComponentFromPackageVersionJob.GetJobInfo(), demoComponent.Id, ApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
        Test.stopTest(); 
        
        
        Demo_Component__C updatedDemoComponent = [SELECT Id, Latest_Package_Version_Name__c FROM Demo_Component__c where Subscriber_Package_Id__c=:ApiCalloutMock.SUBSCRIBER_PACKAGE_ID LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals('ver 1.0', updatedDemoComponent.Latest_Package_Version_Name__c);
        System.assertEquals(jobId, jobInfo.Id);
    }


    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.RTA_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Package_Name__c = 'Visitor Management Demo Scenario',
            Latest_Package_Version_Name__c = '',
            Latest_Package_Version__c = '0.1.1-1',
            Subscriber_Package_Id__c = ApiCalloutMock.SUBSCRIBER_PACKAGE_ID,
            Latest_Subscriber_Package_Version_Id__c = '',
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );
        insert demoComponent;

        String ParentJobId = QueuePlatformAsyncEventHelper.generateId();
        QueueUpdateComponentFromPackageVersion queueUpdateComponentFromPackageVersionJob = new QueueUpdateComponentFromPackageVersion(ParentJobId, demoComponent.Id, ApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateComponentFromPackageVersionJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueUpdateComponentFromPackageVersionJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

    static testmethod void testJobUpdate() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.RTA_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Package_Name__c = 'Visitor Management Demo Scenario',
            Subscriber_Package_Id__c = ApiCalloutMock.SUBSCRIBER_PACKAGE_ID,
            Latest_Package_Version_Name__c = 'ver 0.1',
            Latest_Package_Version__c = '0.1.0-3',
            Latest_Subscriber_Package_Version_Id__c = ApiCalloutMock.PREVIOUS_SUBSCRIBER_PACKAGE_VERSION_ID,
            Package_Installed_Subscriber_Version_Id__c = ApiCalloutMock.PREVIOUS_SUBSCRIBER_PACKAGE_VERSION_ID,
            Installed_Version_Tracking_Method__c = 'None',
            Package_Installed_Version_Number__c = '0.1.0-3',
            Installed__c = true,
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );
        insert demoComponent;


        QueueUpdateComponentFromPackageVersion queueUpdateComponentFromPackageVersionJob = new QueueUpdateComponentFromPackageVersion(demoComponent.Id, ApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateComponentFromPackageVersionJob);
        QueueUpdateComponentFromPackageVersion.doLater(queueUpdateComponentFromPackageVersionJob.GetJobInfo(), demoComponent.Id, ApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
        Test.stopTest(); 
        
        Demo_Component__C updatedDemoComponent = [SELECT Id, Update_Available__c FROM Demo_Component__c where Subscriber_Package_Id__c=:ApiCalloutMock.SUBSCRIBER_PACKAGE_ID LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(true, updatedDemoComponent.Update_Available__c);
    }


    //Test Case for Dependent Components

}