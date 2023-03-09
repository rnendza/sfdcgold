@IsTest
private class TEST_GeocodeSearchController {

    @IsTest
    static void test_retrieveGeocodeAutocompleteAddresses() {

        String locTest = 'Lisle';
        String ep = YelpSearchSvc.LOCATION_IQ_ENDPOINT + '?key=' + YelpSearchSvc.LOCATION_IQ_API_KEY;
        ep  +='&q'+locTest;
        ep  +='&countrycodes=us';

        String getResponse = '{"a":"b"}';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto  =  GeocodeSearchController.retrieveGeocodeAutocompleteAddresses('blah');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveReverseGeocodeAddress () {

        Decimal latitude = 1.0, longitude = 2.0;
        String ep = YelpSearchSvc.LOCATION_IQ_REVERSE_GEOCODE_ENDPOINT + '?key=' + YelpSearchSvc.LOCATION_IQ_API_KEY;
        ep  +='&lat='+latitude;
        ep  +='&lon='+longitude;
        ep  +='&format=JSON';

        String getResponse = '{"a":"b"}';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto =  GeocodeSearchController.retrieveReverseGeocodeAddress (latitude,longitude);

        Test.stopTest();
    }

}