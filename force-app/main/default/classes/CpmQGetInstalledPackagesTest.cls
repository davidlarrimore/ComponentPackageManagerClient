@isTest
public with sharing class CpmQGetInstalledPackagesTest {
    public static final DateTime CURRENT_PACKAGE_VERSION_INSTALL_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_PACKAGE_VERSION_INSTALL_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);

    @testSetup 
    static void setup() {

    }
    
    static testmethod void testJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 

        CpmQGetInstalledPackages queueGetInstalledPackagesJob = new CpmQGetInstalledPackages();
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueGetInstalledPackagesJob);
        CpmQGetInstalledPackages.doLater(queueGetInstalledPackagesJob.GetJobInfo());
        Test.stopTest(); 
        
        
        List<Cpm_Component_Package__c> demoComponents = [SELECT Id FROM Cpm_Component_Package__c];
        AsyncApexJob jobInfo = [SELECT Id, Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :jobId LIMIT 1];

        System.assertEquals(16, demoComponents.size());
        System.assertEquals(jobId, jobInfo.Id);
        System.assertEquals(CpmAsyncEventHelper.STAGE_COMPLETED, queueGetInstalledPackagesJob.GetJobInfo(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE));
    }


    static testmethod void testChildJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 


        String ParentJobId = CpmAsyncEventHelper.generateId();
        CpmQGetInstalledPackages queueGetInstalledPackagesJob = new CpmQGetInstalledPackages(ParentJobId);
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueGetInstalledPackagesJob);
        Test.stopTest(); 
        
        System.assertEquals(ParentJobId, queueGetInstalledPackagesJob.GetJobInfo(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID));
    }

    static testmethod void testHasExistingJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        
        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c(
            Github_Repository_URL__c = null,
            SFDX_Package_Enabled_Flag__c=false,
            Source_Install_Type_Flag__c=false,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Demo Cleanup',
            Package_Name__c = 'Demo Cleanup',
            Subscriber_Package_Id__c = '0332E000000GTe7QAG',
            Latest_Package_Version_Name__c = 'Version 1.1.',
            Latest_Package_Version__c = '1.1.5-1',
            Latest_Subscriber_Package_Version_Id__c = '04t2E000003oc9rQAA',
            Installed__c = false,
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );
        insert demoComponent;

        Id demoComponentId = demoComponent.Id;
        CpmQGetInstalledPackages queueGetInstalledPackagesJob = new CpmQGetInstalledPackages();
        
        Test.startTest();        
        Id jobId = System.enqueueJob(queueGetInstalledPackagesJob);
        CpmQGetInstalledPackages.doLater(queueGetInstalledPackagesJob.GetJobInfo());
        Test.stopTest(); 
 
        Cpm_Component_Package__c updatedDemoComponent = [SELECT Id, Update_Available__c, Installed__c, Package_Installed_Version_Number__c, Package_Installed_Subscriber_Version_Id__c FROM Cpm_Component_Package__c where Id = :demoComponentId LIMIT 1];
       

        System.assertEquals(true, updatedDemoComponent.Installed__c);
    }    


    static testmethod void testUpdatedComponentJob() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        
        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c(
            Github_Repository_URL__c = null,
            SFDX_Package_Enabled_Flag__c=false,
            Source_Install_Type_Flag__c=false,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Demo Cleanup',
            Package_Name__c = 'Demo Cleanup',
            Subscriber_Package_Id__c = '0332E000000GTe7QAG',
            Latest_Package_Version_Name__c = 'Version 1.0.',
            Latest_Package_Version__c = '1.0.5-1',
            Latest_Subscriber_Package_Version_Id__c = '04t2E000003oc9rQAA',
            Package_Installed_Subscriber_Version_Id__c = CpmApiCalloutMock.PREVIOUS_SUBSCRIBER_PACKAGE_VERSION_ID,
            Installed_Version_Tracking_Method__c = 'None',
            Package_Installed_Version_Number__c = '0.1.0-3',
            Installed__c = true,
            Install_Date__c = PREVIOUS_PACKAGE_VERSION_INSTALL_DATETIME,
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );

        insert demoComponent;

        Id demoComponentId = demoComponent.Id;

        CpmQGetInstalledPackages queueGetInstalledPackagesJob = new CpmQGetInstalledPackages();
    
        Test.startTest();        
        Id jobId = System.enqueueJob(queueGetInstalledPackagesJob);
        CpmQGetInstalledPackages.doLater(queueGetInstalledPackagesJob.GetJobInfo());
        Test.stopTest(); 

        Cpm_Component_Package__c updatedDemoComponent = [SELECT Id, Update_Available__c, Installed__c, Install_Date__c, Package_Installed_Version_Number__c, Package_Installed_Subscriber_Version_Id__c FROM Cpm_Component_Package__c where Id = :demoComponentId LIMIT 1];
        
        System.assertEquals('04t2E000003oc9rQAA', updatedDemoComponent.Package_Installed_Subscriber_Version_Id__c);
        System.assert(true, updatedDemoComponent.Install_Date__c > PREVIOUS_PACKAGE_VERSION_INSTALL_DATETIME);
    }    
   
}