@IsTest
private  class cl_REST_RPSSheetsTest {
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_http_get() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = cl_REST_RPSSheets.BASE_URI;
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();

        cl_REST_RPSSheets.get();
        res = RestContext.response;
        String body = res.responseBody.toString();
        System.assertEquals(HttpStatusCodes.OK,res.statusCode,'Return status not '+HttpStatusCodes.OK);

        cl_REST_RPSSheets.FORCE_GET_SERVER_ERROR = true;
        cl_REST_RPSSheets.DEBUG = true;
        cl_REST_RPSSheets.get();
        res = RestContext.response;
        body = res.responseBody.toString();
        System.assertEquals(HttpStatusCodes.INTERNAL_SERVER_ERROR,res.statusCode,'Return status not '+HttpStatusCodes.INTERNAL_SERVER_ERROR);

        cl_REST_RPSSheets.FORCE_GET_SERVER_ERROR = false;
        cl_REST_RPSSheets.FORCE_RESPONSE_ERROR = true;
        cl_REST_RPSSheets.get();
        res = RestContext.response;
        body = res.responseBody.toString();
        System.assertEquals(HttpStatusCodes.BAD_REQUEST,res.statusCode,'Return status not '+HttpStatusCodes.BAD_REQUEST);

        Test.stopTest();
    }

    @IsTest
    static void test_http_post() {

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = cl_REST_RPSSheets.BASE_URI;
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('Test1: "1", TEST2: "2"}');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();

        cl_REST_RPSSheets.post();
        res = RestContext.response;
        String body = res.responseBody.toString();
        System.assertEquals(HttpStatusCodes.OK,res.statusCode,'Return status not '+HttpStatusCodes.OK);

        Test.stopTest();
    }
}