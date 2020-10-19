@isTest
public with sharing class VersionHelperTest {
    public static final DateTime CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);

    @testSetup 
    static void setup() {
    }
    
    static testmethod void testAddGithubComponent() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Test.startTest();        
        VersionHelper.AddGithubComponent(ApiCalloutMock.VM_GITHUB_REPO_URL, new Map<String,String>());
        Test.stopTest(); 
        
        Demo_Component__C demoComponent = [SELECT Id,Source_Install_Type_Flag__c, Title__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
        
        System.assertEquals('gpbu visitor management', demoComponent.Title__c);    
        System.assertEquals(true, demoComponent.Source_Install_Type_Flag__c);
    }

    static testmethod void testRefreshComponent() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock()); 

        DateTime currentRefresh = datetime.now();
        currentRefresh.addDays(-3);

        Demo_Component__c demoComponent = new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = currentRefresh,
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

  
        Test.startTest();        
        VersionHelper.RefreshComponent(String.valueOf(demoComponent.Id));
        Test.stopTest(); 
        
        Demo_Component__C demoComponentUpdate = [SELECT Id, Last_Fetched__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
        System.assert(true, currentRefresh < demoComponentUpdate.Last_Fetched__c); 
    } 

    static testmethod void testgetinstalledXTAGs() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        String jobId = QueuePlatformAsyncEventHelper.generateId();

        Test.startTest();        
        VersionHelper.getinstalledXTAGs(jobId);
        Test.stopTest(); 
        
        List<Demo_Component__C> demoComponents = [SELECT Id FROM Demo_Component__c];
     
        System.assertEquals(2, demoComponents.size()); 
    } 


    static testmethod void testprocessXTagNewComponent() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        String jobId = QueuePlatformAsyncEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformAsyncEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformAsyncEventHelper.STAGE_PROCESSING
        };

        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
        
        Test.startTest();        
        VersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile));
        Test.stopTest(); 
        
        Demo_Component__C demoComponentVM = [SELECT Id, Title__c, Installed__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals('gpbu visitor management', demoComponentVM.Title__c); 
    } 


    static testmethod void testprocessXTagExistingComponent() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());
        DateTime currentRefresh = datetime.now();
        currentRefresh.addDays(-3);
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>();

        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME
        ));

        insert demoComponents;
  
        String jobId = QueuePlatformAsyncEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformAsyncEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformAsyncEventHelper.STAGE_PROCESSING
        };

        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
        
        Test.startTest();        
        VersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile));
        Test.stopTest(); 
        
        Demo_Component__C demoComponentVM = [SELECT Id, Installed__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals(true, demoComponentVM.Installed__c); 
        System.assertEquals(ApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, demoComponentVM.Source_Installed_Commit_Hash__c); 
    } 

    static testmethod void testprocessXTagExistingInstalledComponent() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());
        
        DateTime currentRefresh = datetime.now();
        currentRefresh.addDays(-3);
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>();

        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = true,
            Installed_Version_Tracking_Method__c = 'Github_Commit',            
            Source_installed_Commit_DateTime__c = PREVIOUS_COMMIT_DATETIME,
            Install_Date__c = PREVIOUS_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.VM_GITHUB_PREVIOUS_COMMIT_HASH
        ));

        insert demoComponents;
  
        String jobId = QueuePlatformAsyncEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            QueuePlatformAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            QueuePlatformAsyncEventHelper.FIELD_APEX_CLASS_NAME => VersionHelper.class.getName(),
            QueuePlatformAsyncEventHelper.FIELD_JOB_ID => jobId,
            QueuePlatformAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => QueuePlatformAsyncEventHelper.STAGE_PROCESSING
        };

        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
        

        Test.startTest();        
        VersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile));
        Test.stopTest(); 
        
        Demo_Component__C demoComponentVM = [SELECT Id, Installed__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals(false, demoComponentVM.Update_Available__c); 
        System.assertEquals(ApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, demoComponentVM.Source_Installed_Commit_Hash__c); 
    } 

    static testmethod void testXTagFile() {
        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = new XTagFile();
        xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
     
        System.assertEquals(ApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, xTagFile.commitHash); 
        System.assertEquals(null, xTagFile.demoComponentAlreadyExistsFlag);
    } 



}