public with sharing class CpmComponentController {

    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getDemoComponents(){
        return [SELECT Id, 
                       Title__c, 
                       Name, 
                       Description__c, 
                       Dependencies_Met__c,
                       Package_Name__c, 
                       Installation_Type__c, 
                       Install_Date__c, 
                       Update_Available__c, 
                       Installed__c, 
                       POC_Email__c, 
                       POC_Name__c, 
                       Github_Repository_URL__c, 
                       Installed_Version__c, 
                       Source_Install_Type_Flag__c, 
                       Source_Install_Url__c, 
                       Package_Install_Type_Flag__c, 
                       Package_Install_Url__c, 
                       Latest_Package_Version_Deprecated_Flag__c, 
                       SFDX_Package_Enabled_Flag__c,
                       Last_Modified_Date__c,
                       New_Component_Flag__c,
                       Date_Added__c,
                       Recently_Updated_Flag__c 
                  FROM Demo_Component__c
                ];
    }    




    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getInstalledComponents(String searchString){
        if(searchString == null || searchString == '' || searchString.length() < 2){
            return [SELECT Id, 
                       Title__c, 
                       Name, 
                       Description__c, 
                       Dependencies_Met__c,
                       Package_Name__c, 
                       Installation_Type__c,  
                       Install_Date__c, 
                       Update_Available__c, 
                       Installed__c, 
                       POC_Email__c, 
                       POC_Name__c, 
                       Github_Repository_URL__c, 
                       Source_Install_Type_Flag__c, 
                       Source_Install_Url__c, 
                       Package_Install_Type_Flag__c, 
                       Package_Install_Url__c, 
                       Latest_Package_Version_Deprecated_Flag__c, 
                       SFDX_Package_Enabled_Flag__c,
                       Last_Modified_Date__c,
                       New_Component_Flag__c,
                       Recently_Updated_Flag__c,
                       Date_Added__c  
                  FROM Demo_Component__c 
                 WHERE Installed__c = true
                 ORDER BY Title__c ASC];
        }

        
        List<List<sObject>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Demo_Component__c(
            Id, 
            Title__c, 
            Name, 
            Description__c, 
            Dependencies_Met__c,
            Package_Name__c, 
            Installation_Type__c, 
            Install_Date__c, 
            Update_Available__c, 
            Installed__c, 
            POC_Email__c, 
            POC_Name__c, 
            Github_Repository_URL__c, 
            Installed_Version__c, 
            Source_Install_Type_Flag__c, 
            Source_Install_Url__c, 
            Package_Install_Type_Flag__c, 
            Package_Install_Url__c, 
            Latest_Package_Version_Deprecated_Flag__c, 
            SFDX_Package_Enabled_Flag__c,
            Last_Modified_Date__c,
            New_Component_Flag__c,
            Recently_Updated_Flag__c,
            Date_Added__c )
        ];
        Demo_Component__c[] searchDemoComponents = (Demo_Component__c[])searchList[0];

        List<Demo_Component__c> returnList = new List<Demo_Component__c>{};
        for (Demo_Component__c a : searchDemoComponents) {
            if(a.Installed__c){
                returnList.add(a);
            }
        }

        return returnList;
    }    


    @AuraEnabled(cacheable=true)
    public static list<Demo_Component__c> getAvailableComponents(String searchString){
        if(searchString == null || searchString == '' || searchString.length() < 2){
            return [SELECT Id, 
                       Title__c, 
                       Name, 
                       Description__c, 
                       Dependencies_Met__c,
                       Package_Name__c, 
                       Installation_Type__c,  
                       Install_Date__c, 
                       Update_Available__c, 
                       Installed__c, 
                       POC_Email__c, 
                       POC_Name__c, 
                       Github_Repository_URL__c, 
                       Source_Install_Type_Flag__c, 
                       Source_Install_Url__c, 
                       Package_Install_Type_Flag__c, 
                       Package_Install_Url__c, 
                       Latest_Package_Version_Deprecated_Flag__c, 
                       SFDX_Package_Enabled_Flag__c,
                       Last_Modified_Date__c,
                       New_Component_Flag__c,
                       Recently_Updated_Flag__c,
                       Date_Added__c  
                  FROM Demo_Component__c 
                 WHERE Installed__c = false
                 ORDER BY Title__c ASC];
        }

        
        List<List<sObject>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Demo_Component__c(
            Id, 
            Title__c, 
            Name, 
            Description__c, 
            Dependencies_Met__c,
            Package_Name__c, 
            Installation_Type__c, 
            Install_Date__c, 
            Update_Available__c, 
            Installed__c, 
            POC_Email__c, 
            POC_Name__c, 
            Github_Repository_URL__c, 
            Installed_Version__c, 
            Source_Install_Type_Flag__c, 
            Source_Install_Url__c, 
            Package_Install_Type_Flag__c, 
            Package_Install_Url__c, 
            Date_Added__c,
            Latest_Package_Version_Deprecated_Flag__c, 
            SFDX_Package_Enabled_Flag__c,
            Last_Modified_Date__c,
            New_Component_Flag__c,
            Recently_Updated_Flag__c )
        ];
        Demo_Component__c[] searchDemoComponents = (Demo_Component__c[])searchList[0];

        List<Demo_Component__c> returnList = new List<Demo_Component__c>{};
        for (Demo_Component__c a : searchDemoComponents) {
            if(!a.Installed__c){
                returnList.add(a);
            }
        }

        return returnList;
    }    

}