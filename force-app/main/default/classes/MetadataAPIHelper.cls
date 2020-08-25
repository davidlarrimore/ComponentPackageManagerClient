
/* EXAMPLE TOOLING API CALLS
 *
 * Package Install Requests: /services/data/v48.0/tooling/query/?q=SELECT+Id+,CreatedDate+,SubscriberPackageVersionKey,+PackageInstallSource+FROM+PackageInstallRequest
 * 
 * 
 * 
 */

 public with sharing class MetadataAPIHelper {

    public class MetadataResponse {
        public Integer size;
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public String entityTypeName;
        public List<MetadataResponseRecord> records;
    }   

    public class MetadataResponseRecord {
        public String id;
        public String subscriberPackageId;
        public SubscriberPackage subscriberpackage;
        public SubscriberPackageVersion subscriberPackageVersion;
    }   

    public class SubscriberPackage {
        public String id;
        public String description;
        public String name;
        public String namespacePrefix;     
    }   

    public class SubscriberPackageVersion {
        public String id;
        public String name;
        public Integer MajorVersion;
        public Integer MinorVersion;
        public Integer PatchVersion;
        public Integer BuildNumber;    
    }   

    public MetadataAPIHelper() {

    }

    public static List<MetadataResponseRecord> getInstalledPackages(){
        system.debug('Running getInstalledPackages');
        List<SubscriberPackage> subscriberPackages = new List<SubscriberPackage>();

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(MetadataAPIHelper.getInstalledPackagesQueryUrl(), true);

        system.debug('JSON Response: ' + JSONResponse);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = fixJSONVariableNames(JSONResponse);
            MetadataResponse metadataResponse = (MetadataResponse)System.JSON.deserialize(JSONResponse, MetadataResponse.class);
            system.debug('Found ' +  MetadataResponse.records.size() + ' SubscriberPackages');
            
            for(MetadataResponseRecord record: MetadataResponse.records){
                system.debug('MetadataResponseRecord: ' + record);
            }

            return MetadataResponse.records;
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
        JSONResponse = JSONResponse.replace('"BuildNumber":', '"buildNumber":');             
        JSONResponse = JSONResponse.replace('"MajorVersion":', '"majorVersion":');        
        JSONResponse = JSONResponse.replace('"MinorVersion":', '"minorVersion":');        
        JSONResponse = JSONResponse.replace('"PatchVersion":', '"patchVersion":');        
        JSONResponse = JSONResponse.replace('"SubscriberPackageVersion":', '"subscriberPackageVersion":'); 
        JSONResponse = JSONResponse.replace('"SubscriberPackageId":', '"subscriberPackageId":');     

        system.debug('Updated JSONResponse: ' + JSONResponse);

        return JSONResponse;
    }
   
    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static Map<String,Object> getMetadataQueryAPI(String query){
        system.debug('Running getMetadataQueryAPI');
        system.debug('Query is ' + query);
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        String Url = SFdomainUrl+'/services/data/v48.0/tooling/query/?q='+query;
        return (Map<String,Object>) APIHelper.doRestRequest(url, true);
    }

    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static String getBaseMetadataAPIURL(){
        system.debug('Running getBaseMetadataAPIURL');
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        return SFdomainUrl+'/services/data/v48.0/tooling/query/?q=';
    }    

    public static String getInstalledPackagesQueryUrl(){
        system.debug('Running getInstalledPackagesQueryUrl');       
        return MetadataAPIHelper.getBaseMetadataAPIURL() + MetadataAPIHelper.getInstalledPackagesQuery();
    }

    public static String getInstalledPackagesQuery(){
        system.debug('Running getInstalledPackagesQuery');
        return 'SELECT+Id,+SubscriberPackageId,+SubscriberPackage.NamespacePrefix,+++++++SubscriberPackage.Id,+++++++SubscriberPackage.Name,+++++++SubscriberPackage.Description,+SubscriberPackageVersion.Id,+++++++SubscriberPackageVersion.Name,+SubscriberPackageVersion.MajorVersion,+++++++SubscriberPackageVersion.MinorVersion,+++++++SubscriberPackageVersion.PatchVersion,+++++++SubscriberPackageVersion.BuildNumber++++FROM+InstalledSubscriberPackage++++ORDER+BY+SubscriberPackageId';
    }

    public static String getSubscriberPackageVersionQueryUrl(String subscriberPackageVersionId){
        system.debug('Running getInstalledPackagesQueryUrl');       
        return MetadataAPIHelper.getBaseMetadataAPIURL() + MetadataAPIHelper.getSubscriberPackageVersionQuery() + '+WHERE+Id+=\''+subscriberPackageVersionId + '\'';
    }

    public static String getSubscriberPackageVersionQuery(){
        system.debug('Running getInstalledPackagesQuery');
        return 'SELECT+Id+,Dependencies+,SubscriberPackageId+,Name+,Description+,PublisherName+,MajorVersion+,MinorVersion+,PatchVersion+,BuildNumber+FROM+SubscriberPackageVersion';
    }    

    public static String getSubscriberPackageVersionNumber(SubscriberPackageVersion subscriberPackageVersion){
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
