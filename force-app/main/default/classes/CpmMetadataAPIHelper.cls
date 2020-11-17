/* EXAMPLE TOOLING API CALLS
 *
 * 
 * 
 */

 public with sharing class CpmMetadataAPIHelper {

    public static List<MetadataInstalledPackageResponseRecord> getInstalledPackages(){
        system.debug('Running getInstalledPackages');

        //get JSON String
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(CpmMetadataAPIHelper.getInstalledPackagesQueryUrl(), true);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = fixJSONVariableNames(JSONResponse);
            MetadataInstalledPackageResponse metadataInstalledPackageResponse = (MetadataInstalledPackageResponse)System.JSON.deserialize(JSONResponse, MetadataInstalledPackageResponse.class);
            system.debug('Found ' +  metadataInstalledPackageResponse.records.size() + ' SubscriberPackages');
            
            for(MetadataInstalledPackageResponseRecord record: metadataInstalledPackageResponse.records){
                //system.debug('MetadataResponseRecord: ' + record);
            }

            return metadataInstalledPackageResponse.records;
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }

    public static List<MetadataPackageInstallRequestRecord> getInstallRequests(){
        system.debug('Running getInstallRequests');

        //get JSON String
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(CpmMetadataAPIHelper.getPackageInstallRequestQueryUrl(), true);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = fixJSONVariableNames(JSONResponse);
            MetadataPackageInstallRequest metadataPackageInstallRequest = (MetadataPackageInstallRequest)System.JSON.deserialize(JSONResponse, MetadataPackageInstallRequest.class);
            system.debug('Found ' +  metadataPackageInstallRequest.records.size() + ' SubscriberPackages');
            
            //We may get multiple records back for each subscriber, so we want the latest install date.
            List<MetadataPackageInstallRequestRecord> metadataPackageInstallRequestRecords = new List<MetadataPackageInstallRequestRecord>();
            for(MetadataPackageInstallRequestRecord record: metadataPackageInstallRequest.records){
                boolean existingRecord = false;
                for(Integer j = 0; j < metadataPackageInstallRequestRecords.size(); j++){
                    if(record.SubscriberPackageVersionKey == metadataPackageInstallRequestRecords[j].SubscriberPackageVersionKey && record.LastModifiedDate > metadataPackageInstallRequestRecords[j].LastModifiedDate){
                        existingRecord = true;
                        metadataPackageInstallRequestRecords[j] = record;
                    }
                }  
                if(!existingRecord){
                    metadataPackageInstallRequestRecords.add(record);
                }                             
            }
            return metadataPackageInstallRequestRecords;
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }

    public static MetadataSubscriberPackageVersion getSubscriberPackageVersion(String SubscriberPackageVersionId){
        system.debug('Running getSubscriberPackageVersion');

        //get JSON String
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(CpmMetadataAPIHelper.getSubscriberPackageVersionQueryUrl(SubscriberPackageVersionId), true);

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
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(CpmMetadataAPIHelper.getSubscriberPackageQueryUrl(SubscriberPackageId), true);

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


    //Because there are a lot of reserved words and case sensitivity issues, we swap all those out.
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

        return JSONResponse;
    }
   
    /*
    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static Map<String,Object> getMetadataQueryAPI(String query){
        system.debug('Running getMetadataQueryAPI');
        system.debug('Query is ' + query);
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        String Url = SFdomainUrl+'/services/data/v49.0/tooling/query/?q='+query;
        return (Map<String,Object>) CpmAPIHelper.doRestRequest(url, true);
    }
    */
    
    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static String getBaseMetadataAPIURL(){
        system.debug('Running getBaseMetadataAPIURL');
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        return SFdomainUrl+'/services/data/v49.0/tooling/query/?q=';
    }    

    public static String getInstalledPackagesQueryUrl(){
        system.debug('Running getInstalledPackagesQueryUrl');       
        return CpmMetadataAPIHelper.getBaseMetadataAPIURL() + CpmMetadataAPIHelper.getInstalledPackagesQuery();
    }

    public static String getInstalledPackagesQuery(){
        system.debug('Running getInstalledPackagesQuery');
        return EncodingUtil.urlEncode('SELECT Id, SubscriberPackageId, SubscriberPackage.NamespacePrefix, SubscriberPackage.Id, SubscriberPackage.Name, SubscriberPackage.Description, SubscriberPackageVersion.Id, SubscriberPackageVersion.IsDeprecated, SubscriberPackageVersion.Name, SubscriberPackageVersion.MajorVersion, SubscriberPackageVersion.MinorVersion, SubscriberPackageVersion.PatchVersion, SubscriberPackageVersion.BuildNumber FROM InstalledSubscriberPackage WHERE SubscriberPackageVersion.Id != Null', 'UTF-8');
    }

    public static String getPackageInstallRequestQueryUrl(){    
        system.debug('Running getPackageInstallRequestQueryUrl');       
        return CpmMetadataAPIHelper.getBaseMetadataAPIURL() + CpmMetadataAPIHelper.getPackageInstallRequestQuery();   
    }

    public static String getPackageInstallRequestQueryUrl(String SubscriberPackageVersionKey){    
        system.debug('Running getPackageInstallRequestQueryUrl');       
        return CpmMetadataAPIHelper.getBaseMetadataAPIURL() + CpmMetadataAPIHelper.getPackageInstallRequestQuery() + EncodingUtil.urlEncode(' WHERE Id=\''+SubscriberPackageVersionKey + '\'', 'UTF-8');   
    }

    //SELECT ID,SubscriberPackageVersionKey, Status, LastModifiedDate, PackageInstallSource FROM PackageInstallRequest+WHERE+SubscriberPackageVersionKey='04t1K000002J0KK'
    public static String getPackageInstallRequestQuery(){
        system.debug('Running getPackageInstallRequestQuery');
        return EncodingUtil.urlEncode('SELECT Id, UpgradeType, SubscriberPackageVersionKey, LastModifiedDate FROM PackageInstallRequest ORDER BY SubscriberPackageVersionKey ASC, LastModifiedDate DESC', 'UTF-8');
    }    

    public static String getSubscriberPackageVersionQueryUrl(String subscriberPackageVersionId){    
        system.debug('Running getSubscriberPackageVersionQueryUrl');       
        return CpmMetadataAPIHelper.getBaseMetadataAPIURL() + CpmMetadataAPIHelper.getSubscriberPackageVersionQuery() + EncodingUtil.urlEncode(' WHERE Id=\''+subscriberPackageVersionId + '\'', 'UTF-8');   
    }

    //SELECT ID,SubscriberPackageVersionKey, Status, LastModifiedDate, PackageInstallSource FROM PackageInstallRequest+WHERE+SubscriberPackageVersionKey='04t1K000002J0KK'
    public static String getSubscriberPackageVersionQuery(){
        system.debug('Running getSubscriberPackageVersionQuery');
        return EncodingUtil.urlEncode('SELECT Id, Dependencies, SubscriberPackageId, Name, Description, PublisherName, MajorVersion, IsDeprecated, MinorVersion, PatchVersion, BuildNumber FROM SubscriberPackageVersion', 'UTF-8');
    }    

    public static String getSubscriberPackageQueryUrl(String subscriberPackageId){
        system.debug('Running getSubscriberPackageQueryUrl');       
        return CpmMetadataAPIHelper.getBaseMetadataAPIURL() + CpmMetadataAPIHelper.getSubscriberPackageQuery() + EncodingUtil.urlEncode(' WHERE Id=\''+subscriberPackageId + '\'', 'UTF-8');
    }

    public static String getSubscriberPackageQuery(){
        system.debug('Running getSubscriberPackageQuery');
        return EncodingUtil.urlEncode('SELECT Id, Name, IsPackageValid, NamespacePrefix, Description FROM SubscriberPackage', 'UTF-8');
    }    
}