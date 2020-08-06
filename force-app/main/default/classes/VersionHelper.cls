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
        
        
        GPBU_Package__c gpbuPackage = new GPBU_Package__c();
        gpbuPackage.Title__c = '';

        //@TODO: add the ability to find the package.xml in a child directory
        String sourcePath = '';

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
            /* SFDX-project.json Package Lookup Model */
            // Step 1: Get Package name from "Default" project
            System.debug('Grabbing packageDirectories');
            List<Object> packageDirectories = (List<Object>) results.get('packageDirectories');
            if (packageDirectories != null && packageDirectories.size() > 0){
                System.debug('found ' + packageDirectories.size() + ' packageDirectories');
                for(Object packageDirectory: packageDirectories){
                    Map<String,Object> thisPackageDirectory = (Map<String,Object>) packageDirectory;
                    if((boolean) thisPackageDirectory.get('default')){
                        gpbuPackage.Title__c =  (String)thisPackageDirectory.get('package');
                        gpbuPackage.Description__c = (String)thisPackageDirectory.get('versionDescription');
                        System.debug('found default package ' + gpbuPackage.Title__c);
                    }
                }
                if (null != gpbuPackage.Title__c  || gpbuPackage.Title__c != ''){
                    gpbuPackage.SFDX_Install_Type_Flag__c = true;

                    // Step 2: Check for packageAliases to see if we can use packaging model
                    System.debug('Grabbing packageAliases');
                    Map<String,Object> packageAliases = (Map<String,Object>) results.get('packageAliases');

                    //If no packageAliases are provided, this means there are no Unlocked or Managed Packages available
                    string latestVersion = '';
                    if(packageAliases != null && packageAliases.keySet().size() > 0){
                        System.debug('found ' + packageAliases.keySet().size() + ' packageAliases');
                        for (String packageAliasKey: packageAliases.keySet()){
                            //PackageName = 'Demo Reset Tools'
                            if(packageAliasKey.contains(gpbuPackage.Title__c + '@')){
                                System.debug('packageAliases ' + packageAliasKey + ' is for the default packageDirectory.');
                                latestVersion = packageAliasKey;
                            } 
                        }  
                        gpbuPackage.Latest_Version__c = latestVersion.substring(0, latestVersion.indexOf('@'));
                        gpbuPackage.Latest_Subscriber_Package_Version_Id__c = (String) packageAliases.get(latestVersion);

                        System.debug('Latest version of package ' + gpbuPackage.Title__c + ' is ' + latestVersion);
                        gpbuPackage.Package_Install_Type_Flag__c = true;
                    }else{
                        System.debug('no packageAliases found, Source is only install option');
                    }
                }
            }
        }
        //If the sfdx-package.json model did not work, we have another way!
        if(null == results || gpbuPackage.Title__c == '' || gpbuPackage.Title__c == null){
            System.debug('Could not find sfdx-project.json, looking in src folder for package.xml');
            Dom.Document doc = VersionHelper.getGithubSFDXProjectDotXML(githubUrl);
            if (null != doc){
                //Retrieve the root element for this document.
                Dom.XMLNode rootXMLNode = doc.getRootElement();
                
                for (Dom.XMLNode child: rootXMLNode.getChildElements()) {
                    if (child.getNodeType() == DOM.XMLNodeType.ELEMENT) {
                        if(child.getName()=='fullName'){
                            System.debug('fullName: ' + child.getText());
                            gpbuPackage.Title__c = child.getText();
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

        System.debug('Inserting ' + gpbuPackage);
        //Insert gpbuPackage;

        return gpbuPackage; 
    }






    //Grabs information on all installed packages
    public static List<SFDXPackage> getInstalledPackages(){
        Map<String, Object> results = new Map<String, Object>();
        List<Object> records = (List<Object>) VersionHelper.getMetadataAPI('SELECT+Id+,SubscriberPackage.Name+,SubscriberPackage.Id+,SubscriberPackage.NamespacePrefix+,SubscriberPackageVersion.Name+,SubscriberPackageVersion.BuildNumber+,SubscriberPackageVersion.Id+,SubscriberPackageVersion.MajorVersion+,SubscriberPackageVersion.MinorVersion+,SubscriberPackageVersion.PatchVersion+FROM+InstalledSubscriberPackage');
        
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

    /*
    public static List<SFDXPackage> getSalesforcePackageInfo(SFDXPackage lastestSFDXPackage){
        List<String> subscriberPackageVersions = getMetadataAPI(lastestSFDXPackage.SubscriberPackageName);
        Map<String, Object> results = new Map<String, Object>();

        List<Object> records = (List<Object>) VersionHelper.getMetadataAPI('SELECT+Id+,SubscriberPackage.Name+,SubscriberPackage.Id+,SubscriberPackage.NamespacePrefix+,SubscriberPackageVersion.Name+,SubscriberPackageVersion.BuildNumber+,SubscriberPackageVersion.Id+,SubscriberPackageVersion.MajorVersion+,SubscriberPackageVersion.MinorVersion+,SubscriberPackageVersion.PatchVersion+FROM+InstalledSubscriberPackage');
        
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






    public static List<Object> getMetadataAPI(String query){
        
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        request.setHeader('Content-Type', 'application/json');
        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
       
        query='SELECT+Id+,SubscriberPackage.Name+,SubscriberPackage.Id+,SubscriberPackage.NamespacePrefix+,SubscriberPackageVersion.Name+,SubscriberPackageVersion.BuildNumber+,SubscriberPackageVersion.Id+,SubscriberPackageVersion.MajorVersion+,SubscriberPackageVersion.MinorVersion+,SubscriberPackageVersion.PatchVersion+FROM+InstalledSubscriberPackage';
        
        //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
        request.setEndpoint(SFdomainUrl+'/services/data/v48.0/tooling/query/?q='+query);
        
        request.setMethod('GET');
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        Map<String, Object> results =  (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return (List<Object>) results.get('records');
    }


















    public static Map<String,Object> getGithubSFDXProjectDotJSON(String githubUrl){
        system.debug('Running getMetadataAPI against URL:' + githubUrl);
        String rawGithubUrl = '';
        if(githubUrl.indexOf('www.github.com') > 0){
            rawGithubUrl = githubUrl.replace('www.github', 'raw.githubusercontent.com');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'raw.githubusercontent.com');
        }
        system.debug('Converted URL to ' + rawGithubUrl + '/master/sfdx-project.json');

        try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            //https://raw.githubusercontent.com/davidlarrimore/SFDX-demo-reset-tools/master/sfdx-project.json
            request.setEndpoint(rawGithubUrl + '/master/sfdx-project.json');
            request.setMethod('GET');

            System.debug('Attempting to grab sfdx-project.json from: ' + rawGithubUrl + '/master/sfdx-project.json');
            HttpResponse response = http.send(request);
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200) {
                // Deserialize the JSON string into collections of primitive data types.
                return (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            }else{
                return null;
            }

        }catch(Exception e){
            system.debug('Error Running API: ' + e);
            return null;
        }        
    }


    public static Dom.Document getGithubSFDXProjectDotXML(String githubUrl){
        system.debug('Running getGithubSFDXProjectDotXML against URL:' + githubUrl);
        String rawGithubUrl = '';
        if(githubUrl.indexOf('www.github.com') > 0){
            rawGithubUrl = githubUrl.replace('www.github', 'raw.githubusercontent.com');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'raw.githubusercontent.com');
        }
        system.debug('Converted URL to ' + rawGithubUrl + '/master/src/package.xml');
        
        try{        
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(rawGithubUrl + '/master/src/package.xml');

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