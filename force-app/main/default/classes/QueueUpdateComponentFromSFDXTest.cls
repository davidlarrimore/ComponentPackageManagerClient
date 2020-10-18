@isTest
public with sharing class QueueUpdateComponentFromSFDXTest {

    @testSetup 
    static void setup() {
    }
    
    static testmethod void testJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario'
        );

        insert demoComponent;

        QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(demoComponent.Id);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueUpdateComponentFromSFDXJob);
        QueueUpdateComponentFromSFDX.doLater(queueUpdateComponentFromSFDXJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest(); 
        
        
        Demo_Component__C updatedDemoComponent = [SELECT Id, SFDX_Package_Name__c, Latest_SFDX_Package_Alias__c FROM Demo_Component__c where Id =:demoComponent.Id LIMIT 1];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals('Visitor Management Demo Scenario', updatedDemoComponent.SFDX_Package_Name__c);
        System.assertEquals('Visitor Management Demo Scenario@0.1.1-1', updatedDemoComponent.Latest_SFDX_Package_Alias__c);       
        System.assertEquals(jobId, jobInfo.Id);
    }

    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = datetime.now(),
            Latest_SFDX_Package_Alias__c = 'Visitor Management Demo Scenario@0.1.1-1',
            Latest_SFDX_Package_Version_Name__c = 'ver 1.0',
            SFDX_Package_Name__c = 'Visitor Management Demo Scenario'
        );

        insert demoComponent;
        
        String ParentJobId = QueuePlatformAsyncEventHelper.generateId();

        QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(ParentJobId, demoComponent.Id);
        
        Test.startTest();        
            System.enqueueJob(queueUpdateComponentFromSFDXJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueUpdateComponentFromSFDXJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

    static testmethod void testNoSFDXProjectDotJSON() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock());

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario'
        );

        insert demoComponent;

        QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(demoComponent.Id);
        
        Test.startTest();        
        System.enqueueJob(queueUpdateComponentFromSFDXJob);
        QueueUpdateComponentFromSFDX.doLater(queueUpdateComponentFromSFDXJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest(); 
        
        
        Demo_Component__C updatedDemoComponent = [SELECT Id, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c where Id =:demoComponent.Id LIMIT 1];
        System.assertEquals(false, updatedDemoComponent.SFDX_Package_Enabled_Flag__c);
    }

    static testmethod void testNotAnSFDXProject() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock());

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = null,
            SFDX_Package_Enabled_Flag__c=false,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'TestTest'
        );

        insert demoComponent;

        QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(demoComponent.Id);
        
        Test.startTest();        
        System.enqueueJob(queueUpdateComponentFromSFDXJob);
        QueueUpdateComponentFromSFDX.doLater(queueUpdateComponentFromSFDXJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest(); 
        
        
        Demo_Component__C updatedDemoComponent = [SELECT Id, Title__c FROM Demo_Component__c where Id =:demoComponent.Id LIMIT 1];
        System.assertEquals('TestTest', updatedDemoComponent.Title__c);
    }

    static testmethod void testNoDemoComponentFound() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock());

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=false,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'TestTest'
        );

        insert demoComponent;
        Id demoComponentId = demoComponent.Id;
        delete demoComponent;

        QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(demoComponentId);
        
        Test.startTest();        
        System.enqueueJob(queueUpdateComponentFromSFDXJob);
        QueueUpdateComponentFromSFDX.doLater(queueUpdateComponentFromSFDXJob.GetJobInfo(), demoComponentId);
        Test.stopTest(); 
        
        System.assertEquals(QueuePlatformAsyncEventHelper.STAGE_FAILED, queueUpdateComponentFromSFDXJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE));
    }

    static testmethod void testUpdate() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = datetime.now(),
            Latest_SFDX_Package_Alias__c = 'Visitor Management Demo Scenario@0.1.0-3',
            Latest_SFDX_Package_Version_Name__c = 'ver 1.0',
            Latest_Package_Version__c = '0.1.0-3',
            Subscriber_Package_Id__c = '0333h000000AY9lAAG',
            Installed__c = true,
            Installed_Version_Tracking_Method__c = 'SFDX_Project',
            SFDX_Installed_Package_Alias__c = 'Visitor Management Demo Scenario@0.1.0-3',
            SFDX_Installed_Package_Version_Name__c = 'ver 1.0',
            SFDX_Package_Name__c = 'Visitor Management Demo Scenario',
            Package_Installed_Version_Number__c = '0.1.0-3', 
            Package_Installed_Subscriber_Version_Id__c = '04t3h000004bdNOAAY'
        );

        insert demoComponent;

        QueueUpdateComponentFromSFDX queueUpdateComponentFromSFDXJob = new QueueUpdateComponentFromSFDX(demoComponent.Id);
        
        Test.startTest();        
            System.enqueueJob(queueUpdateComponentFromSFDXJob);
            QueueUpdateComponentFromSFDX.doLater(queueUpdateComponentFromSFDXJob.GetJobInfo(), demoComponent.Id);
        Test.stopTest(); 
        
        Demo_Component__C updatedDemoComponent = [SELECT Id, Update_Available__c, Latest_SFDX_Package_Alias__c, Latest_Subscriber_Package_Version_Id__c FROM Demo_Component__c where Id =:demoComponent.Id LIMIT 1];
        System.assertEquals(true, updatedDemoComponent.Update_Available__c);
        System.assertEquals('Visitor Management Demo Scenario@0.1.1-1', updatedDemoComponent.Latest_SFDX_Package_Alias__c);
        System.assertEquals('04t3h000004bdPAAAY', updatedDemoComponent.Latest_Subscriber_Package_Version_Id__c);        
    }



}