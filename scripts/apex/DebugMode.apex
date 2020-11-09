//Enable debug mode for the default scratch org user
User defaultUser = [SELECT Id FROM User WHERE Name = 'User User'];
defaultUser.UserPreferencesUserDebugModePref = true;
update defaultUser;

System.debug('Running CPMInstallCheckerController.getAppSettings');

Demo_Component_Manager_Settings__c appSetting = new Demo_Component_Manager_Settings__c();
List<Demo_Component_Manager_Settings__c> appSettings = [SELECT Id, Last_Library_Refresh_Date__c, Initial_Config_Flag__c, Sandbox_Flag__c FROM Demo_Component_Manager_Settings__c];

if(appSettings.size() == 0){
    System.debug('Initializing appSettings');
    Organization organization = [SELECT IsSandbox FROM Organization LIMIT 1];
    if(organization.IsSandbox){
        appSetting.Sandbox_Flag__c = false;
    }else{
        appSetting.Sandbox_Flag__c = true; 
    }   
    insert appSetting;
}else{
    appSetting = appSettings[0];
}

appSetting.Sandbox_Flag__c = true;
update appSetting;