/*
 *Name: VersionHelper
 *Description: Manages data gathering to support Unlocked Package version and upgrade functions
 *hosted.scratch.herokuapp.com/byoo?template=GithubURL
 *Contact: dlarrimore@salesforce.com
 */
// 


public with sharing class VersionHelper {

    private static List<SFDXPackage> installedSFDXPackages;

    //Checks for sfdx-project.json if it has it, that means its an SFDX project
    //If it can't find sfdx-project.json, it looks for /src/project.xml this means its a legacy aura project

    public static GPBU_Package__c getPackageFromGithubURL(String githubUrl){

        System.debug('Processing ' + githubUrl);
        List<String> versions = new List<String>();
        
        Boolean demoConfigFileFlag = false;
        String packageName = '';

        GPBU_Package__c gpbuPackage = new GPBU_Package__c();
        gpbuPackage.Title__c = '';

        //@TODO: add the ability to find the package.xml in a child directory
        String sourcePath = '';

        List<String> dependentPackageSubscriberPackageVersionIds = new List<String>();

        gpbuPackage.Github_repository__c = githubUrl;
        gpbuPackage.Last_Fetched__c = Datetime.Now();

        //Preset Options. We assume we can at least do a Source install from a valid github repo
        gpbuPackage.Source_Install_Type_Flag__c = true;
        gpbuPackage.SFDX_Install_Type_Flag__c = false; 
        gpbuPackage.Package_Install_Type_Flag__c = false;

        Map<String, Object> results = new Map<String, Object>();
        System.debug('Attempting to grab sfdx-project.json from: ' + githubUrl);

        results = VersionHelper.getGithubSFDXProjectDotJSON(githubUrl);

        //return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        if (null != results){
            System.debug('Looking for Demo Config JSON file');
            Map<String, Object> demoConfigDotJSONresults = VersionHelper.getGithubDemoConfigDotJSON(githubUrl);
            //return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if (null != demoConfigDotJSONresults){
                demoConfigFileFlag = true;
                gpbuPackage.Title__c = demoConfigDotJSONresults.containsKey('name') ? (String)demoConfigDotJSONresults.get('name') : '';
                gpbuPackage.Description__c = demoConfigDotJSONresults.containsKey('description') ? (String)demoConfigDotJSONresults.get('description') : '';
                gpbuPackage.POC_Name__c = demoConfigDotJSONresults.containsKey('author') ? (String)demoConfigDotJSONresults.get('author') : '';
                gpbuPackage.POC_Email__c = demoConfigDotJSONresults.containsKey('authorEmail') ? (String)demoConfigDotJSONresults.get('authorEmail') : '';
                gpbuPackage.Admin_Permission_Set__c = demoConfigDotJSONresults.containsKey('permissionSet') ? (String)demoConfigDotJSONresults.get('permissionSet') : '';
                gpbuPackage.Package_Name__c = packageName;
                //Grabing Package Dependencies
                if(demoConfigDotJSONresults.containsKey('dependencies')){
                    for(Object dependencies: (List<Object>)demoConfigDotJSONresults.get('dependencies')){
                        Map<String, Object> thisDependencies = (Map<String,Object>) dependencies;
                        dependentPackageSubscriberPackageVersionIds.add((String)thisDependencies.get('package'));
                    }
                     System.debug('Found some dependent Packages, will address later: ' + dependentPackageSubscriberPackageVersionIds);
                }

                if(demoConfigDotJSONresults.containsKey('disableSourceInstall') && (Boolean)demoConfigDotJSONresults.get('disableSourceInstall') == true){
                    gpbuPackage.Source_Install_Type_Flag__c = false;                   
                }
            }


            /* SFDX-project.json Package Lookup Model */
            // Step 1: Get Package name from "Default" project
            System.debug('Grabbing packageDirectories');
            List<Object> packageDirectories = (List<Object>) results.get('packageDirectories');
            if (packageDirectories != null && packageDirectories.size() > 0){
                System.debug('found ' + packageDirectories.size() + ' packageDirectories');
                for(Object packageDirectory: packageDirectories){
                    Map<String,Object> thisPackageDirectory = (Map<String,Object>) packageDirectory;
                    if((boolean) thisPackageDirectory.get('default')){
                        packageName = (String)thisPackageDirectory.get('package');
                        gpbuPackage.Package_Name__c = packageName;
                        gpbuPackage.Latest_Package_Version_Name__c = thisPackageDirectory.containsKey('versionName') ? (String)thisPackageDirectory.get('versionName') : '';  
                        System.debug('found default package ' + packageName);
                        if(!demoConfigFileFlag){
                            gpbuPackage.Title__c =  packageName;
                        }  
                    }
                }
                if (null != packageName  || packageName != ''){
                    gpbuPackage.SFDX_Install_Type_Flag__c = true;

                    // Step 2: Check for packageAliases to see if we can use packaging model
                    System.debug('Grabbing packageAliases');
                    Map<String,Object> packageAliases = (Map<String,Object>) results.get('packageAliases');

                    //If no packageAliases are provided, this means there are no Unlocked or Managed Packages available
                    string latestVersion = '';
                    gpbuPackage.Latest_Version__c = '0.1.0-1';

                    if(packageAliases != null && packageAliases.keySet().size() > 0){
                        System.debug('found ' + packageAliases.keySet().size() + ' packageAliases');
                        for (String packageAliasKey: packageAliases.keySet()){
                            //PackageName = 'Demo Reset Tools'
                            System.debug('Analyzing packageAliasKey ' + packageAliasKey);
                            if(packageAliasKey.contains(packageName + '@')){
                                System.debug('packageAliases ' + packageAliasKey + ' is for the default packageDirectory.');
                                latestVersion = packageAliasKey;
                                gpbuPackage.Latest_Version__c = latestVersion.substring(latestVersion.indexOf('@')+1, latestVersion.length());
                                gpbuPackage.Latest_Package_Version__c = latestVersion.substring(latestVersion.indexOf('@')+1, latestVersion.length());
                            } 
                        }  
                        gpbuPackage.Latest_Subscriber_Package_Version_Id__c = (String) packageAliases.get(latestVersion);

                        System.debug('Latest version of package ' + packageName + ' is ' + latestVersion);
                        gpbuPackage.Package_Install_Type_Flag__c = true;

                    }else{
                        System.debug('no packageAliases found, Source is only install option');
                    }
                }
            }
        }


        //If the sfdx-package.json model did not work, we have another way. Older Project Types have a package.xml file in the /src directory
        if(null == results || packageName == '' || packageName == null){
            System.debug('Could not find sfdx-project.json, looking in src folder for package.xml');
            Dom.Document doc = VersionHelper.getGithubSFDXProjectDotXML(githubUrl);
            if (null != doc){
                //Retrieve the root element for this document.
                Dom.XMLNode rootXMLNode = doc.getRootElement();
                
                for (Dom.XMLNode child: rootXMLNode.getChildElements()) {
                    if (child.getNodeType() == DOM.XMLNodeType.ELEMENT) {
                        if(child.getName()=='fullName'){
                            System.debug('fullName: ' + child.getText());
                            packageName = child.getText();
                        }else if(child.getName()=='description'){
                            System.debug('description: ' + child.getText());
                            gpbuPackage.Description__c = child.getText();
                        }else if(child.getName()=='version'){
                            System.debug('version: ' + child.getText());
                            gpbuPackage.Latest_Version__c = child.getText();
                        }
                    }
                }
            }else{
                return null;
            }
        }

        System.debug('Seeing if Package already exists');
        List<GPBU_Package__c> existingPackageLookup = [SELECT Id from GPBU_Package__c WHERE Title__c  = :gpbuPackage.Title__c LIMIT 1];
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

        return gpbuPackage; 
    }

    public static void processDependentPackages(List<String> subscriberPackageVersionIds, Id gpbuPackageId){
        System.debug('Running processDependentPackages');
        for(String subscriberPackageVersionId: subscriberPackageVersionIds){
            System.debug('Looking up the following SubscriberPackageVersionIds: ' + SubscriberPackageVersionId);
            List<GPBU_Package__c> existingPackageLookup = [SELECT Id, Latest_Subscriber_Package_Version_Id__c from GPBU_Package__c WHERE Latest_Subscriber_Package_Version_Id__c = :subscriberPackageVersionId LIMIT 1];
            if(existingPackageLookup.size() > 0){
                System.debug('DependentPackage already exists');
                Package_Dependency__c packageDependency = new Package_Dependency__c();
                packageDependency.GPBU_Package__c = gpbuPackageId;
                packageDependency.Dependent_Package__c = existingPackageLookup[0].Id;
                insert packageDependency;
            }else{
                System.debug('No existing package, adding new one #Future');
                VersionHelper.createPackageFromSubscriberPackageVersionId(subscriberPackageVersionId, gpbuPackageId);
            }
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

        GPBU_Package__c gpbuDependentPackage = new GPBU_Package__c();
        gpbuDependentPackage.Last_Fetched__c = Datetime.Now();

        //Preset Options. We assume we can at least do an install from a Package
        gpbuDependentPackage.Source_Install_Type_Flag__c = false;
        gpbuDependentPackage.SFDX_Install_Type_Flag__c = false; 
        gpbuDependentPackage.Package_Install_Type_Flag__c = true;        
        gpbuDependentPackage.Latest_Subscriber_Package_Version_Id__c = SubscriberPackageVersionId;

        String query = 'SELECT+Id+,Dependencies+,SubscriberPackageId+,Name+,Description+,PublisherName+,MajorVersion+,MinorVersion+,PatchVersion+,BuildNumber+FROM+SubscriberPackageVersion+WHERE+Id+=\''+SubscriberPackageVersionId + '\'';
        Map<String,Object> results = new Map<String,Object>();
        results = (Map<String,Object>) VersionHelper.getMetadataAPI(query);

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
        
        results = (Map<String,Object>) VersionHelper.getMetadataAPI(query);
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

        Package_Dependency__c packageDependency = new Package_Dependency__c();
        packageDependency.GPBU_Package__c = gpbuPackageId;
        packageDependency.Dependent_Package__c = gpbuDependentPackage.id;
        insert packageDependency;
    }

    //Updates Package Name and Subscriber Id from the Tooling API based upon its Subscriber Version ID
    @future(callout = true)
    public static void updatePackageFromSubscriberPackageVersionId(String gpbuPackageId){
        System.debug('Start updatePackageFromSubscriberPackageVersionId');

        List<GPBU_Package__c> gpbuPackage = [SELECT Id, Description__c, Latest_Subscriber_Package_Version_Id__c, Subscriber_Package_Id__c FROM GPBU_Package__c WHERE Id = :gpbuPackageId LIMIT 1];
        if(gpbuPackage.size() > 0){
            System.debug('GPBU_Package__c found');  

            String query = 'SELECT+Id+,Dependencies+,SubscriberPackageId+,Name+,Description+,PublisherName+,MajorVersion+,MinorVersion+,PatchVersion+,BuildNumber+FROM+SubscriberPackageVersion+WHERE+Id+=\''+ gpbuPackage[0].Latest_Subscriber_Package_Version_Id__c + '\'';
            
            System.debug('Running Metadata API using the following query: ' + query); 
            Map<String,Object> results = new Map<String,Object>();
            
            results = (Map<String,Object>) VersionHelper.getMetadataAPI(query);

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
            results = (Map<String,Object>) VersionHelper.getMetadataAPI(query);
            records = (List<Object>) results.get('records');

            system.debug('SubscriberPackage Records:' + records);

            for(Object record: records){
                Map<String,Object> thisRecord = (Map<String,Object>) record;
                gpbuPackage[0].Package_Name__c = thisRecord.containsKey('Name') ? (String)thisRecord.get('Name') : '';       
            }
            
            System.debug('Updating Package');  
            upsert gpbuPackage[0];
        }else{
            System.debug('No GPBU_Package__c found, skipping');  
        }
    }


/*

    //Grabs information on all installed packages
    public static List<SFDXPackage> getInstalledPackages(){
        String query = 'query='SELECT+Id+,SubscriberPackage.Name+,SubscriberPackage.Id+,SubscriberPackage.NamespacePrefix+,SubscriberPackageVersion.Name+,SubscriberPackageVersion.BuildNumber+,SubscriberPackageVersion.Id+,SubscriberPackageVersion.MajorVersion+,SubscriberPackageVersion.MinorVersion+,SubscriberPackageVersion.PatchVersion+FROM+InstalledSubscriberPackage';
        
        List<Object> records = (List<Object>) VersionHelper.getMetadataAPI(query);
        
        system.debug('Records:' + records);
        List<SFDXPackage> SFDXPackages = new List<SFDXPackage>();

        for(Object thisRecord: records){
            SFDXPackage newSFDXPackage = new SFDXPackage();
            Map<String, Object> ThisPackage = (Map<String, Object>) thisRecord;
            Map<String, Object> ThisSubscriberPackage = (Map<String, Object>) ThisPackage.get('SubscriberPackage');
            Map<String, Object> ThisSubscriberPackageVersion = (Map<String, Object>) ThisPackage.get('SubscriberPackageVersion');

            newSFDXPackage.PackageId = (String)ThisPackage.get('Id');
            newSFDXPackage.SubscriberPackageVersionId = (String)ThisPackage.get('SubscriberPackageVersionId');
            newSFDXPackage.SubscriberPackageId = (String)ThisPackage.get('SubscriberPackageId');
            newSFDXPackage.SubscriberPackageName = (String)ThisSubscriberPackage.get('Name');               
            
            system.debug('Record:' + thisRecord);
            system.debug('PackageId = ' + newSFDXPackage.PackageId); 
            system.debug('PackageName = ' + newSFDXPackage.SubscriberPackageName); 
            system.debug('SubscriberPackageVersionId = ' + newSFDXPackage.SubscriberPackageVersionId); 
            system.debug('SubscriberPackageId = ' + newSFDXPackage.SubscriberPackageId); 
            
            SFDXPackages.add(newSFDXPackage);
        }          
        
        System.debug(records);
        return SFDXPackages;
    }

*/


    //query='SELECT+Id+,SubscriberPackage.Name+,SubscriberPackage.Id+,SubscriberPackage.NamespacePrefix+,SubscriberPackageVersion.Name+,SubscriberPackageVersion.BuildNumber+,SubscriberPackageVersion.Id+,SubscriberPackageVersion.MajorVersion+,SubscriberPackageVersion.MinorVersion+,SubscriberPackageVersion.PatchVersion+FROM+InstalledSubscriberPackage';
    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static Map<String,Object> getMetadataAPI(String query){
        system.debug('Running getMetadataAPI');
        system.debug('Query is ' + query);
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        String Url = SFdomainUrl+'/services/data/v48.0/tooling/query/?q='+query;
        return (Map<String,Object>) VersionHelper.doRestRequest(url, true);
    }


    public static Map<String,Object> doRestRequest(String url, Boolean auth){
        system.debug('Running getRestRequest');
        system.debug('URL is ' + url);

        HttpRequest request = new HttpRequest();
        if(auth){
            request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        }
        request.setHeader('Content-Type', 'application/json');

        request.setEndpoint(url); 
        request.setMethod('GET');   
          
        try{

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                // Deserialize the JSON string into collections of primitive data types.
                system.debug('Success!');
                system.debug('Response: ' + response.getBody());
                return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            }else{
                system.debug('Request failed. Status Code: ' + response.getStatusCode());
                return null;
            }

        }catch(Exception e){
            system.debug('Error Running HTTP Request: ' + e);
            return null;
        }  
    }


    public static Map<String,Object> getGithubSFDXProjectDotJSON(String githubUrl){
        system.debug('Running getGithubSFDXProjectDotJSON against URL:' + githubUrl);
        String rawGithubUrl = '';
        String newGithubUrl = '';

        if(githubUrl.indexOf('www.github.com') > 0){
            rawGithubUrl = githubUrl.replace('www.github', 'raw.githubusercontent.com');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'raw.githubusercontent.com');
        }

        if(rawGithubUrl.contains('master')){
            system.debug('Url Contains Master, Assuming this is a subdirectory of a project');
            rawGithubUrl = rawGithubUrl.replace('/tree', '');
            newGithubUrl = rawGithubUrl + '/sfdx-project.json';
        }else{
            newGithubUrl = rawGithubUrl + '/master/sfdx-project.json';
        }

        system.debug('Converted URL to ' + newGithubUrl);

        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
        return (Map<String,Object>) VersionHelper.doRestRequest(newGithubUrl, false);
    }


    public static Map<String,Object> getGithubDemoConfigDotJSON(String githubUrl){
        system.debug('Running getGithubDemoConfigDotJSON against URL:' + githubUrl);
        String rawGithubUrl = '';
        String newGithubUrl = '';

        if(githubUrl.indexOf('www.github.com') > 0){
            rawGithubUrl = githubUrl.replace('www.github', 'raw.githubusercontent.com');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'raw.githubusercontent.com');
        }

        if(rawGithubUrl.contains('master')){
            system.debug('Url Contains Master, Assuming this is a subdirectory of a project');
            rawGithubUrl = rawGithubUrl.replace('/tree', '');
            newGithubUrl = rawGithubUrl + '/demo-config.json';
        }else{
            newGithubUrl = rawGithubUrl + '/master/demo-config.json';
        }

        system.debug('Converted URL to ' + newGithubUrl);

        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
        return (Map<String,Object>) VersionHelper.doRestRequest(newGithubUrl, false);
    }



    //For older packages (PRE SFDX), we can try to grab the /src/package.xml
    public static Dom.Document getGithubSFDXProjectDotXML(String githubUrl){
        system.debug('Running getGithubSFDXProjectDotXML against URL:' + githubUrl);
        String rawGithubUrl = '';
        String newGithubUrl = '';
        if(githubUrl.indexOf('www.github.com') > 0){
            rawGithubUrl = githubUrl.replace('www.github', 'raw.githubusercontent.com');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'raw.githubusercontent.com');
        }
        
        if(rawGithubUrl.contains('master')){
            system.debug('Url Contains Master, Assuming this is a subdirectory of a project');
            rawGithubUrl = rawGithubUrl.replace('/tree', '');
            newGithubUrl = rawGithubUrl + '/sfdx-project.json';
        }else{
            newGithubUrl = rawGithubUrl + '/master/sfdx-project.json';
        }

        system.debug('Converted URL to ' + newGithubUrl);
        


        try{        
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(newGithubUrl);

            request.setMethod('GET');
            HttpResponse response = http.send(request);
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200) {
                // Deserialize the JSON string into collections of primitive data types.
                return response.getBodyDocument();
            }else{
                return null;
            }
        }catch(Exception e){
            system.debug('Error Running API: ' + e);
            return null;
        }          
    }



    

}