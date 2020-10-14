@isTest
global class ApiCalloutMock implements HttpCalloutMock {

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
    public static final String METADATA_API_GET_INSTALLED_PACKAGES = MetadataAPIHelper.getInstalledPackagesQueryUrl();
    public static final String SUBSCRIBER_PACKAGE_VERSION_ID = '04t3h000004bdPAAAY';
    public static final String METADATA_API_GET_SUB_PACKAGE_VERSION = MetadataAPIHelper.getSubscriberPackageVersionQueryUrl(SUBSCRIBER_PACKAGE_VERSION_ID);
    public static final String SUBSCRIBER_PACKAGE_ID = '0333h000000AY9lAAG';
    public static final String METADATA_API_GET_SUB_PACKAGE = MetadataAPIHelper.getSubscriberPackageQueryUrl(SUBSCRIBER_PACKAGE_ID);
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
        METADATA_API_GET_SUB_PACKAGE_VERSION => 'testMetadataApiGetSubPackageVersion',
        METADATA_API_GET_SUB_PACKAGE => 'testMetadataApiGetSubPackage'
    };     

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        String StaticResourceName = staticResourceMap.get(request.getEndpoint());
        System.debug('THE ENDPOINT IS: ' + request.getEndpoint() + ', USING STATIC RESOURCE: ' + StaticResourceName);

        StaticResource staticResource = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE :StaticResourceName LIMIT 1];

        
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(staticResource.Body.toString());
        response.setStatusCode(200);
        return response; 
    }
}