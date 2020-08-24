/*
 *Name: VersionHelper
 *Description: Manages data gathering to support Unlocked Package version and upgrade functions
 *hosted.scratch.herokuapp.com/byoo?template=GithubURL
 *Contact: dlarrimore@salesforce.com
 *
 * 
 */


public with sharing class VersionHelper {

    //Checks for sfdx-project.json if it has it, that means its an SFDX project
    //If it can't find sfdx-project.json, it looks for /src/project.xml this means its a legacy aura project

    public static Demo_Component__c getComponentFromGithubURL(String githubUrl){

        System.debug('Processing ' + githubUrl);
        List<String> versions = new List<String>();
        
        Boolean demoConfigFileFlag = false;
        Boolean subRepoFlag = githubUrl.contains('master') ? true : false;


        Demo_Component__c gpbuPackage = new Demo_Component__c();

        //@TODO: add the ability to find the package.xml in a child directory

        List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();

        gpbuPackage.Github_Repository_URL__c = githubUrl;
        gpbuPackage.Description__c = '';
        gpbuPackage.Last_Fetched__c = Datetime.Now();

        //Preset Options. We assume we can at least do a Source install from a valid github repo
        gpbuPackage.Source_Install_Type_Flag__c = true;
        gpbuPackage.SFDX_Package_Enabled_Flag__c = false; 
        gpbuPackage.Package_Install_Type_Flag__c = false;

        System.debug('Attempting to grab component-config.json from: ' + githubUrl);
        GithubAPIHelper.ComponentConfigDotJSON componentConfig = GithubAPIHelper.getGithubComponentConfigDotJSON(githubUrl);
        
        if(componentConfig != null){
            demoConfigFileFlag = true;
            gpbuPackage.SFDX_Package_Enabled_Flag__c = true;

            gpbuPackage.Title__c = componentConfig.name;
            gpbuPackage.Description__c = componentConfig.description != null ? componentConfig.description : '';
            gpbuPackage.POC_Name__c = componentConfig.author != null ? componentConfig.author : '';
            gpbuPackage.POC_Email__c = componentConfig.authorEmail != null  ? componentConfig.authorEmail : '';
            gpbuPackage.Admin_Permission_Set__c = componentConfig.permissionSet != null ? componentConfig.permissionSet  : '';
            gpbuPackage.SFDX_Package_Name__c = componentConfig.name;

            //Processing Dependencies
            if(componentConfig.dependencies != null){
                for(Map<String,String> thisDependency: (List<map<string,string>>) componentConfig.dependencies){
                    if(thisDependency.containsKey('packageName')){
                        dependentPackageSubscriberPackageVersionIds.add((String)thisDependency.get('packageName'));
                    }
                }
                 System.debug('Found some dependent Packages in component-config.json, will address later: ' + dependentPackageSubscriberPackageVersionIds);
            }
            if(componentConfig.disableSourceInstall && componentConfig.disableSourceInstall == true){
                gpbuPackage.Source_Install_Type_Flag__c = false;                   
            }
        }



        System.debug('Attempting to grab sfdx-project.json from: ' + githubUrl);
        GithubAPIHelper.SFDXProjectDotJSON componentSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(githubUrl);
        if(componentSFDXProjectDotJSON != null){
            System.debug('found sfdx-project.json, processing...');

            if(!demoConfigFileFlag){
                gpbuPackage.Source_Install_Type_Flag__c = true; 
            }

            //Processing dependencies
            if(componentSFDXProjectDotJSON.packageAliases != null){
                System.debug('this is an SFDX deployed Project, processing');
                gpbuPackage.SFDX_Package_Enabled_Flag__c = true;
                for(GithubAPIHelper.PackageDirectory thisPackageDirectory: (List<GithubAPIHelper.PackageDirectory>) componentSFDXProjectDotJSON.packageDirectories){
                    if(thisPackageDirectory.defaultDirectory == true){
                        System.debug('Found the default package directory');
                        gpbuPackage.Package_Install_Type_Flag__c = true;

                        if(!demoConfigFileFlag){
                            gpbuPackage.Title__c = thisPackageDirectory.packageName;  
                        }

                        //Processing Dependencies
                        if(dependentPackageSubscriberPackageVersionIds.size() < 1 && thisPackageDirectory.dependencies != null && thisPackageDirectory.dependencies.size() > 0){
                            for(Map<String,String> thisDependency: (List<map<string,string>>) thisPackageDirectory.dependencies){
                                if(thisDependency.containsKey('packageName')){
                                    dependentPackageSubscriberPackageVersionIds.add((String)thisDependency.get('packageName'));
                                }
                            }
                            System.debug('Found some dependent Packages in SFDX-Project.json, will address later: ' + dependentPackageSubscriberPackageVersionIds);
                        }

                        gpbuPackage.SFDX_Package_Name__c = thisPackageDirectory.packageName;
                        gpbuPackage.Latest_SFDX_Package_Version_Name__c = thisPackageDirectory.versionName;
                        gpbuPackage.Latest_SFDX_Package_Version_Description__c = thisPackageDirectory.versionDescription;

                    }else{
                        System.debug('This is not the default package directory, skipping');
                    }
                }

                for (String packageAlias : componentSFDXProjectDotJSON.packageAliases.keySet()){
                    System.debug('Processing packageAlias ' + packageAlias + ' : ' + componentSFDXProjectDotJSON.packageAliases.get(packageAlias));
                    gpbuPackage.Latest_SFDX_Package_Alias__c = componentSFDXProjectDotJSON.packageAliases.get(packageAlias);
                    gpbuPackage.Latest_Subscriber_Package_Version_Id__c = componentSFDXProjectDotJSON.packageAliases.get(packageAlias);
                }
            }
        }  

        if(!gpbuPackage.SFDX_Package_Enabled_Flag__c){
            System.debug('Not a SFDX Based project, defaulting project name to Github Repo Name');
            String tempName = githubUrl.substring(githubUrl.lastIndexOf('/')+1, githubUrl.length());
            tempName = tempName.replace('_', ' ');
            tempName = tempName.replace('-', ' ');
            gpbuPackage.Title__c = tempName;
        }

        //TODO: Check for Package.XML (Low Priority)


        System.debug('Seeing if Package already exists');
        List<Demo_Component__c> existingPackageLookup = [SELECT Id from Demo_Component__c WHERE Github_Repository_URL__c  = :githubUrl LIMIT 1];
        if(existingPackageLookup.size() > 0){
            System.debug('Package already exists, adding Id and updating');
            gpbuPackage.Id = existingPackageLookup[0].Id;
        }else{
            System.debug('Nope....Inserting New Package: ' + gpbuPackage);
            //Insert gpbuPackage; 
        }
        upsert gpbuPackage;

        System.debug('Processing Dependent Packages');
        VersionHelper.processDependentPackages(dependentPackageSubscriberPackageVersionIds, gpbuPackage.Id);

        //Updating Package Info
        if(gpbuPackage.Package_Install_Type_Flag__c){
            System.debug('This is Package Install Enabled, using Tooling api to grab info');
            VersionHelper.updatePackageFromSubscriberPackageVersionId(gpbuPackage.Id);
        }

        //Updating Source Info
        if(gpbuPackage.Source_Install_Type_Flag__c && !subRepoFlag){
            System.debug('This is Source Install Enabled, using Github api to grab Commit/tag info');
            VersionHelper.updateComponentSourceCommitInfo(gpbuPackage.Id);
            VersionHelper.updateComponentSourceTagInfo(gpbuPackage.Id);
        }

        return gpbuPackage; 
    }

    public static void processDependentPackages(List<String> subscriberPackageVersionIds, Id gpbuPackageId){
        System.debug('Running processDependentPackages');
        for(String subscriberPackageVersionId: subscriberPackageVersionIds){
            System.debug('Looking up the following SubscriberPackageVersionId: ' + subscriberPackageVersionId);
            List<Demo_Component__c> existingPackageLookup = [SELECT Id, Latest_Subscriber_Package_Version_Id__c from Demo_Component__c WHERE Latest_Subscriber_Package_Version_Id__c = :subscriberPackageVersionId LIMIT 1];
            if(existingPackageLookup.size() > 0){
                System.debug('DependentPackage already exists');

                List<Component_Dependency__c> packageDependencyLookup = [SELECT Id, Demo_Component__c, Dependent_Component__c FROM Component_Dependency__c WHERE Demo_Component__c = :gpbuPackageId AND Dependent_Component__c = :existingPackageLookup[0].Id LIMIT 1];
                if(packageDependencyLookup.size() > 0){
                    System.debug('Package Dependency Record Already Exists, skipping');
                }else{
                    System.debug('Creating new Package Dependency Record');
                    Component_Dependency__c packageDependency = new Component_Dependency__c();
                    packageDependency.Demo_Component__c = gpbuPackageId;
                    packageDependency.Dependent_Component__c = existingPackageLookup[0].id;
                    insert packageDependency;
                }
            }else{
                System.debug('No existing package, adding new one #Future');
                VersionHelper.createPackageFromSubscriberPackageVersionId(subscriberPackageVersionId, gpbuPackageId);
            }
        }
    }
    
    @future(callout = true)
    public static void updateComponentSourceCommitInfo(Id gpbuPackageId){
        System.debug('Running updateComponentSourceCommitInfo');  
        List<Demo_Component__c> gpbuPackage = [SELECT Id, Github_Repository_URL__c, SFDX_Package_Enabled_Flag__c FROM Demo_Component__c WHERE Id = :gpbuPackageId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('Processing ' + gpbuPackage[0].Github_Repository_URL__c);   
            List<GithubAPIHelper.GithubCommit> githubCommits = GithubAPIHelper.getGithubCommits(gpbuPackage[0].Github_Repository_URL__c);

            if(githubCommits != null && githubCommits.size() > 0){
                for(GithubAPIHelper.GithubCommit thisCommit: githubCommits){
                    if (thisCommit.latestCommitFlag){
                        gpbuPackage[0].Latest_Commit_DateTime__c = thisCommit.commitInfo.committer.commitDate;
                        gpbuPackage[0].Latest_Commit_Description__c = thisCommit.commitInfo.message;
                        gpbuPackage[0].Latest_Commit_Hash__c = thisCommit.sha;

                        //If not an SFDX Based project, we assume POC information is not there, grabbing commit author info;
                        if (!gpbuPackage[0].SFDX_Package_Enabled_Flag__c){
                            GithubAPIHelper.GithubUser githubUser = GithubAPIHelper.getGithubUser(thisCommit.author.url);
                            gpbuPackage[0].POC_Name__c = githubUser.name;
                            gpbuPackage[0].POC_Email__c = githubUser.email;
                        }

                        update gpbuPackage[0];
                    }
                }
            }else{
                System.debug('No Commits found');  
            }
        }else{
            System.debug('Could not find Component ' + gpbuPackage[0].Id);   
        }

    }


    @future(callout = true)
    public static void updateComponentSourceTagInfo(Id gpbuPackageId){
        System.debug('Running updateComponentSourceTagInfo');  
        List<Demo_Component__c> gpbuPackage = [SELECT Id, Github_Repository_URL__c FROM Demo_Component__c WHERE Id = :gpbuPackageId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('Processing ' + gpbuPackage[0].Github_Repository_URL__c);   
            List<GithubAPIHelper.GithubTag> githubTags = GithubAPIHelper.getGithubTags(gpbuPackage[0].Github_Repository_URL__c);

            if(githubTags != null && githubTags.size() > 0){
                for(GithubAPIHelper.GithubTag thisTag: githubTags){
                    if (thisTag.latestTagFlag){
                        gpbuPackage[0].Latest_Tag_Commit_DateTime__c = thisTag.tagDate;
                        gpbuPackage[0].Latest_Tag_Commit_Description__c = thisTag.githubCommit.commitInfo.message;
                        gpbuPackage[0].Latest_Tag_Commit_Hash__c = thisTag.githubCommit.sha;
                        gpbuPackage[0].Latest_Tag_Version_Name__c = thisTag.name;
                        update gpbuPackage[0];
                    }
                }
            }else{
                System.debug('No Commits found');  
            }
        }else{
            System.debug('Could not find Component ' + gpbuPackage[0].Id);   
        }

    }







/*
 * Sample Data and queries for Tooling API calls:
 * SubscriberPackageVersion: 04t1K000002J0KK
 * /services/data/v48.0/tooling/query/?q=SELECT+Id+,Dependencies+,SubscriberPackageId+,Name+,Description+,PublisherName+,MajorVersion+,MinorVersion+,PatchVersion+FROM+SubscriberPackageVersion+WHERE+Id+='04t3h000004bdPAAAY'
 * SubscriberPackage: 0331K000000oduuQAA
 * /services/data/v48.0/tooling/query/?q=SELECT+Id+,Name+,Description+FROM+SubscriberPackage+WHERE+Id+='0331K000000oduuQAA'
 */

    //TODO: Check to see if Subscriber_Package_Id__c already exists
    @future(callout = true)
    public static void createPackageFromSubscriberPackageVersionId(String SubscriberPackageVersionId, Id gpbuPackageId){
        System.debug('Start createPackageFromSubscriberPackageVersionId');
        System.debug('Processing ' + SubscriberPackageVersionId);

        Demo_Component__c gpbuDependentPackage = new Demo_Component__c();
        gpbuDependentPackage.Last_Fetched__c = Datetime.Now();

        //Preset Options. We assume we can at least do an install from a Package
        gpbuDependentPackage.Source_Install_Type_Flag__c = false;
        gpbuDependentPackage.SFDX_Package_Enabled_Flag__c = false; 
        gpbuDependentPackage.Package_Install_Type_Flag__c = true;        
        gpbuDependentPackage.Latest_Subscriber_Package_Version_Id__c = SubscriberPackageVersionId;

        String query = 'SELECT+Id+,Dependencies+,SubscriberPackageId+,Name+,Description+,PublisherName+,MajorVersion+,MinorVersion+,PatchVersion+,BuildNumber+FROM+SubscriberPackageVersion+WHERE+Id+=\''+SubscriberPackageVersionId + '\'';
        Map<String,Object> results = new Map<String,Object>();
        results = (Map<String,Object>) MetadataAPIHelper.getMetadataAPI(query);

        List<Object> records = new List<Object>();
        records = (List<Object>) results.get('records');
        
        system.debug('SubscriberPackageVersion Records:' + records);

        for(Object record: records){
            Map<String,Object> thisRecord = (Map<String,Object>) record;
            system.debug((String)thisRecord.get('SubscriberPackageId'));
            gpbuDependentPackage.Subscriber_Package_Id__c = thisRecord.containsKey('SubscriberPackageId') ? (String)thisRecord.get('SubscriberPackageId') : '';
            String version = '';
            version += thisRecord.containsKey('MajorVersion') ? String.valueOf(thisRecord.get('MajorVersion')) : '0';
            version += '.';
            version += thisRecord.containsKey('MinorVersion') ? String.valueOf(thisRecord.get('MinorVersion')) : '0';
            version += '.';
            version += thisRecord.containsKey('PatchVersion') ? String.valueOf(thisRecord.get('PatchVersion')) : '0';               
            version += '-';
            version += thisRecord.containsKey('BuildNumber') ? String.valueOf(thisRecord.get('BuildNumber')) : '0';               
            system.debug('Version: ' + version);            
            gpbuDependentPackage.Latest_Package_Version__c = version;
            gpbuDependentPackage.Latest_Package_Version_Name__c = thisRecord.containsKey('Name') ? (String)thisRecord.get('Name') : '';  
        }

        query = 'SELECT+Id+,Name+,Description+FROM+SubscriberPackage+WHERE+Id+=\''+gpbuDependentPackage.Subscriber_Package_Id__c + '\'';
        
        results = (Map<String,Object>) MetadataAPIHelper.getMetadataAPI(query);
        records = (List<Object>) results.get('records');

        system.debug('SubscriberPackage Records:' + records);

        for(Object record: records){
            Map<String,Object> thisRecord = (Map<String,Object>) record;
            gpbuDependentPackage.Title__c = thisRecord.containsKey('Name') ? (String)thisRecord.get('Name') : '';
            gpbuDependentPackage.Description__c = thisRecord.containsKey('description') ? (String)thisRecord.get('description') : '';     
            gpbuDependentPackage.Package_Name__c = thisRecord.containsKey('Name') ? (String)thisRecord.get('Name') : '';        
        }
        
        System.debug('Insert New Package: ' + gpbuDependentPackage);  
        insert gpbuDependentPackage;


        List<Component_Dependency__c> packageDependencyLookup = [SELECT Id, Demo_Component__c, Dependent_Component__c FROM Component_Dependency__c WHERE Demo_Component__c = :gpbuPackageId AND Dependent_Component__c = :gpbuDependentPackage.Id LIMIT 1];
        if(packageDependencyLookup.size() > 0){
            System.debug('Package Dependency Already Exists, skipping');
        }else{
            System.debug('Creating new Package Dependency');
            Component_Dependency__c packageDependency = new Component_Dependency__c();
            packageDependency.Demo_Component__c = gpbuPackageId;
            packageDependency.Dependent_Component__c = gpbuDependentPackage.id;
            insert packageDependency;
        }

    }





    //Updates Package Name and Subscriber Id from the Tooling API based upon its Subscriber Version ID
    @future(callout = true)
    public static void updatePackageFromSubscriberPackageVersionId(String gpbuPackageId){
        System.debug('Start updatePackageFromSubscriberPackageVersionId');

        List<Demo_Component__c> gpbuPackage = [SELECT Id, Description__c, Latest_Subscriber_Package_Version_Id__c, Subscriber_Package_Id__c FROM Demo_Component__c WHERE Id = :gpbuPackageId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('Demo_Component__c found');  

            String query = 'SELECT+Id+,Dependencies+,SubscriberPackageId+,Name+,Description+,PublisherName+,MajorVersion+,MinorVersion+,PatchVersion+,BuildNumber+FROM+SubscriberPackageVersion+WHERE+Id+=\''+ gpbuPackage[0].Latest_Subscriber_Package_Version_Id__c + '\'';
            
            System.debug('Running Metadata API using the following query: ' + query); 
            Map<String,Object> results = new Map<String,Object>();
            
            results = (Map<String,Object>) MetadataAPIHelper.getMetadataAPI(query);

            List<Object> records = new List<Object>();
            records = (List<Object>) results.get('records');
            
            system.debug('SubscriberPackageVersion Records:' + records);

            for(Object record: records){
                Map<String,Object> thisRecord = (Map<String,Object>) record;
                system.debug((String)thisRecord.get('SubscriberPackageId'));
                gpbuPackage[0].Subscriber_Package_Id__c = thisRecord.containsKey('SubscriberPackageId') ? (String)thisRecord.get('SubscriberPackageId') : '';
                String version = '';
                version += thisRecord.containsKey('MajorVersion') ? String.valueOf(thisRecord.get('MajorVersion')) : '0';
                version += '.';
                version += thisRecord.containsKey('MinorVersion') ? String.valueOf(thisRecord.get('MinorVersion')) : '0';
                version += '.';
                version += thisRecord.containsKey('PatchVersion') ? String.valueOf(thisRecord.get('PatchVersion')) : '0';               
                version += '-';
                version += thisRecord.containsKey('BuildNumber') ? String.valueOf(thisRecord.get('BuildNumber')) : '0';               
                system.debug('Version: ' + version);            
                gpbuPackage[0].Latest_Package_Version__c = version;
                gpbuPackage[0].Latest_Package_Version_Name__c = thisRecord.containsKey('Name') ? (String)thisRecord.get('Name') : '';  
            }


            query = 'SELECT+Id+,Name+,Description+FROM+SubscriberPackage+WHERE+Id+=\''+gpbuPackage[0].Subscriber_Package_Id__c + '\'';
            results = (Map<String,Object>) MetadataAPIHelper.getMetadataAPI(query);
            records = (List<Object>) results.get('records');

            system.debug('SubscriberPackage Records:' + records);

            for(Object record: records){
                Map<String,Object> thisRecord = (Map<String,Object>) record;
                gpbuPackage[0].Package_Name__c = thisRecord.containsKey('Name') ? (String)thisRecord.get('Name') : '';       
            }
            
            System.debug('Updating Package');  
            upsert gpbuPackage[0];
        }else{
            System.debug('No Demo_Component__c found, skipping');  
        }
    }

    



    //TODO: Check to see if Subscriber_Package_Id__c already exists
    public static void getInstalledPackages(){
        System.debug('Start getInstalledPackages');

        List<Demo_Component__c> newGPBUPackages = new List<Demo_Component__c>();       

        /*
        newGPBUPackage.Last_Fetched__c = Datetime.Now();

        //Preset Options. We assume we can at least do an install from a Package
        newGPBUPackage.Source_Install_Type_Flag__c = false;
        newGPBUPackage.SFDX_Package_Enabled_Flag__c = false; 
        newGPBUPackage.Package_Install_Type_Flag__c = true;        
        newGPBUPackage.Latest_Subscriber_Package_Version_Id__c = SubscriberPackageVersionId;
        */


        String query = 'SELECT+Id,+SubscriberPackageId,+SubscriberPackage.NamespacePrefix,+++++++SubscriberPackage.Name,+++++++SubscriberPackage.Description,+SubscriberPackageVersion.Id,+++++++SubscriberPackageVersion.Name,+SubscriberPackageVersion.MajorVersion,+++++++SubscriberPackageVersion.MinorVersion,+++++++SubscriberPackageVersion.PatchVersion,+++++++SubscriberPackageVersion.BuildNumber++++FROM+InstalledSubscriberPackage++++ORDER+BY+SubscriberPackageId';
        
        Map<String,Object> results = new Map<String,Object>();
        results = (Map<String,Object>) MetadataAPIHelper.getMetadataAPI(query);

        List<Object> records = new List<Object>();
        records = (List<Object>) results.get('records');
        
        system.debug('InstalledSubscriberPackage Records:' + records);
        List<Demo_Component__c> existingPackageLookup = [SELECT Id, Package_Name__c, Installed__c, Title__c, Latest_Package_Version__c from Demo_Component__c];

        for(Object record: records){
            Map<String,Object> thisRecord = (Map<String,Object>) record;
            Map<String,Object> thisSubscriberPackage = new Map<String,Object>();
            Map<String,Object> thisSubscriberPackageVersion = new Map<String,Object>();

            thisSubscriberPackage = (Map<String,Object>) thisRecord.get('SubscriberPackage');
            thisSubscriberPackageVersion = (Map<String,Object>) thisRecord.get('SubscriberPackageVersion');

            Demo_Component__c newGPBUPackage = new Demo_Component__c();
            Boolean packageExistsFlag = false;
            system.debug('Processing Package ' + (String)thisSubscriberPackage.get('Name'));
            system.debug('Looking to see if Installed Package Matches existing Packages');
            for(Demo_Component__c existingPackage: existingPackageLookup){
                system.debug('Does Installed Package ' + (String)thisSubscriberPackage.get('Name') + ' = ' + existingPackage.Package_Name__c);
                if(String.valueOf(thisSubscriberPackage.get('Name')) == existingPackage.Package_Name__c){
                    system.debug('Package already exists, assigning it');
                    newGPBUPackage = existingPackage;
                    packageExistsFlag = true;
                }
            }
            
            if(!packageExistsFlag){
                system.debug('Package does not already exist. Creating a new one');
                newGPBUPackage.Package_Name__c = (String)thisSubscriberPackage.get('Name');
                newGPBUPackage.Title__c =  (String)thisSubscriberPackage.get('Name');  
                newGPBUPackage.Description__c = thisSubscriberPackage.containsKey('Description') ? (String)thisSubscriberPackage.get('Description') : '';    
            }
            
            newGPBUPackage.Subscriber_Package_Id__c = thisSubscriberPackageVersion.containsKey('Id') ? (String)thisSubscriberPackageVersion.get('Id') : '';
            String version = '';
            version += thisSubscriberPackageVersion.containsKey('MajorVersion') ? String.valueOf(thisSubscriberPackageVersion.get('MajorVersion')) : '0';
            version += '.';
            version += thisSubscriberPackageVersion.containsKey('MinorVersion') ? String.valueOf(thisSubscriberPackageVersion.get('MinorVersion')) : '0';
            version += '.';
            version += thisSubscriberPackageVersion.containsKey('PatchVersion') ? String.valueOf(thisSubscriberPackageVersion.get('PatchVersion')) : '0';               
            version += '-';
            version += thisSubscriberPackageVersion.containsKey('BuildNumber') ? String.valueOf(thisSubscriberPackageVersion.get('BuildNumber')) : '0';               
            system.debug('Version: ' + version);            
            
            if(!packageExistsFlag && newGPBUPackage.Latest_Package_Version__c != ''){
                //TODO: Compare Package Versions to see if an update is available
                newGPBUPackage.Latest_Package_Version__c = thisSubscriberPackageVersion.containsKey('Name') ? (String)thisSubscriberPackageVersion.get('Name') : '';  
            }else{
                newGPBUPackage.Latest_Package_Version__c = version;
            }
            newGPBUPackage.Latest_Package_Version_Name__c = thisSubscriberPackageVersion.containsKey('Name') ? (String)thisSubscriberPackageVersion.get('Name') : '';  
            newGPBUPackage.Installed_Subscriber_Package_Id__c = thisSubscriberPackageVersion.containsKey('Id') ? (String)thisSubscriberPackageVersion.get('Id') : '';
            newGPBUPackage.Latest_Subscriber_Package_Version_Id__c = thisSubscriberPackageVersion.containsKey('Id') ? (String)thisSubscriberPackageVersion.get('Id') : '';
            newGPBUPackage.Package_Installed_Version_Number__c = version;
            newGPBUPackage.Installed__c = true;
            newGPBUPackage.Installation_Type__c = 'Managed Package';

            if(newGPBUPackage.Title__c != null && newGPBUPackage.Title__c != ''){
                newGPBUPackages.add(newGPBUPackage);
            }

        } 
        System.debug('Upserting Installed Packages: ' + newGPBUPackages);  
        upsert newGPBUPackages;

    }

}