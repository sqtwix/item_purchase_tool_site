@isTest
global class UnsplashCalloutMock implements HttpCalloutMock {
    // This method intercepts the HTTP request and hands back a fake Unsplash JSON response
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"results": [{"urls": {"small": "https://images.unsplash.com/mock-image"}}]}');
        res.setStatusCode(200);
        return res;
    }
}