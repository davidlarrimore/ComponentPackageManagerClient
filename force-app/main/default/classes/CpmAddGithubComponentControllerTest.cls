@isTest
public with sharing class CpmAddGithubComponentControllerTest {
    public static final DateTime CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);


    @testSetup 
    static void setup() {
    }
    
    static testmethod void testrunApex() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 

        Test.startTest();        
        CpmAddGithubComponentController.runApex(ApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 

        Demo_Component__C demoComponent = [SELECT Id, Title__c FROM Demo_Component__c where Github_Repository_URL__c =:ApiCalloutMock.RTA_GITHUB_REPO_URL LIMIT 1];
        
        System.assertEquals('richTextInputFSC', demoComponent.Title__c);
    }
}