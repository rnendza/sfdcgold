@IsTest
private class GeoTab_Sch_QueueableLocRefreshTest {
    public static String UNAME = 'acceltest@accel.com';

    @TestSetup
    static void setup() {

        Test.startTest();

        List<ServiceResource> srs = new List<ServiceResource>();
        String testDeviceId = GeoTabUtils.TEST_DEVICE_IDS[0];
        srs.add(AccelTestHarness.buildSingleServiceResource(UserInfo.getName(),UserInfo.getUserId(),testDeviceId));
        insert srs;

        Test.stopTest();
    }

    @IsTest
    static void test_schedule_Positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getDeviceJson = GeoTabUtils.testGetDevicesResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c, authJson, HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse countOfMockRes = buildMockResp(mdtApi.Http_Method__c, getDeviceJson, HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c + '/' + mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c + '/' + mdtApi.API_Method__c, countOfMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        GeoTab_Sch_QueueableLocRefresh schJob = new GeoTab_Sch_QueueableLocRefresh(1);
        String cron = '0 0 23 * * ?';
        system.schedule(GeoTab_Sch_QueueableLocRefresh.JOB_NAME, cron, schJob);
        Test.stopTest();

    }

    @IsTest
    static void test_abort_Positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getDeviceJson = GeoTabUtils.testGetDevicesResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c, authJson, HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse countOfMockRes = buildMockResp(mdtApi.Http_Method__c, getDeviceJson, HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c + '/' + mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c + '/' + mdtApi.API_Method__c, countOfMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        GeoTab_Sch_QueueableLocRefresh schJob = new GeoTab_Sch_QueueableLocRefresh(1);
        String cron = '0 0 23 * * ?';
        system.schedule(GeoTab_Sch_QueueableLocRefresh.JOB_NAME, cron, schJob);
        Test.stopTest();
        schJob.abortAll();

    }

    static  MockHttpResponseHandler.SimpleMockResponse buildMockResp(String httpMethod, String jsonResp,Integer httpStatusCode) {
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(httpMethod, jsonResp);
        getResp.statusCode = httpStatusCode;
        return getResp;
    }

}