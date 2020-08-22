
/* EXAMPLE TOOLING API CALLS
 *
 * Package Install Requests: /services/data/v48.0/tooling/query/?q=SELECT+Id+,CreatedDate+,SubscriberPackageVersionKey,+PackageInstallSource+,Status+FROM+PackageInstallRequest
 * 
 * 
 * 
 */

 public with sharing class MetadataAPIHelper {
    public MetadataAPIHelper() {

    }


    //query='SELECT+Id+,SubscriberPackage.Name+,SubscriberPackage.Id+,SubscriberPackage.NamespacePrefix+,SubscriberPackageVersion.Name+,SubscriberPackageVersion.BuildNumber+,SubscriberPackageVersion.Id+,SubscriberPackageVersion.MajorVersion+,SubscriberPackageVersion.MinorVersion+,SubscriberPackageVersion.PatchVersion+FROM+InstalledSubscriberPackage';
    //string query='SELECT+Id+FROM+InstalledSubscriberPackage';
    public static Map<String,Object> getMetadataAPI(String query){
        system.debug('Running getMetadataAPI');
        system.debug('Query is ' + query);
        String SFdomainUrl=URL.getOrgDomainUrl().toExternalForm();
        String Url = SFdomainUrl+'/services/data/v48.0/tooling/query/?q='+query;
        return (Map<String,Object>) APIHelper.doRestRequest(url, true);
    }


}
