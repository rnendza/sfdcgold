@isTest
global class GPSAuthMockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req){
        System.assertEquals('https://webservice.donlen.com/', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        //create fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/xml');
        res.setBody('<webServiceResponse><response ResponseName="GET_AUTHENTICATION_TOKEN_RESPONSE"><responseList><responseItem id="Token" value="12345"></responseItem></responseList></response></webServiceResponse>');
        res.setStatusCode(200);
        return res;
     }
    


}