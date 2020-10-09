@isTest
global class GithubApiCalloutMock implements HttpCalloutMock {

    public static final String GITHUB_API_REPO_JSON = 'testGithubApiGetRepo'; 
    public static final String GITHUB_API_USER_JSON = 'testGithubApiGetUser';   
    public static final String GITHUB_API_COMMITS_JSON = 'testGithubApiGetCommits';       
    public static final String GITHUB_API_COMMIT_JSON = 'testGithubApiGetCommit';    
    public static final String GITHUB_API_TAGS_JSON = 'testGithubApiGetTags';   
    public static final String GITHUB_API_SFDX_PROJECT_JSON = 'testGithubApiGetSFDXProject';       
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        String StaticResourceName = '';

        if(request.getEndpoint() == GithubApiTest.GITHUB_API_REPO_URL){
            StaticResourceName = GITHUB_API_REPO_JSON;
        }else if (request.getEndpoint() == GithubApiTest.GITHUB_API_USER_URL){
            StaticResourceName = GITHUB_API_USER_JSON;            
        }else if (request.getEndpoint() == GithubApiTest.GITHUB_API_COMMITS_URL){
            StaticResourceName = GITHUB_API_COMMITS_JSON;            
        }else if (request.getEndpoint() == GithubApiTest.GITHUB_API_COMMIT_MASTER_URL){
            StaticResourceName = GITHUB_API_COMMIT_JSON;            
        }else if (request.getEndpoint() == GithubApiTest.GITHUB_API_COMMIT_HASH_URL){
            StaticResourceName = GITHUB_API_COMMIT_JSON;            
        }else if (request.getEndpoint() == GithubApiTest.GITHUB_RAW_SFDX_PROJECT_URL){
            StaticResourceName = GITHUB_API_SFDX_PROJECT_JSON;            
        }else if (request.getEndpoint() == GithubApiTest.GITHUB_API_TAGS_URL){
            StaticResourceName = GITHUB_API_TAGS_JSON;            
        }

        StaticResource staticResource = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE :StaticResourceName LIMIT 1];
        System.debug('THE ENDPOINT IS: ' + request.getEndpoint());
        
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(staticResource.Body.toString());
        response.setStatusCode(200);
        return response; 
    }
}