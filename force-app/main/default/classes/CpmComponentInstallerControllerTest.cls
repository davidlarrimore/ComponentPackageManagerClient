@isTest
public with sharing class CpmComponentInstallerControllerTest {
    @testSetup 
    static void setup() {
        List<Cpm_Component_Package__c> demoComponents = new List<Cpm_Component_Package__c>();

        Cpm_Component_Package__c parentComponent =  new Cpm_Component_Package__c(
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
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );

        Cpm_Component_Package__c dependentComponent1 =  new Cpm_Component_Package__c(
            SFDX_Package_Enabled_Flag__c=false,
            Source_Install_Type_Flag__c=false,
            Package_Install_Type_Flag__c=true,
            Title__c = 'horizontalRule',
            Package_Name__c = 'horizontalRule',
            Latest_Package_Version_Name__c = 'AllPages',
            Latest_Package_Version__c = '0.1.1-1',
            Subscriber_Package_Id__c = '0331K000000oduuQAA',
            Latest_Subscriber_Package_Version_Id__c = '04t1K000002J0KKQA0',
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false
        );

        Cpm_Component_Package__c dependentComponent2 =  new Cpm_Component_Package__c(
            SFDX_Package_Enabled_Flag__c=false,
            Source_Install_Type_Flag__c=false,
            Package_Install_Type_Flag__c=true,
            Title__c = 'DynamicHeaderFooter',
            Package_Name__c = 'DynamicHeaderFooter',
            Latest_Package_Version_Name__c = 'Spring 2020',
            Latest_Package_Version__c = '2.61.0-1',
            Subscriber_Package_Id__c = '0331t000000c4w5AAA',
            Latest_Subscriber_Package_Version_Id__c = '04t1t0000034vZjAAI',
            Last_Fetched__c = datetime.now(),
            Update_Available__c = false,
            Installed__c = true,
            Installed_Version_Tracking_Method__c = 'None',
            Package_Installed_Version_Number__c = '2.61.0-1', 
            Package_Installed_Subscriber_Version_Id__c = '04t1t0000034vZjAAI'            
        );  

        demoComponents.add(parentComponent);
        demoComponents.add(dependentComponent1);
        demoComponents.add(dependentComponent2);
        insert demoComponents;

        List<Cpm_Component_Package_Dependency__c> componentDependencies = new List<Cpm_Component_Package_Dependency__c>();

        Cpm_Component_Package_Dependency__c componentDependency1 =  new Cpm_Component_Package_Dependency__c(
            Cpm_Component_Package__c = parentComponent.Id,
            Dependent_Component_Package__c = dependentComponent1.Id
        );  
        componentDependencies.add(componentDependency1);

        Cpm_Component_Package_Dependency__c componentDependency2 =  new Cpm_Component_Package_Dependency__c(
            Cpm_Component_Package__c = parentComponent.Id,
            Dependent_Component_Package__c = dependentComponent2.Id
        ); 
        componentDependencies.add(componentDependency2);

        insert componentDependencies;
    }
    
    static testmethod void testrunApex() {

        Cpm_Component_Package__c updatedDemoComponent = [SELECT Id FROM Cpm_Component_Package__c where Subscriber_Package_Id__c =:CpmApiCalloutMock.SUBSCRIBER_PACKAGE_ID LIMIT 1];
        
        Test.startTest();        
        list<Cpm_Component_Package__c> dependentComponents = CpmComponentInstallerController.getDependentPackages(updatedDemoComponent.Id);
        Test.stopTest(); 

        System.assertEquals(2, dependentComponents.size()); 
    }
}