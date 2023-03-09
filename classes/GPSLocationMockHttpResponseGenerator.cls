@isTest
global class GPSLocationMockHttpResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req){
        System.assertEquals('https://webservice.donlen.com/', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        //create fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'text/xml');
        res.setBody('<webServiceResponse><response ResponseName="GET_COMPANY_LAST_LOCATION_RESPONSE"><responseList><responseItem id="DVN" value="A05278"></responseItem><responseItem id="ActivityType" value="Stopped"></responseItem><responseItem id="LastLatitude" value="41.76046"></responseItem><responseItem id="LastLongitude" value="-87.911987"></responseItem><responseItem id="LastActivityDate" value="2018-10-25 15:19:35.0"></responseItem></responseList><responseList><responseItem id="DVN" value="A05280"></responseItem><responseItem id="ActivityType" value="In Motion"></responseItem><responseItem id="LastLatitude" value="41.931187"></responseItem><responseItem id="LastLongitude" value="-87.77961"></responseItem><responseItem id="LastActivityDate" value="2018-10-24 01:34:47.0"></responseItem></responseList><responseList><responseItem id="DVN" value="A09194"></responseItem><responseItem id="ActivityType" value="Stopped"></responseItem><responseItem id="LastLatitude" value="41.760693"></responseItem><responseItem id="LastLongitude" value="-87.91201"></responseItem><responseItem id="LastActivityDate" value="2018-10-25 12:47:23.0"></responseItem></responseList><responseList><responseItem id="DVN" value="A09466"></responseItem><responseItem id="ActivityType" value="In Motion"></responseItem><responseItem id="LastLatitude" value="41.889717"></responseItem><responseItem id="LastLongitude" value="-87.984642"></responseItem><responseItem id="LastActivityDate" value="2018-10-25 17:07:09.0"></responseItem></responseList><responseList><responseItem id="DVN" value="A10045"></responseItem><responseItem id="ActivityType" value="No Movement Today"></responseItem><responseItem id="LastLatitude" value="41.76046"></responseItem><responseItem id="LastLongitude" value="-87.911171"></responseItem><responseItem id="LastActivityDate" value="2018-10-24 11:50:46.0"></responseItem></responseList></response></webServiceResponse>');
        res.setStatusCode(200);
        return res;
     }
}