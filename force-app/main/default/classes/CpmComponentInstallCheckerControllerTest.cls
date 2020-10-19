@isTest
public with sharing class CpmComponentInstallCheckerControllerTest {
    @testSetup 
    static void setup() {
    }
    
    static testmethod void testrunApex() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock());

        Test.startTest();        
        CpmComponentInstallCheckerController.runApex();
        Test.stopTest(); 

       Demo_Component__C demoComponentVM = [SELECT Id, Title__c, Installed__c, Installed_Version_Tracking_Method__c, Update_Available__c, Source_Installed_Commit_Hash__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.VM_GITHUB_REPO_URL LIMIT 1];
                
        System.assertEquals('gpbu visitor management', demoComponentVM.Title__c); 
        System.assertEquals('Github_Commit', demoComponentVM.Installed_Version_Tracking_Method__c); 
    }
}