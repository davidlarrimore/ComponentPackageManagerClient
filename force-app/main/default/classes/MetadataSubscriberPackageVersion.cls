public class MetadataSubscriberPackageVersion {
    public String id;
    public String name;
    public String description;
    public Integer majorVersion;
    public Integer minorVersion;
    public Integer patchVersion;
    public Integer buildNumber;   

    public String publisherName;
    public String subscriberPackageId;  
    public MetadataSubscriberPackageDependencies dependencies;  
    
    //public Map<String,String> dependencies; //TODO:FIX.....    

    /* Example Dependencies JSON
        {
        "Dependencies": {
            "ids": [
            {
                "subscriberPackageVersionId": "04t1K000002J0KKQA0"
            },
            {
                "subscriberPackageVersionId": "04t1t0000034vZjAAI"
            }
            ]
        }
        }
    */

    public MetadataSubscriberPackageVersion() {

    }

    public String getSubscriberPackageVersionNumberText(){
        system.debug('Running MetadataSubscriberPackageVersion.getSubscriberPackageVersionNumberText');       
        String version = '';
        version += this.majorVersion != null ? String.valueOf(this.majorVersion)  : '0';
        version += '.';
        version += this.minorVersion != null ? String.valueOf(this.minorVersion) : '0';
        version += '.';
        version += this.patchVersion != null ? String.valueOf(this.patchVersion) : '0';               
        version += '-';
        version += this.buildNumber != null ? String.valueOf(this.buildNumber) : '0';   
        
        system.debug('VersionText: ' + version);    
        return version;
    }

    public Integer getSubscriberPackageVersionNumber(){
        system.debug('Running MetadataSubscriberPackageVersion.getSubscriberPackageVersionNumber');  
        Integer versionNumber = 0;
        versionNumber += Integer.valueOf(String.valueOf(this.majorVersion) + '000000');
        versionNumber += Integer.valueOf(String.valueOf(this.minorVersion) + '0000');
        versionNumber += Integer.valueOf(String.valueOf(this.patchVersion) + '00');
        versionNumber += Integer.valueOf(String.valueOf(this.buildNumber));                    
        
        system.debug('Version Number: ' + String.valueOf(versionNumber));    
        return versionNumber;
    }

}