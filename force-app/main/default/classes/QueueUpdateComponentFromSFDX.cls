public class QueueUpdateComponentFromSFDX implements Queueable, Database.AllowsCallouts  {
    Id demoComponentId = null;
        
    public QueueUpdateComponentFromSFDX(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }

    public void execute(QueueableContext context) {

        System.debug('Running QueueUpdateComponentFromSFDX.execute');  
        List<Demo_Component__c> demoComponent = [SELECT Id, Github_Repository_URL__c, Latest_Subscriber_Package_Version_Id__c, Installed_Version_Tracking_Method__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponent.size() > 0){
            System.debug('Processing ' + demoComponent[0].Github_Repository_URL__c);   
            Boolean triggerPackageUpdate = false;
            GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(demoComponent[0].Github_Repository_URL__c);
            if(githubSFDXProjectDotJSON != null){
                if(githubSFDXProjectDotJSON.packageDirectories != null && githubSFDXProjectDotJSON.packageDirectories.size() > 0){
                    for(GithubPackageDirectory thisPackageDirectory: (List<GithubPackageDirectory>) githubSFDXProjectDotJSON.packageDirectories){
                        if(thisPackageDirectory.defaultDirectory == true){
                            System.debug('Found the default package directory, this is an SFDX Enabled Project!');
    
                            demoComponent[0].Package_Install_Type_Flag__c = true;
                            demoComponent[0].SFDX_Package_Enabled_Flag__c = true;
                            demoComponent[0].SFDX_Package_Name__c = thisPackageDirectory.packageName;
                            demoComponent[0].Latest_SFDX_Package_Version_Name__c = thisPackageDirectory.versionName;
                            demoComponent[0].Latest_SFDX_Package_Version_Description__c = thisPackageDirectory.versionDescription;
    
                            //Processing Dependencies
                            if(thisPackageDirectory.dependencies != null && thisPackageDirectory.dependencies.size() > 0){
                                List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();
                                for(Map<String,String> thisDependency: (List<map<string,string>>) thisPackageDirectory.dependencies){
                                    if(thisDependency.containsKey('packageName')){
                                        dependentPackageSubscriberPackageVersionIds.add((String)thisDependency.get('packageName'));
                                    }
                                }
                                System.debug('Found some dependent Packages in SFDX-Project.json, will address later: ' + dependentPackageSubscriberPackageVersionIds);
                            }
                        }else{
                            System.debug('This is not the default package directory, skipping');
                        }
                    }
    
                    if(demoComponent[0].Latest_Subscriber_Package_Version_Id__c != githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()){
                        System.debug('Package Versions are different, QueueUpdateComponentFromPackageVersion');
                        demoComponent[0].Latest_SFDX_Package_Alias__c = githubSFDXProjectDotJSON.getLatestVersionAlias();
                        demoComponent[0].Latest_Subscriber_Package_Version_Id__c = githubSFDXProjectDotJSON.getLatestVersionPackageVersionId();
                        triggerPackageUpdate = true;

                        if(demoComponent[0].Installed__c){
                            System.debug('Checking to see if update is available');
                            if(demoComponent[0].Installed_Version_Tracking_Method__c == 'SFDX Project' ){
                                System.debug('Update Available');
                                demoComponent[0].Update_Available__c = true;
                            }
                        }

                    }
                }

                update demoComponent[0];

                if(triggerPackageUpdate){
                    QueueUpdateComponentFromPackageVersion queueUpdateComponentFromPackageVersionJob = new QueueUpdateComponentFromPackageVersion(new List<String>{githubSFDXProjectDotJSON.getLatestVersionPackageVersionId()}, new Map<String,String>()); 
                    ID JobID = System.enqueueJob(queueUpdateComponentFromPackageVersionJob);    
                }

            }else{
                System.debug('sfdx-project.json not found');  
            }
        }else{
            System.debug('Could not find Component ' + demoComponentId);   
        }
    }

}    
