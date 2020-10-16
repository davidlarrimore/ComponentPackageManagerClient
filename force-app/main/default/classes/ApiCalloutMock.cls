@isTest
global class ApiCalloutMock implements HttpCalloutMock {

    //GITHUB API Endpoints
    public static final String GITHUB_REPO_URL_WWWW = 'https://www.github.com/davidlarrimore/richTextInputFSC';    
    public static final String GITHUB_REPO_URL = 'https://github.com/davidlarrimore/richTextInputFSC';     
    public static final String GITHUB_API_REPO_URL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC';    
    public static final String GITHUB_API_USER_URL = 'https://api.github.com/users/davidlarrimore';
    public static final String GITHUB_API_COMMITS_URL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC/commits';
    public static final String GITHUB_API_COMMIT_MASTER_URL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC/commits/master';
    public static final String GITHUB_CURRENT_COMMIT_HASH = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81';
    public static final String GITHUB_API_CURRENT_COMMIT_HASH_URL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC/commits/' + GITHUB_CURRENT_COMMIT_HASH;
    public static final String GITHUB_PREVIOUS_COMMIT_HASH = '2f79555d13074b531c6e8e3983ca1851da13f411';
    public static final String GITHUB_API_PREVIOUS_COMMIT_HASH_URL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC/commits/' + GITHUB_PREVIOUS_COMMIT_HASH;
    public static final String GITHUB_RAW_SFDX_PROJECT_URL = 'https://raw.githubusercontent.com/davidlarrimore/richTextInputFSC/master/sfdx-project.json';
    public static final String GITHUB_API_TAGS_URL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC/tags';
 
    //These URL's are a little more tricky with all the Encoding, so we just use the same functions to get the Endpoint URL
    public static final String METADATA_API_GET_INSTALLED_PACKAGES = MetadataAPIHelper.getInstalledPackagesQueryUrl();

    public static final String PREVIOUS_SUBSCRIBER_PACKAGE_VERSION_ID = '04t3h000004bdP5AAI';
    public static final String METADATA_API_GET_PREVIOUS_SUB_PACKAGE_VERSION = MetadataAPIHelper.getSubscriberPackageVersionQueryUrl(PREVIOUS_SUBSCRIBER_PACKAGE_VERSION_ID);    
    
    public static final String CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID = '04t3h000004bdPAAAY';
    public static final String METADATA_API_GET_CURRENT_SUB_PACKAGE_VERSION = MetadataAPIHelper.getSubscriberPackageVersionQueryUrl(CURRENT_SUBSCRIBER_PACKAGE_VERSION_ID);
    
    public static final String SUBSCRIBER_PACKAGE_ID = '0333h000000AY9lAAG';
    public static final String METADATA_API_GET_SUB_PACKAGE = MetadataAPIHelper.getSubscriberPackageQueryUrl(SUBSCRIBER_PACKAGE_ID);
    
    public static final String PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_VERSION_ID = '04t1K000002J0KKQA0';
    public static final String PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_ID = '0331K000000oduuQAA';
    public static final String METADATA_API_GET_DEPENDECY_1_VERSION = MetadataAPIHelper.getSubscriberPackageVersionQueryUrl(PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_VERSION_ID);
    public static final String METADATA_API_GET_DEPENDECY_1_PACKAGE = MetadataAPIHelper.getSubscriberPackageQueryUrl(PACKAGE_DEPENDENCY_1_SUBSCRIBER_PACKAGE_ID);
    
    public static final String PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_VERSION_ID = '04t1t0000034vZjAAI';
    public static final String PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_ID = '0331t000000c4w5AAA';
    public static final String METADATA_API_GET_DEPENDECY_2_VERSION = MetadataAPIHelper.getSubscriberPackageVersionQueryUrl(PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_VERSION_ID);
    public static final String METADATA_API_GET_DEPENDECY_2_PACKAGE = MetadataAPIHelper.getSubscriberPackageQueryUrl(PACKAGE_DEPENDENCY_2_SUBSCRIBER_PACKAGE_ID);

    //This variable Maps the API's to a Static Resource to provide the appropriate Response
    public static final Map<String,String> staticResourceMap = new Map<String,String>{
        GITHUB_API_REPO_URL => 'testGithubApiGetRepo',
        GITHUB_API_USER_URL => 'testGithubApiGetUser',
        GITHUB_API_COMMITS_URL => 'testGithubApiGetCommits',
        GITHUB_API_COMMIT_MASTER_URL => 'testGithubApiGetCurrentCommit',
        GITHUB_API_CURRENT_COMMIT_HASH_URL => 'testGithubApiGetCurrentCommit',
        GITHUB_API_PREVIOUS_COMMIT_HASH_URL => 'testGithubApiGetPreviousCommit',
        GITHUB_RAW_SFDX_PROJECT_URL => 'testGithubApiGetSFDXProject',
        GITHUB_API_TAGS_URL => 'testGithubApiGetTags',
        METADATA_API_GET_INSTALLED_PACKAGES => 'testMetadataApiGetInstalledPackages',
        METADATA_API_GET_PREVIOUS_SUB_PACKAGE_VERSION => 'testMetadataApiGetPreviousSubPackageVersion',
        METADATA_API_GET_CURRENT_SUB_PACKAGE_VERSION => 'testMetadataApiGetCurrentSubPackageVersion',
        METADATA_API_GET_SUB_PACKAGE => 'testMetadataApiGetSubPackage',
        METADATA_API_GET_DEPENDECY_1_VERSION => 'testMetadataApiGetPackageDependency1Version',
        METADATA_API_GET_DEPENDECY_1_PACKAGE => 'testMetadataApiGetPackageDependency1Package',
        METADATA_API_GET_DEPENDECY_2_VERSION => 'testMetadataApiGetPackageDependency2Version',
        METADATA_API_GET_DEPENDECY_2_PACKAGE => 'testMetadataApiGetPackageDependency2Package'
    };     

    global HTTPResponse respond(HTTPRequest request) {
        String StaticResourceName = staticResourceMap.get(request.getEndpoint());
        System.debug('REQUESTED MOCK ENDPOINT: ' + request.getEndpoint() + ', USING STATIC RESOURCE: ' + StaticResourceName);

        StaticResource staticResource = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE :StaticResourceName LIMIT 1];

        
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(staticResource.Body.toString());
        response.setStatusCode(200);
        return response; 
    }
}