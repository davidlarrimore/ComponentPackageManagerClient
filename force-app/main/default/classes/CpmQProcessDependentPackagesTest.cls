@isTest
public with sharing class CpmQProcessDependentPackagesTest {

    @testSetup 
    static void setup() {
        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Package_Name__c = 'Visitor Management Demo Scenario',
            Latest_Package_Version_Name__c = '',
            Latest_Package_Version__c = '0.1.1-1',
            Subscriber_Package_Id__c = CpmApiCalloutMock.SUBSCRIBER_PACKAGE_ID,
            Latest_Subscriber_Package_Version_Id__c = '',
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );
        insert demoComponent;
    }
    
    static testmethod void testJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        List<String> dependentPackageVersionIds = new List<String>{CpmApiCalloutMock.PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_VERSION_ID, CpmApiCalloutMock.PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_VERSION_ID};

        Cpm_Component_Package__c demoComponent = [SELECT Id FROM Cpm_Component_Package__c where Subscriber_Package_Id__c =:CpmApiCalloutMock.SUBSCRIBER_PACKAGE_ID LIMIT 1];


        CpmQProcessDependentPackages queueProcessDependentPackagesJob = new CpmQProcessDependentPackages(String.valueOf(demoComponent.Id),dependentPackageVersionIds);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueProcessDependentPackagesJob);
        CpmQProcessDependentPackages.doLater(queueProcessDependentPackagesJob.GetJobInfo(), String.valueOf(demoComponent.Id), dependentPackageVersionIds);
        Test.stopTest(); 
        
        List<Cpm_Component_Package__c> demoComponents = [SELECT Id FROM Cpm_Component_Package__c];

        List<Cpm_Component_Package_Dependency__c> dependentComponents = [SELECT Id FROM Cpm_Component_Package_Dependency__c where Cpm_Component_Package__c = :demoComponent.Id];
        
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(2, dependentComponents.size());
        System.assertEquals(3, demoComponents.size());  
        System.assertEquals(jobId, jobInfo.Id);
    }


    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        List<String> dependentPackageVersionIds = new List<String>{CpmApiCalloutMock.PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_VERSION_ID, CpmApiCalloutMock.PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_VERSION_ID};

        Cpm_Component_Package__c demoComponent = [SELECT Id FROM Cpm_Component_Package__c where Subscriber_Package_Id__c =:CpmApiCalloutMock.SUBSCRIBER_PACKAGE_ID LIMIT 1];

        String ParentJobId = CpmAsyncEventHelper.generateId();
        CpmQProcessDependentPackages queueProcessDependentPackagesJob = new CpmQProcessDependentPackages(ParentJobId, String.valueOf(demoComponent.Id), dependentPackageVersionIds);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueProcessDependentPackagesJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueProcessDependentPackagesJob.GetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

}