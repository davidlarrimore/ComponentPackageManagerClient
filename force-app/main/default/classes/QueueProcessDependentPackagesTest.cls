@isTest
public with sharing class QueueProcessDependentPackagesTest {

    @testSetup 
    static void setup() {
        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
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
    }
    
    static testmethod void testJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        List<String> dependentPackageVersionIds = new List<String>{ApiCalloutMock.PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_VERSION_ID, ApiCalloutMock.PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_VERSION_ID};

        Demo_Component__c demoComponent = [SELECT Id FROM Demo_Component__c where Subscriber_Package_Id__c =:ApiCalloutMock.SUBSCRIBER_PACKAGE_ID LIMIT 1];


        QueueProcessDependentPackages queueProcessDependentPackagesJob = new QueueProcessDependentPackages(String.valueOf(demoComponent.Id),dependentPackageVersionIds);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueProcessDependentPackagesJob);
        QueueProcessDependentPackages.doLater(queueProcessDependentPackagesJob.GetJobInfo(), String.valueOf(demoComponent.Id), dependentPackageVersionIds);
        Test.stopTest(); 
        
        List<Demo_Component__C> demoComponents = [SELECT Id FROM Demo_Component__c];

        List<Component_Dependency__c> dependentComponents = [SELECT Id FROM Component_Dependency__c where Demo_Component__c = :demoComponent.Id];
        
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(2, dependentComponents.size());
        System.assertEquals(3, demoComponents.size());  
        System.assertEquals(jobId, jobInfo.Id);
    }


    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        List<String> dependentPackageVersionIds = new List<String>{ApiCalloutMock.PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_VERSION_ID, ApiCalloutMock.PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_VERSION_ID};

        Demo_Component__c demoComponent = [SELECT Id FROM Demo_Component__c where Subscriber_Package_Id__c =:ApiCalloutMock.SUBSCRIBER_PACKAGE_ID LIMIT 1];

        String ParentJobId = QueuePlatformAsyncEventHelper.generateId();
        QueueProcessDependentPackages queueProcessDependentPackagesJob = new QueueProcessDependentPackages(ParentJobId, String.valueOf(demoComponent.Id), dependentPackageVersionIds);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueProcessDependentPackagesJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueProcessDependentPackagesJob.GetJobInfo(QueuePlatformAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

}