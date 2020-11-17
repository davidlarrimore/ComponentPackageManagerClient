@isTest
global class CpmApiError404CalloutMock implements HttpCalloutMock {

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"message": "Not Found","documentation_url": "https://docs.github.com/rest"}');
        response.setStatusCode(404);
        return response; 
    }
}