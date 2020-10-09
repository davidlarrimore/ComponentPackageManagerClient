@isTest
global class GithubApiGetRepoCalloutMock implements HttpCalloutMock {

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {

        StaticResource staticResource = [SELECT Id, Name, Body, SystemModStamp FROM StaticResource WHERE Name LIKE 'testGithubApiGetRepo' LIMIT 1];

        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody(staticResource.Body.toString());
        response.setStatusCode(200);
        return response; 
    }
}