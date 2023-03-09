@IsTest
private class TEST_YelpSearchController {

    @IsTest
    static void test_retrieveBusinesses() {
        String location = 'Lisle', term = 'slot';
        List<String> categories = new List<String>{'bar'};
        Decimal latitude = 1.0, longitude = 2.0;
        Integer radiusMeters = 500;

        String ep = YelpSearchSvc.FUSION_API_ENDPOINT + YelpSearchSvc.FUSION_API_VERSION +
                YelpSearchSvc.BUSINESS_PATH + YelpSearchSvc.SEARCH_PATH;

        String getResponse = '{"a":"b"}';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto = YelpSearchController.retrieveBusinesses(location,latitude,longitude,term,categories,radiusMeters);

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveBusinessDetails() {
        String businessId = '234234';

        String ep = YelpSearchSvc.FUSION_API_ENDPOINT + YelpSearchSvc.FUSION_API_VERSION +
                YelpSearchSvc.BUSINESS_PATH + '/';
        ep  += businessId;

        String getResponse = '{"a":"b"}';
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto = YelpSearchController.retrieveBusinessDetails(businessId);

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveReviews() {
        String businessId = '234234';

        String ep = YelpSearchSvc.FUSION_API_ENDPOINT + YelpSearchSvc.FUSION_API_VERSION +
                YelpSearchSvc.BUSINESS_PATH + '/';
        ep  += businessId + '/reviews';

        String getResponse = '{"a":"b"}';
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto = YelpSearchController.retrieveReviews(businessId);

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveCategories() {

        String ep = YelpSearchSvc.FUSION_API_ENDPOINT + YelpSearchSvc.FUSION_API_VERSION +
                YelpSearchSvc.CATEGORIES_PATH + '?locale=';
        ep  += 'en_US';

        String getResponse = getAllCategoriesResponseBodySample();
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<String> parentAliases = new List<String> {'active','arts'};
        ResponseDto dto = YelpSearchController.retrieveCategories('en_US',parentAliases);

        Test.stopTest();
    }
    public static String getReviewsResponseBodySample() {
        String body = '{"reviews": [{"id": "xAG4O7l-t1ubbwVAlPnDKg","rating": 5,"user": {"id": "W8UK02IDdRS2GL_66fuq6w","profile_url": "https://www.yelp.com/user_details?userid=W8UK02IDdRS2GL_66fuq6w",';
        body +='"image_url": "https://s3-media3.fl.yelpcdn.com/photo/iwoAD12zkONZxJ94ChAaMg/o.jpg","name": "Ella A."},"text": "Went back again to this place since the last time i visited the bay area 5 months ago, and nothing has changed. Still the sketchy Mission, Still the cashier...","time_created": "2016-08-29 00:41:13",';
        body += '"url": "https://www.yelp.com/biz/la-palma-mexicatessen-san-francisco?hrid=hp8hAJ-AnlpqxCCu7kyCWA&adjust_creative=0sidDfoTIHle5vvHEBvF0w&utm_campaign=yelp_api_v3&utm_medium=api_v3_business_reviews&utm_source=0sidDfoTIHle5vvHEBvF0w"}';
        body += '],"total": 3,"possible_languages": ["en"]}';
        return body;
    }

    public static String getAllCategoriesResponseBodySample() {
        String body = '{"categories": [{"alias": "active","title": "Active Life","parent_aliases": [],"country_whitelist": [],"country_blacklist": []},';
        body += '{"alias": "arts","title": "Arts & Entertainment","parent_aliases": [],"country_whitelist": [],"country_blacklist": []}]}';
        return body;
    }


}