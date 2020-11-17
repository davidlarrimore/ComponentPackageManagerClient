/*
 *Name: CpmVersionHelper
 *Description: Manages data gathering to support Unlocked Package version and upgrade functions
 *hosted.scratch.herokuapp.com/byoo?template=GithubURL
 *Contact: dlarrimore@salesforce.com
 *
 * 
 */


public with sharing class CpmVersionHelper {

    //Checks for sfdx-project.json if it has it, that means its an SFDX project
    //If it can't find sfdx-project.json, it looks for /src/project.xml this means its a legacy aura project

    public static void AddGithubComponent(String githubUrl, Map<String,String> options){
        String jobId = CpmAsyncEventHelper.generateId();

        System.debug('CpmVersionHelper.AddGithubComponent.runApex');  
        System.debug('Processing ' + githubUrl);

        Map<String,String> jobInfo = new Map<String,String>{
            CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Add Demo Component from Github Repository', 
            CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmVersionHelper.class.getName(),
            CpmAsyncEventHelper.FIELD_JOB_ID => jobId,
            CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => CpmAsyncEventHelper.STAGE_PROCESSING
        };
        CpmAsyncEventHelper.publishPlatformEvent(jobInfo);

        System.debug('Seeing if Package already exists');
        List<Cpm_Component_Package__c> existingPackageLookup = [SELECT Id, Source_Install_Type_Flag__c, Latest_Subscriber_Package_Version_Id__c, Package_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Cpm_Component_Package__c WHERE Github_Repository_URL__c = :githubUrl LIMIT 1];
        if(existingPackageLookup.size() == 0){

            System.debug('Nope....Inserting New Package');
            Cpm_Component_Package__c demoComponent = new Cpm_Component_Package__c();
            demoComponent.Github_Repository_URL__c = githubUrl;

            String tempName = githubUrl.substring(githubUrl.lastIndexOf('/')+1, githubUrl.length());
            tempName = tempName.replace('_', ' ');
            tempName = tempName.replace('-', ' ');
            demoComponent.Title__c = tempName;
            demoComponent.Source_Install_Type_Flag__c = true;


            //XTAG file was included, meaning it was installed, Updating
            if(options.containsKey('xTagFile')){
                XTagFile xTagFile = (XTagFile)System.JSON.deserialize(options.get('xTagFile'), XTagFile.class);
                System.debug('Existing demo component ' + demoComponent.Title__c + ' Is a match to this XTag File');
                demoComponent.Installed__c = true;
                demoComponent.Install_Date__c = xTagFile.installDateTime;
                demoComponent.Installation_Type__c = 'Source';
                demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';   
                demoComponent.Source_Installed_Commit_Hash__c = xTagFile.commitHash;
                
            }                              
 
            demoComponent.Last_Fetched__c = datetime.now();

            insert demoComponent;   

            if(options.containsKey('xTagFile')){
              XTagFile xTagFile = (XTagFile)System.JSON.deserialize(options.get('xTagFile'), XTagFile.class);
              CpmQUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new CpmQUpdateInstalledSourceCommitInfo(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
              System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob);   
            }

            CpmQUpdateFromSFDX CpmQUpdateFromSFDXJob = new CpmQUpdateFromSFDX(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id); 
            System.enqueueJob(CpmQUpdateFromSFDXJob);
            
            CpmQUpdateSourceCommitInfo CpmQUpdateSourceCommitInfoJob = new CpmQUpdateSourceCommitInfo(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id);   
            System.enqueueJob(CpmQUpdateSourceCommitInfoJob);

            CpmQUpdateSourceTagInfo CpmQUpdateSourceTagInfoJob = new CpmQUpdateSourceTagInfo(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id);    
            System.enqueueJob(CpmQUpdateSourceTagInfoJob);
            
            CpmQUpdateFromGithubRepo CpmQUpdateFromGithubRepoJob = new CpmQUpdateFromGithubRepo(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id); 
            System.enqueueJob(CpmQUpdateFromGithubRepoJob);
            
            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Added new Demo Component "' + demoComponent.Title__c + '". performing Post Processing!',
              CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_SUCCESS
            });                

            CpmComponentPackageUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
              CpmComponentPackageUpdateEventHelper.FIELD_UPDATE_FLAG => CpmComponentPackageUpdateEventHelper.FLAG_TRUE,
              CpmComponentPackageUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
            });               
        }else{
            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
              CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
              CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component already exists',
              CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_INFO});               
        }

    }


    public static void RefreshComponent(String demoComponentId){
        System.debug('Running CpmVersionHelper.RefreshComponent');

        String jobId = CpmAsyncEventHelper.generateId();

        Map<String,String> jobInfo = new Map<String,String>{
            CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Refresh Demo Component Info', 
            CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmVersionHelper.class.getName(),
            CpmAsyncEventHelper.FIELD_JOB_ID => jobId,
            CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => CpmAsyncEventHelper.STAGE_PROCESSING
        };
        
        CpmAsyncEventHelper.publishPlatformEvent(jobInfo);


        //FIRST THING WE DO IS CHECK TO SEE IF PACKAGES WERE ALREADY INSTALLED
        CpmQGetInstalledPackages queueGetInstalledPackagesJob = new CpmQGetInstalledPackages(jobId);
        List<AsyncApexJob> existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :queueGetInstalledPackagesJob.getJobInfo(CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME) LIMIT 1];
        if (existingJobs.size() == 0){
            System.debug('Running queueGetInstalledPackagesJob');
            System.enqueueJob(queueGetInstalledPackagesJob);
        }

        CpmVersionHelper.getinstalledXTAGs(jobId);


        List<Cpm_Component_Package__c> demoComponentSearch = [SELECT Id, Github_Repository_URL__c, Source_Install_Type_Flag__c, SFDX_Package_Enabled_Flag__c FROM Cpm_Component_Package__c WHERE Id = :demoComponentId LIMIT 1];
        if(demoComponentSearch.size() > 0){
            Cpm_Component_Package__c demoComponent = demoComponentSearch[0];

            CpmQUpdateFromSFDX CpmQUpdateFromSFDXJob = new CpmQUpdateFromSFDX(jobId, demoComponentId); 
            existingJobs = [SELECT Id, ApexClass.Name, Status FROM AsyncApexJob WHERE Status IN ('Holding','Queued','Preparing','Processing') AND ApexClass.Name = :CpmQUpdateFromSFDXJob.getJobInfo('Apex_Class_Name__c') LIMIT 1];
            if (existingJobs.size() == 0){
                System.enqueueJob(CpmQUpdateFromSFDXJob);
            }


            if(demoComponent.Source_Install_Type_Flag__c){
                CpmQUpdateSourceCommitInfo CpmQUpdateSourceCommitInfoJob = new CpmQUpdateSourceCommitInfo(jobId, demoComponentId);   
                System.enqueueJob(CpmQUpdateSourceCommitInfoJob);
                
                CpmQUpdateSourceTagInfo CpmQUpdateSourceTagInfoJob = new CpmQUpdateSourceTagInfo(jobId, demoComponentId); 
                System.enqueueJob(CpmQUpdateSourceTagInfoJob);

                CpmQUpdateFromGithubRepo CpmQUpdateFromGithubRepoJob = new CpmQUpdateFromGithubRepo(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID),demoComponent.Id); 
                System.enqueueJob(CpmQUpdateFromGithubRepoJob);            
            }
            demoComponent.Last_Fetched__c = datetime.now();
            update demoComponent;
        }
        jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
        CpmAsyncEventHelper.publishPlatformEvent(jobInfo);    
    }    
    

    public static void getinstalledXTAGs(String parentJobId){
        String jobId = CpmAsyncEventHelper.generateId();

        Map<String,String> jobInfo = new Map<String,String>{
            CpmAsyncEventHelper.FIELD_JOB_NAME =>  'Checking for installed Source Packages', 
            CpmAsyncEventHelper.FIELD_APEX_CLASS_NAME => CpmVersionHelper.class.getName(),
            CpmAsyncEventHelper.FIELD_JOB_ID => jobId,
            CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE => CpmAsyncEventHelper.STAGE_PROCESSING
        };

        if(String.isBlank(parentJobId)
        ){
            jobInfo.put(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID, parentJobId);
        }
        CpmAsyncEventHelper.publishPlatformEvent(jobInfo);
        List<StaticResource> staticResources = new List<StaticResource>();
        try {
            //Added to allow for Testing
            if(Test.isRunningTest()){
                staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testTagFile%'];
            }else{
                staticResources = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'XTAG%'];
            }

            List<XTagFile> xTagFiles = new List<XTagFile>();

            if(staticResources.size() > 0){
                System.debug('Found' + staticResources.size() + ' static_resources');
                for (StaticResource staticResource: staticResources){
                    XTagFile xTagFile = (XTagFile)System.JSON.deserialize(staticResource.Body.toString(), XTagFile.class);
                    System.debug('Found Static Resource ID: ' + staticResource.Id + ', with name: '+ xTagFile.name); 
                    xTagFiles.add(xTagFile);
                }

                for (XTagFile xTagFile: xTagFiles){
                    CpmVersionHelper.processXTag(jobInfo, JSON.serialize(xTagFile)); 
                }
            }

            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo);    
            
        }catch (Exception e) {
            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_FAILED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Completion Notification',
            CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
            CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_ERROR});                
        }  
    }

    
    @TestVisible 
    private static void processXTag(Map<String, String> jobInfo, String xTagJSON){
       try {

            XTagFile xTagFile = (XTagFile)System.JSON.deserialize(xTagJSON, XTagFile.class);
            Boolean hasParentJob = false;

            if(jobInfo.containsKey(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID)){
                hasParentJob = true;
            }

            List<Cpm_Component_Package__c> demoComponentSearch = [SELECT Id, Name, Github_Repository_URL__c, Title__c, Update_Available__c, Install_Date__c, Installed__c, Source_Installed_Commit_Hash__c, Source_Installed_Tag_Hash__c FROM Cpm_Component_Package__c WHERE Github_Repository_URL__c = :xTagFile.githubRepositoryUrl LIMIT 1];       
            if(demoComponentSearch.size() > 0){
                Cpm_Component_Package__c demoComponent = demoComponentSearch[0];
                xTagFile.demoComponentAlreadyExistsFlag = false;

                System.debug('Existing demo component ' + demoComponent.Title__c + ' Is a match to this XTag File');
                //Component was not installed, and now is....
                if(!demoComponent.Installed__c){
                    System.debug('Marking Demo Component as Installed');
                    demoComponent.Installed__c = true;
                    demoComponent.Install_Date__c = xTagFile.installDateTime;
                    demoComponent.Installation_Type__c = 'Source';
                    demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';  
                    demoComponent.Update_Available__c = false;
                    demoComponent.Source_Installed_Commit_Hash__c = xTagFile.commitHash;

                    update demoComponent;  

                    CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                      CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                      CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Demo Component ' + demoComponent.Title__c + ' was installed. Updating',
                      CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_SUCCESS
                    });  

                    CpmComponentPackageUpdateEventHelper.publishPlatformEvent(new Map<String,String>{
                      CpmComponentPackageUpdateEventHelper.FIELD_UPDATE_FLAG => CpmComponentPackageUpdateEventHelper.FLAG_TRUE,
                      CpmComponentPackageUpdateEventHelper.FIELD_DEMO_COMPONENT_ID => demoComponent.Id
                    });
                        
                    CpmQUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new CpmQUpdateInstalledSourceCommitInfo(hasParentJob ? jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID) : jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                //Newer version was installed
                }else if (demoComponent.Installed__c && xTagFile.installDateTime > demoComponent.Install_Date__c){
                    System.debug('Component already installed and was probably updated. Component Install Date: ' + demoComponent.Install_Date__c + ', XTag InstallDate: ' + xTagFile.installDateTime);
                    demoComponent.Install_Date__c = xTagFile.installDateTime;
                    demoComponent.Installation_Type__c = 'Source';
                    demoComponent.Installed_Version_Tracking_Method__c = 'Github_Commit';   
                    demoComponent.Update_Available__c = false;
                    demoComponent.Source_Installed_Commit_Hash__c = xTagFile.commitHash;

                    update demoComponent;  

                    CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                      CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                      CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'It looks like Demo Component ' + demoComponent.Title__c + ' was updated! Congratulations.',
                      CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_SUCCESS
                    });  

                    CpmQUpdateInstalledSourceCommitInfo queueUpdateInstalledSourceCommitInfoJob = new CpmQUpdateInstalledSourceCommitInfo(hasParentJob ? jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_PARENT_ID) : jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_ID), demoComponent.Id, xTagFile.commitHash); 
                    System.enqueueJob(queueUpdateInstalledSourceCommitInfoJob); 

                }else{
                    System.debug('XTag matches existing info, doing nothing');
                }

            }else{

                System.debug('Repository ' + xTagFile.githubRepositoryUrl + ' Does not match an existing component, creating a new one');

                CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
                    CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Update Notification',
                    CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => 'Found newly installed component!',
                    CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_SUCCESS});  

                CpmVersionHelper.AddGithubComponent(xTagFile.githubRepositoryUrl, new map<String,String>{'xTagFile'=>xTagJSON});
            }

            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_COMPLETED);
            CpmAsyncEventHelper.publishPlatformEvent(jobInfo);    

        }catch (Exception e) {
            System.debug(jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage());   

            jobInfo.put(CpmAsyncEventHelper.FIELD_CURRENT_JOB_STAGE, CpmAsyncEventHelper.STAGE_FAILED);

            CpmAsyncEventHelper.publishPlatformEvent(jobInfo,new Map<String,String>{
            CpmAsyncEventHelper.FIELD_EVENT_STATUS_TITLE => 'Job Failed Notification',
            CpmAsyncEventHelper.FIELD_EVENT_STATUS_MESSAGE => jobInfo.get(CpmAsyncEventHelper.FIELD_JOB_NAME) + ' Error: ' + e.getMessage(),
            CpmAsyncEventHelper.FIELD_EVENT_LEVEL => CpmAsyncEventHelper.EVENT_LEVEL_ERROR});                
        }  
    }


    public static String getVersionNumberFromAlias(String alias){     
        return alias.substring(alias.indexOf('@')+1, alias.length());
    }    


    public static Integer getVersionNumberFromText(String versionNumberAsText){     
        System.debug('Running CpmVersionHelper.getVersionNumberFromText');
        System.debug('Processing: ' + versionNumberAsText);
        String newString = versionNumberAsText;
        String versionPart=  '';

        Integer majorVersion = 0;
        Integer minorVersion = 0;
        Integer patchVersion = 0;
        Integer buildNumber = 0;

        versionPart = newString.substring(0,newString.indexOf('.'));
        newString = newString.substring(versionPart.length()+1,newString.length());
        majorVersion = Integer.valueOf(versionPart + '000000');

        versionPart = newString.substring(0,newString.indexOf('.'));
        newString = newString.substring(versionPart.length()+1,newString.length());
        minorVersion = Integer.valueOf(versionPart + '0000');

        versionPart = newString.substring(0,newString.indexOf('-'));
        newString = newString.substring(versionPart.length()+1,newString.length());
        patchVersion = Integer.valueOf(versionPart + '00');
        buildNumber = Integer.valueOf(newString);
        
        Integer intval = majorVersion + minorVersion + patchVersion + buildNumber;

        System.debug('Returning: ' + intval);
        return intval;
    }    

}