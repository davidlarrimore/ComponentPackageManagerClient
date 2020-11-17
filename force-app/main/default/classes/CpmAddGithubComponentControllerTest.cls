@isTest
public with sharing class CpmAddGithubComponentControllerTest {
    public static final DateTime CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);


    @testSetup 
    static void setup() {
    }
    
    static testmethod void testrunApex() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 

        Test.startTest();        
        CpmAddGithubComponentController.runApex(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 

        Cpm_Component_Package__c demoComponent = [SELECT Id, Title__c FROM Cpm_Component_Package__c where Github_Repository_URL__c =:CpmApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        
        System.assertEquals('richTextInputFSC', demoComponent.Title__c);
    }
}