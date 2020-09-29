
/* EXAMPLE TOOLING API CALLS
 *
 * Package Install Requests: /services/data/v48.0/tooling/query/?q=SELECT+Id+,CreatedDate+,SubscriberPackageVersionKey,+PackageInstallSource+FROM+PackageInstallRequest
 * 
 * 
 * 
 */

 public with sharing class MetadataAPIHelper {

    public MetadataAPIHelper() {

    }

    public static List<MetadataInstalledPackageResponseRecord> getInstalledPackages(){
        system.debug('Running getInstalledPackages');

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(MetadataAPIHelper.getInstalledPackagesQueryUrl(), true);

        system.debug('JSON Response: ' + JSONResponse);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = fixJSONVariableNames(JSONResponse);
            MetadataInstalledPackageResponse metadataInstalledPackageResponse = (MetadataInstalledPackageResponse)System.JSON.deserialize(JSONResponse, metadataInstalledPackageResponse.class);
            system.debug('Found ' +  metadataInstalledPackageResponse.records.size() + ' SubscriberPackages');
            
            for(MetadataInstalledPackageResponseRecord record: metadataInstalledPackageResponse.records){
                system.debug('MetadataResponseRecord: ' + record);
            }

            return metadataInstalledPackageResponse.records;
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }


    public static MetadataSubscriberPackageVersion getSubscriberPackageVersion(String SubscriberPackageVersionId){
        system.debug('Running getSubscriberPackageVersion');

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(MetadataAPIHelper.getSubscriberPackageVersionQueryUrl(SubscriberPackageVersionId), true);

        system.debug('JSON Response: ' + JSONResponse);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = fixJSONVariableNames(JSONResponse);
            MetadataSubscriberPackageVersionResponse metadataResponse = (MetadataSubscriberPackageVersionResponse)System.JSON.deserialize(JSONResponse, MetadataSubscriberPackageVersionResponse.class);
            system.debug('Found ' +  MetadataResponse.records.size() + ' SubscriberPackages');
            
            for(MetadataSubscriberPackageVersion record: MetadataResponse.records){
                system.debug('SubscriberPackageVersion: ' + record);
            }

            return MetadataResponse.records[0];
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }


    public static MetadataSubscriberPackage getSubscriberPackage(String SubscriberPackageId){
        system.debug('Running getSubscriberPackage');

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(MetadataAPIHelper.getSubscriberPackageQueryUrl(SubscriberPackageId), true);

        system.debug('JSON Response: ' + JSONResponse);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = fixJSONVariableNames(JSONResponse);
            MetadataSubscriberPackageResponse metadataResponse = (MetadataSubscriberPackageResponse)System.JSON.deserialize(JSONResponse, MetadataSubscriberPackageResponse.class);
            system.debug('Found ' +  MetadataResponse.records.size() + ' SubscriberPackages');
            
            for(MetadataSubscriberPackage record: MetadataResponse.records){
                system.debug('SubscriberPackage: ' + record);
            }

            return MetadataResponse.records[0];
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }


 
    public static String fixJSONVariableNames(String JSONResponse){
        system.debug('Running fixJSONVariableNames');

        JSONResponse = JSONResponse.replace('"Id":', '"id":');       
        JSONResponse = JSONResponse.replace('"Description":', '"description":');
        JSONResponse = JSONResponse.replace('"SubscriberPackage":', '"subscriberPackage":');
        JSONResponse = JSONResponse.replace('"NamespacePrefix":', '"namespacePrefix":');        
        JSONResponse = JSONResponse.replace('"Name":', '"name":');    
        JSONResponse = JSONResponse.replace('"PublisherName":', '"publisherName":');       
        JSONResponse = JSONResponse.replace('"BuildNumber":', '"buildNumber":');             
        JSONResponse = JSONResponse.replace('"MajorVersion":', '"majorVersion":');        
        JSONResponse = JSONResponse.replace('"MinorVersion":', '"minorVersion":');        
        JSONResponse = JSONResponse.replace('"PatchVersion":', '"patchVersion":');        
        JSONResponse = JSONResponse.replace('"SubscriberPackageVersion":', '"subscriberPackageVersion":'); 
        JSONResponse = JSONResponse.replace('"SubscriberPackageId":', '"subscriberPackageId":');   
        JSONResponse = JSONResponse.replace('"IsPackageValid":', '"isPackageValid":'); 

        system.debug('Updated JSONResponse: ' + JSONResponse);

        return JSONResponse;
    }
   
    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static Map<String,Object> getMetadataQueryAPI(String query){
        system.debug('Running getMetadataQueryAPI');
        system.debug('Query is ' + query);
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        String Url = SFdomainUrl+'/services/data/v49.0/tooling/query/?q='+query;
        return (Map<String,Object>) APIHelper.doRestRequest(url, true);
    }

    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static String getBaseMetadataAPIURL(){
        system.debug('Running getBaseMetadataAPIURL');
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        return SFdomainUrl+'/services/data/v49.0/tooling/query/?q=';
    }    

    public static String getInstalledPackagesQueryUrl(){
        system.debug('Running getInstalledPackagesQueryUrl');       
        return MetadataAPIHelper.getBaseMetadataAPIURL() + MetadataAPIHelper.getInstalledPackagesQuery();
    }

    public static String getInstalledPackagesQuery(){
        system.debug('Running getInstalledPackagesQuery');
        return EncodingUtil.urlEncode('SELECT Id, SubscriberPackageId, SubscriberPackage.NamespacePrefix, SubscriberPackage.Id, SubscriberPackage.Name, SubscriberPackage.Description, SubscriberPackageVersion.Id, SubscriberPackageVersion.Name, SubscriberPackageVersion.MajorVersion, SubscriberPackageVersion.MinorVersion, SubscriberPackageVersion.PatchVersion, SubscriberPackageVersion.BuildNumber FROM InstalledSubscriberPackage ORDER BY SubscriberPackageId', 'UTF-8');

    }

    public static String getSubscriberPackageVersionQueryUrl(String subscriberPackageVersionId){
        system.debug('Running getSubscriberPackageVersionQueryUrl');       
        return MetadataAPIHelper.getBaseMetadataAPIURL() + MetadataAPIHelper.getSubscriberPackageVersionQuery() + EncodingUtil.urlEncode(' WHERE Id=\''+subscriberPackageVersionId + '\'', 'UTF-8');   
    }

    public static String getSubscriberPackageVersionQuery(){
        system.debug('Running getSubscriberPackageVersionQuery');
        return EncodingUtil.urlEncode('SELECT Id, Dependencies, SubscriberPackageId, Name, Description, PublisherName, MajorVersion, MinorVersion, PatchVersion, BuildNumber FROM SubscriberPackageVersion', 'UTF-8');
    }    

    public static String getSubscriberPackageQueryUrl(String subscriberPackageId){
        system.debug('Running getSubscriberPackageQueryUrl');       
        return MetadataAPIHelper.getBaseMetadataAPIURL() + MetadataAPIHelper.getSubscriberPackageQuery() + EncodingUtil.urlEncode(' WHERE Id=\''+subscriberPackageId + '\'', 'UTF-8');
    }

    public static String getSubscriberPackageQuery(){
        system.debug('Running getSubscriberPackageQuery');
        return EncodingUtil.urlEncode('SELECT Id, Name, NamespacePrefix, IsPackageValid, Description FROM SubscriberPackage', 'UTF-8');
    }    

    public static String getSubscriberPackageVersionNumber(MetadataSubscriberPackageVersion subscriberPackageVersion){
        system.debug('Running getSubscriberPackageVersionNumber');       
        String version = '';
        version += SubscriberPackageVersion.majorVersion != null ? String.valueOf(SubscriberPackageVersion.majorVersion)  : '0';
        version += '.';
        version += SubscriberPackageVersion.minorVersion != null ? String.valueOf(SubscriberPackageVersion.minorVersion) : '0';
        version += '.';
        version += SubscriberPackageVersion.patchVersion != null ? String.valueOf(SubscriberPackageVersion.patchVersion) : '0';               
        version += '-';
        version += SubscriberPackageVersion.buildNumber != null ? String.valueOf(SubscriberPackageVersion.buildNumber) : '0';   
        
        system.debug('Version: ' + version);    
        return version;
    }


}
