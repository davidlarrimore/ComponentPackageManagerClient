@isTest
public with sharing class CpmMetadataApiTest {


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

    static testmethod void testGetInstalledPackages() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        MetadataInstalledPackageResponse metadataInstalledPackageResponse = new MetadataInstalledPackageResponse();
        List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = new List<MetadataInstalledPackageResponseRecord>();
        MetadataInstalledPackageResponseRecord metadataInstalledPackageResponseRecord = new MetadataInstalledPackageResponseRecord();
        MetadataSubscriberPackage subscriberpackage = new MetadataSubscriberPackage();
        MetadataSubscriberPackageVersion subscriberPackageVersion = new MetadataSubscriberPackageVersion();

        Test.startTest();        
            metadataInstalledPackageResponseRecords = CpmMetadataAPIHelper.getInstalledPackages();
        Test.stopTest(); 

        System.assertNotEquals(null, metadataInstalledPackageResponse);

        metadataInstalledPackageResponseRecord = metadataInstalledPackageResponseRecords[0];
        subscriberpackage = metadataInstalledPackageResponseRecord.subscriberpackage;
        subscriberPackageVersion = metadataInstalledPackageResponseRecord.subscriberPackageVersion;

        
        System.assertEquals(16, metadataInstalledPackageResponseRecords.size());
        System.assertEquals('0331I000000Z2yGQAS', metadataInstalledPackageResponseRecord.subscriberPackageId);
        System.assertEquals('version 1.0', subscriberPackageVersion.name);
        System.assertEquals('User Badges, Skills and Contributions - Lightning', subscriberpackage.name);
    }  

    static testmethod void testGetInstallRequests() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        MetadataPackageInstallRequest metadataPackageInstallRequest = new MetadataPackageInstallRequest();
        List<MetadataPackageInstallRequestRecord> metadataPackageInstallRequestRecords = new List<MetadataPackageInstallRequestRecord>();
        MetadataPackageInstallRequestRecord metadataPackageInstallRequestRecord = new MetadataPackageInstallRequestRecord();

        Test.startTest();        
        metadataPackageInstallRequestRecords = CpmMetadataAPIHelper.getInstallRequests();
        Test.stopTest(); 

        System.assertNotEquals(null, metadataPackageInstallRequest);

        metadataPackageInstallRequestRecord = metadataPackageInstallRequestRecords[0];
        
        System.assertEquals(3, metadataPackageInstallRequestRecords.size());
        System.assertEquals('04t1Q0000016Ygj', metadataPackageInstallRequestRecord.SubscriberPackageVersionKey);
    }  


    static testmethod void testGetInstalledPackages404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        List<MetadataInstalledPackageResponseRecord> metadataInstalledPackageResponseRecords = new List<MetadataInstalledPackageResponseRecord>();

        Test.startTest();        
            metadataInstalledPackageResponseRecords = CpmMetadataAPIHelper.getInstalledPackages();
        Test.stopTest(); 

        System.assertEquals(null, metadataInstalledPackageResponseRecords);
    }  

    static testmethod void testGetSubscriberPackageVersion() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        MetadataSubscriberPackageVersionResponse metadataSubscriberPackageVersionResponse = new MetadataSubscriberPackageVersionResponse();
        MetadataSubscriberPackageVersion subscriberPackageVersion = new MetadataSubscriberPackageVersion();
        MetadataSubscriberPackageDependencies dependencies = new MetadataSubscriberPackageDependencies();
        List<Map<String,String>> ids = new List<Map<String,String>>();
        Test.startTest();        
            subscriberPackageVersion = CpmMetadataAPIHelper.getSubscriberPackageVersion(CpmApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
        Test.stopTest(); 
        
        dependencies = subscriberPackageVersion.dependencies;
        ids = dependencies.ids;

        System.assertEquals(null, metadataSubscriberPackageVersionResponse.size);
        System.assertEquals('0333h000000AY9lAAG', subscriberPackageVersion.subscriberPackageId);
        System.assertEquals('04t1K000002J0KKQA0', ids[0].get('subscriberPackageVersionId'));
        System.assertEquals(0, subscriberPackageVersion.majorVersion);
        System.assertEquals(1, subscriberPackageVersion.minorVersion);
        System.assertEquals(1, subscriberPackageVersion.buildNumber);
        System.assertEquals(1, subscriberPackageVersion.patchVersion);                       
    }  

    static testmethod void testGetSubscriberPackageVersion404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        MetadataSubscriberPackageVersion subscriberPackageVersion = new MetadataSubscriberPackageVersion();
        
        Test.startTest();        
            subscriberPackageVersion = CpmMetadataAPIHelper.getSubscriberPackageVersion(CpmApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
        Test.stopTest(); 
        
        System.assertEquals(null, subscriberPackageVersion);                   
    }    
    
    static testmethod void testGetSubscriberPackage() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        MetadataSubscriberPackageResponse metadataSubscriberPackageResponse = new MetadataSubscriberPackageResponse();
        MetadataSubscriberPackage subscriberpackage = new MetadataSubscriberPackage();

        Test.startTest();        
            subscriberpackage = CpmMetadataAPIHelper.getSubscriberPackage(CpmApiCalloutMock.SUBSCRIBER_PACKAGE_ID);
        Test.stopTest(); 
        
        System.assertEquals(null, metadataSubscriberPackageResponse.size);
        System.assertEquals('Visitor Management Demo Scenario', subscriberpackage.name);
               
    }      

    static testmethod void testGetSubscriberPackage404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        MetadataSubscriberPackage subscriberpackage = new MetadataSubscriberPackage();

        Test.startTest();        
            subscriberpackage = CpmMetadataAPIHelper.getSubscriberPackage(CpmApiCalloutMock.SUBSCRIBER_PACKAGE_ID);
        Test.stopTest(); 
        
        System.assertEquals(null, subscriberpackage);      
    }    
    
}