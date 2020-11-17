@isTest
public with sharing class CpmClientCustomSettingHelperTest {

    @testSetup 
    static void setup() {
    }
    
    static testmethod void testExistingCustomSetting() {
        List<Cpm_Client_Settings__c> appSettings = [SELECT Id, Last_Library_Refresh_Date__c, Initial_Config_Flag__c, Sandbox_Flag__c FROM Cpm_Client_Settings__c]; 
        
        Cpm_Client_Settings__c appSetting = new Cpm_Client_Settings__c();
        appSetting.Sandbox_Flag__c = true; 
        insert appSetting;

        Test.startTest();        
            Cpm_Client_Settings__c getAppSetting = CpmClientCustomSettingHelper.getAppSettings();
        Test.stopTest(); 

        System.assertEquals(0, appSettings.size());    
        System.assertEquals(true, getAppSetting.Sandbox_Flag__c); 
    }

    static testmethod void testNoExistingCustomSetting() {
        List<Cpm_Client_Settings__c> beforeTestAppSetting = [SELECT Id, Last_Library_Refresh_Date__c, Initial_Config_Flag__c, Sandbox_Flag__c FROM Cpm_Client_Settings__c]; 
       
        Test.startTest();        
            Cpm_Client_Settings__c getAppSetting = CpmClientCustomSettingHelper.getAppSettings();
        Test.stopTest(); 
  
        List<Cpm_Client_Settings__c> afterTestAppSetting = [SELECT Id, Last_Library_Refresh_Date__c, Initial_Config_Flag__c, Sandbox_Flag__c FROM Cpm_Client_Settings__c]; 
       
        System.assertEquals(0, beforeTestAppSetting.size()); 
        System.assertEquals(1, afterTestAppSetting.size());                
    }

}