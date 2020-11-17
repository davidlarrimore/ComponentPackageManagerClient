@isTest
public with sharing class CpmComponentInstallCheckerControllerTest {
    @testSetup 
    static void setup() {
    }
    
    static testmethod void testrunApex() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock());

        Cpm_Client_Settings__c newAppSetting = new Cpm_Client_Settings__c();
        insert newAppSetting;

        Test.startTest();        
            CpmComponentInstallCheckerController.runApex(true);
        Test.stopTest(); 

       Cpm_Component_Package__c demoComponentVM = [SELECT Id, Title__c, Installed__c, Installed_Version_Tracking_Method__c, Update_Available__c, Latest_Package_Version_Deprecated_Flag__c, Source_Installed_Commit_Hash__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals('gpbu visitor management', demoComponentVM.Title__c); 
        System.assertEquals('Github_Commit', demoComponentVM.Installed_Version_Tracking_Method__c); 
    }


    static testmethod void testrunApexNoSetting() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock());
        
        Test.startTest();        
            CpmComponentInstallCheckerController.runApex(false);
        Test.stopTest(); 

        List<Cpm_Client_Settings__c> appSettings = [SELECT Id, Last_Library_Refresh_Date__c, Initial_Config_Flag__c FROM Cpm_Client_Settings__c];
       
       System.assertEquals(1, appSettings.size());  
    }    

    static testmethod void testgetAppSettings() {

        Cpm_Client_Settings__c newAppSetting = new Cpm_Client_Settings__c();
        newAppSetting.Initial_Config_Flag__c = true;
        insert newAppSetting;


        Test.startTest();        
            Cpm_Client_Settings__c demoComponentManagerSetting = CpmComponentInstallCheckerController.getAppSettings();
        Test.stopTest(); 
           
        System.assertEquals(true, demoComponentManagerSetting.Initial_Config_Flag__c);  
    }

    static testmethod void testgetAppSettingsNoSetting() {

        Test.startTest();        
            Cpm_Client_Settings__c demoComponentManagerSetting = CpmComponentInstallCheckerController.getAppSettings();
        Test.stopTest(); 
           
        System.assertEquals(false, demoComponentManagerSetting.Initial_Config_Flag__c);  
    }
}