@isTest
public with sharing class CpmRefreshCheckerControllerTest {
    public static final DateTime PREVIOUS_REFRESH_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);


    @testSetup 
    static void setup() {
    }
    
    static testmethod void testrunApex() {

        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock());

        Cpm_Component_Package__c demoComponent =  new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'Visitor Management Demo Scenario',
            Package_Name__c = 'Visitor Management Demo Scenario',
            Latest_Package_Version_Name__c = '',
            Latest_Package_Version__c = '0.1.1-1',
            Subscriber_Package_Id__c = CpmApiCalloutMock.SUBSCRIBER_PACKAGE_ID,
            Latest_Subscriber_Package_Version_Id__c = CpmApiCalloutMock.CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID,
            Last_Fetched__c = PREVIOUS_REFRESH_DATETIME,
            Update_Available__c = false
        );
        insert demoComponent;

        Test.startTest();        
        CpmRefreshCheckerController.runApex(demoComponent.Id, false);
        Test.stopTest(); 

       Cpm_Component_Package__c demoComponentVM = [SELECT Id, Title__c, Installed__c, Last_Fetched__c,Installed_Version_Tracking_Method__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
       System.assert(true, demoComponentVM.Last_Fetched__c > PREVIOUS_REFRESH_DATETIME); 
    }
}