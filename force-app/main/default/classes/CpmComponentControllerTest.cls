@isTest
public with sharing class CpmComponentControllerTest {
    public static final DateTime CURRENT_COMMIT_DATETIME = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class);
    public static final DateTime PREVIOUS_COMMIT_DATETIME = (DateTime)Json.deserialize('2019-08-27T19:26:30.000Z', DateTime.class);

    @testSetup 
    static void setup() {
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>();

        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.VM_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Installed__c = false,
            Title__c = 'Visitor Management Demo Scenario',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.VM_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Latest_Package_Version_Deprecated_Flag__c = false
        ));       

        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.RTA_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=false,
            Title__c = 'richTextInputFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = ApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH, //Old Commit
            Latest_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Installed__c = true,
            Update_Available__c = false,
            Source_installed_Commit_DateTime__c = CURRENT_COMMIT_DATETIME,
            Source_Installed_Commit_Hash__c = ApiCalloutMock.RTA_GITHUB_PREVIOUS_COMMIT_HASH,
            Latest_Package_Version_Deprecated_Flag__c = false    
        ));

        insert demoComponents;
    }
    
    static testmethod void testGetDemoComponents() {
        List<Demo_Component__C> demoComponents = CpmComponentController.getDemoComponents();
        System.assertEquals(2, demoComponents.size());
    }

    static testmethod void testGetInstalledComponents() {
        List<Demo_Component__C> demoComponents = CpmComponentController.getInstalledComponents(null);
        System.assertEquals(1, demoComponents.size());
        System.assertEquals('richTextInputFSC', demoComponents[0].Title__c);
    }

    static testmethod void testGetAvailableComponents() {
        List<Demo_Component__C> demoComponents = CpmComponentController.getAvailableComponents(null);
        System.assertEquals(1, demoComponents.size());
        System.assertEquals('Visitor Management Demo Scenario', demoComponents[0].Title__c);
    }    

    static testmethod void testGetInstalledComponentsSearch() {
        Demo_Component__c demoComponent = [SELECT Id FROM Demo_Component__c WHERE Title__c = 'richTextInputFSC'];

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = demoComponent.Id;
        Test.setFixedSearchResults(new List<Id>(fixedSearchResults));

        List<Demo_Component__C> demoComponents = CpmComponentController.getInstalledComponents('richTextInputFSC');
        System.assertEquals(1, demoComponents.size());
        System.assertEquals('richTextInputFSC', demoComponents[0].Title__c);
    }

    static testmethod void testGetAvailableComponentsSearch() {
        Demo_Component__c demoComponent = [SELECT Id FROM Demo_Component__c WHERE Title__c = 'Visitor Management Demo Scenario'];

        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = demoComponent.Id;
        Test.setFixedSearchResults(new List<Id>(fixedSearchResults));

        List<Demo_Component__C> demoComponents = CpmComponentController.getAvailableComponents('Visitor');
        System.assertEquals(1, demoComponents.size());
        System.assertEquals('Visitor Management Demo Scenario', demoComponents[0].Title__c);
    }    

}