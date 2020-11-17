public with sharing class CpmComponentController {

    @AuraEnabled(cacheable=true)
    public static list<Cpm_Component_Package__c> getDemoComponents(){
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
                  FROM Cpm_Component_Package__c
                ];
    }    




    @AuraEnabled(cacheable=true)
    public static list<Cpm_Component_Package__c> getInstalledComponents(String searchString){
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
                       Installed_Version__c,
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
                  FROM Cpm_Component_Package__c 
                 WHERE Installed__c = true
                 ORDER BY Title__c ASC];
        }

        
        List<List<sObject>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Cpm_Component_Package__c(
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
        Cpm_Component_Package__c[] searchDemoComponents = (Cpm_Component_Package__c[])searchList[0];

        List<Cpm_Component_Package__c> returnList = new List<Cpm_Component_Package__c>{};
        for (Cpm_Component_Package__c a : searchDemoComponents) {
            if(a.Installed__c){
                returnList.add(a);
            }
        }

        return returnList;
    }    


    @AuraEnabled(cacheable=true)
    public static list<Cpm_Component_Package__c> getAvailableComponents(String searchString){
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
                  FROM Cpm_Component_Package__c 
                 WHERE Installed__c = false
                   AND Latest_Package_Version_Deprecated_Flag__c = false
                 ORDER BY Title__c ASC];
        }

        
        List<List<sObject>> searchList = [FIND :searchString IN ALL FIELDS RETURNING Cpm_Component_Package__c(
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
        Cpm_Component_Package__c[] searchDemoComponents = (Cpm_Component_Package__c[])searchList[0];

        List<Cpm_Component_Package__c> returnList = new List<Cpm_Component_Package__c>{};
        for (Cpm_Component_Package__c a : searchDemoComponents) {
            if(!a.Installed__c && !a.Latest_Package_Version_Deprecated_Flag__c){
                returnList.add(a);
            }
        }

        return returnList;
    }    

}