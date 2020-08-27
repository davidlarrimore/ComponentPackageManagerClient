public class QueueComponentUpdateCheck implements Queueable {
    String componentId = null;

    public QueueComponentUpdateCheck(String componentId) {
        this.componentId = componentId;
    }

    public void execute(QueueableContext context) {
        System.debug('Start QueueComponentUpdateCheck.execute');
        Boolean updateFlag = false;
        List<Demo_Component__c> demoComponent = [SELECT Id, Description__c, Latest_Commit_DateTime__c, Installation_Type__c, Package_Installed_Version_Number__c, Source_Installed_Commit_Hash__c, Source_Installed_Commit_DateTime__c, SFDX_Installed_Package_Alias__c, Package_Install_Type_Flag__c, Latest_SFDX_Package_Alias__c, Latest_Tag_Commit_Hash__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, Package_Installed_Subscriber_Version_Id__c, Installed__c  FROM Demo_Component__c WHERE Id = :componentId LIMIT 1];
        if(demoComponent.size() > 0){
            system.debug('Found Demo Component');
            if(demoComponent[0].Installed__c){
                system.debug('It is installed');
                system.debug('Component Install Type is' + demoComponent[0].Installation_Type__c);
                system.debug('Component Version Tracking Method' + demoComponent[0].Installed_Version_Tracking_Method__c);

                if(demoComponent[0].Installed_Version_Tracking_Method__c == 'SFDX Project'){
                    if(demoComponent[0].Installation_Type__c == 'Package'){
                        if(demoComponent[0].Package_Installed_Subscriber_Version_Id__c != demoComponent[0].Latest_Subscriber_Package_Version_Id__c){
                            system.debug('Component Latest Subscriber Package Version ID of ' + demoComponent[0].Latest_Subscriber_Package_Version_Id__c + ' Is not the same as the installed version of ' + demoComponent[0].Package_Installed_Subscriber_Version_Id__c);
                            updateFlag = true;
                        }
                    }else if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Source' && demoComponent[0].Source_Installed_Tag_Hash__c != ''){
                        if(demoComponent[0].Source_Installed_Tag_DateTime__c < demoComponent[0].Latest_Tag_Commit_DateTime__c){
                            system.debug('Component Source Tag Installed date of ' + demoComponent[0].Source_Installed_Tag_DateTime__c + ' Is less than the latest tag commit date ' + demoComponent[0].Latest_Tag_Commit_DateTime__c);
                            updateFlag = true;
                        }
                    }else if(demoComponent[0].Installed_Version_Tracking_Method__c == 'Source' && demoComponent[0].Source_Installed_Commit_Hash__c != ''){ 
                        if(demoComponent[0].Source_Installed_Commit_DateTime__c < demoComponent[0].Latest_Commit_DateTime__c){
                            system.debug('Component Source Tag Installed date of ' + demoComponent[0].Source_Installed_Tag_DateTime__c + ' Is less than the latest tag commit date ' + demoComponent[0].Latest_Tag_Commit_DateTime__c);
                            updateFlag = true;
                        }                     
                    }
                }
            }           
        }

        if(updateFlag){
            demoComponent[0].Update_Available__c = true;
            update demoComponent;
        }        
    }
}
