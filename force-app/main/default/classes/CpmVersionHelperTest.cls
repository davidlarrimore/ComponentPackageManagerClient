@isTest
public with sharing class CpmVersionHelperTest {
    public static final DateTime CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);

    @testSetup 
    static void setup() {
    }
    
    static testmethod void testAddGithubComponent() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 

        Test.startTest();        
        CpmVersionHelper.AddGithubComponent(CpmApiCalloutMock.VM_GITHUB_REPO_URL, new Map<String,String>());
        Test.stopTest(); 
        
        Cpm_Component_Package__c demoComponent = [SELECT Id,Source_Install_Type_Flag__c, Title__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
        
        System.assertEquals('gpbu visitor management', demoComponent.Title__c);    
        System.assertEquals(true, demoComponent.Source_Install_Type_Flag__c);
    }

    static testmethod void testRefreshComponent() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 

        DateTime currentRefresh = datetime.now();
        currentRefresh.addDays(-3);

        Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.VM_GITHUB_REPO_URL,
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
        CpmVersionHelper.RefreshComponent(String.valueOf(demoComponent.Id));
        Test.stopTest(); 
        
        Cpm_Component_Package__c demoComponentUpdate = [SELECT Id, Last_Fetched__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
        System.assert(true, currentRefresh < demoComponentUpdate.Last_Fetched__c); 
    } 

    static testmethod void testgetinstalledXTAGs() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock());

        String jobId = CpmAsyncEventHelper.generateId();

        Test.startTest();        
        CpmVersionHelper.getinstalledXTAGs(jobId);
        Test.stopTest(); 
        
        List<Cpm_Component_Package__c> demoComponents = [SELECT Id FROM Cpm_Component_Package__c];
     
        System.assertEquals(2, demoComponents.size()); 
    } 


    static testmethod void testprocessXTagNewComponent() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock());

        String jobId = CpmAsyncEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmVersionHelper.class.getName(),
            CpmAsyncEventHelper.FIELD_JOB_ID => jobId,
            CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => CpmAsyncEventHelper.STAGE_PROCESSING
        };

        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
        
        Test.startTest();        
        CpmVersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile));
        Test.stopTest(); 
        
        Cpm_Component_Package__c demoComponentVM = [SELECT Id, Title__c, Installed__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals('gpbu visitor management', demoComponentVM.Title__c); 
    } 


    static testmethod void testprocessXTagExistingComponent() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock());
        DateTime currentRefresh = datetime.now();
        currentRefresh.addDays(-3);
        List<Cpm_Component_Package__c> demoComponents = new List<Cpm_Component_Package__c>();

        demoComponents.add(new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = CpmApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME
        ));

        insert demoComponents;
  
        String jobId = CpmAsyncEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmVersionHelper.class.getName(),
            CpmAsyncEventHelper.FIELD_JOB_ID => jobId,
            CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => CpmAsyncEventHelper.STAGE_PROCESSING
        };

        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
        
        Test.startTest();        
        CpmVersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile));
        Test.stopTest(); 
        
        Cpm_Component_Package__c demoComponentVM = [SELECT Id, Installed__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals(true, demoComponentVM.Installed__c); 
        System.assertEquals(CpmApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, demoComponentVM.Source_Installed_Commit_Hash__c); 
    } 

    static testmethod void testprocessXTagExistingInstalledComponent() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock());
        
        DateTime currentRefresh = datetime.now();
        currentRefresh.addDays(-3);
        List<Cpm_Component_Package__c> demoComponents = new List<Cpm_Component_Package__c>();

        demoComponents.add(new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = CpmApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = true,
            Installed_Version_Tracking_Method__c = 'Github_Commit',            
            Source_installed_Commit_DateTime__c = PREVIOUS_COMMIT_DATETIME,
            Install_Date__c = PREVIOUS_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = CpmApiCalloutMock.VM_GITHUB_PREVIOUS_COMMIT_HASH
        ));

        insert demoComponents;
  
        String jobId = CpmAsyncEventHelper.generateId();
        Map<String,String> jobInfo = new Map<String,String>{
            CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmVersionHelper.class.getName(),
            CpmAsyncEventHelper.FIELD_JOB_ID => jobId,
            CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => CpmAsyncEventHelper.STAGE_PROCESSING
        };

        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
        

        Test.startTest();        
        CpmVersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile));
        Test.stopTest(); 
        
        Cpm_Component_Package__c demoComponentVM = [SELECT Id, Installed__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals(false, demoComponentVM.Update_Available__c); 
        System.assertEquals(CpmApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, demoComponentVM.Source_Installed_Commit_Hash__c); 
    } 

    static testmethod void testXTagFile() {
        List<StaticResource> staticResources = new List<StaticResource>();
        staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFileVM'];
        XTagFile xTagFile = new XTagFile();
        xTagFile = (XTagFile)System.JSON.deserialize(staticResources[0].Body.toString(), XTagFile.class);
     
        System.assertEquals(CpmApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, xTagFile.commitHash); 
        System.assertEquals(null, xTagFile.demoComponentAlreadyExistsFlag);
    } 



}