public with sharing class CustomSettingHelper {


    public static Demo_Component_Manager_Settings__c getAppSettings(){ 
        System.debug('Running CustomSettingHelper.CustomSettingHelper');
        Demo_Component_Manager_Settings__c appSetting = new Demo_Component_Manager_Settings__c();
        List<Demo_Component_Manager_Settings__c> appSettings = [SELECT Id, Last_Library_Refresh_Date__c, Initial_Config_Flag__c, Sandbox_Flag__c, App_Deployer_URL__c FROM Demo_Component_Manager_Settings__c];

        if(appSettings.size() == 0){
            System.debug('No Demo_Component_Manager_Settings__c Found. Initializing');
            appSetting = CustomSettingHelper.initializeAppSettings();
        }else{
            appSetting = appSettings[0];
        }

        return appSetting;
    }    

    public static Demo_Component_Manager_Settings__c initializeAppSettings(){ 
        System.debug('Running CustomSettingHelper.initializeAppSettings');
        List<Demo_Component_Manager_Settings__c> appSettings = [SELECT Id, Last_Library_Refresh_Date__c, Initial_Config_Flag__c, Sandbox_Flag__c, App_Deployer_URL__c FROM Demo_Component_Manager_Settings__c];

        if(appSettings.size() != 0){
            delete appSettings;
        }

        Demo_Component_Manager_Settings__c appSetting = new Demo_Component_Manager_Settings__c();
        System.debug('Initializing appSettings');
        Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
        if(organization.IsSandbox){
            appSetting.Sandbox_Flag__c = true; 
            appSetting.App_Deployer_URL__c = 'http://localhost:8443/byoo';
        }else{
            appSetting.Sandbox_Flag__c = false;
            appSetting.App_Deployer_URL__c = 'https://gpbu-deployer.herokuapp.com/byoo';           
        }   


        insert appSetting;

        return appSetting;
    }    



}
