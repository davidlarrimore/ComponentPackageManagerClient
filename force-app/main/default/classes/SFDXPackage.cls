public with sharing class SFDXPackage {

    public String PackageId{get; set;}
    public String SubscriberPackageName{get; set;}
    public String SubscriberPackageId{get; set;}
    public String SubscriberPackageVersionId{get; set;}   
    public String PackageVersion{get; set;}
    public Boolean IsCurrentVersion{get; set;}
    public Boolean IsLatestVersion{get; set;}

    public SFDXPackage() {

    }

    
}
