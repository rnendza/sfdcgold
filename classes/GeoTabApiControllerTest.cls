@IsTest
private class GeoTabApiControllerTest {


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
    static void test_retrieveAllDevices_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getDeviceJson = GeoTabUtils.testGetDevicesResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse devicesRes = buildMockResp(mdtApi.Http_Method__c,getDeviceJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, devicesRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto = GeoTabApiController.retrieveAllDevices(5000);
        System.assert(dto.isSuccess);

        List<GeoTabApiController.DeviceWrapper> deviceWrappers =
                (List<GeoTabApiController.DeviceWrapper>)dto.values.get(GeoTabApiController.MAP_KEY_DEVICES);
        System.assert(deviceWrappers != null && !deviceWrappers.isEmpty());


        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllDevices_autherror_negative() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authErrorJson = GeoTabUtils.testAuthErrorResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authErrorJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto = GeoTabApiController.retrieveAllDevices(5000);
        System.assert(!dto.isSuccess);
        System.assert(dto.severity == 'warning');
        System.assert(dto.message != null);

        List<GeoTabApiController.DeviceWrapper> deviceWrappers =
                (List<GeoTabApiController.DeviceWrapper>)dto.values.get(GeoTabApiController.MAP_KEY_DEVICES);
        System.assert(deviceWrappers == null || deviceWrappers.isEmpty());


        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllDevicesStatusInfo_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getDeviceStatusInfoJson = GeoTabUtils.testGetDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoRes = buildMockResp(mdtApi.Http_Method__c,getDeviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto = GeoTabApiController.retrieveAllDevicesStatusInfo(5000);
        System.assert(dto.isSuccess);

        Test.stopTest();
    }

    @IsTest
    static void test_buildServiceResourceState() {
        Test.startTest();
        GeoTabApiController.ServiceResourceState state = GeoTabApiController.buildServiceResourceState();
        System.assert(state.totalActiveServiceResources > 0);
        Test.stopTest();
    }


    @IsTest
    static void test_retrieveServiceResources_positive() {


        Test.startTest();

        ResponseDto dto = GeoTabApiController.retrieveServiceResources();
        System.assert(dto.isSuccess);

        Test.stopTest();
    }

    @IsTest
    static void test_fireDeviceStatusJob() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getDeviceStatusInfoJson = GeoTabUtils.testGetDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoRes = buildMockResp(mdtApi.Http_Method__c,getDeviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        ResponseDto dto = GeoTabApiController.fireDeviceStatusJob();
        System.debug('--> dto='+dto);
        System.debug('--> jobId = '+(Id)dto.values.get('JOB_FIRE_STATUS'));
        Test.stopTest();
    }

    @IsTest
    static void test_abortAllDeviceStatusJobs() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getDeviceStatusInfoJson = GeoTabUtils.testGetDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoRes = buildMockResp(mdtApi.Http_Method__c,getDeviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoRes);

        Test.setMock(HttpCalloutMock.class, mock);
        Id jobId;
        Test.startTest();
        ResponseDto dto = GeoTabApiController.fireDeviceStatusJob();
        jobId = (Id)dto.values.get('JOB_FIRE_STATUS');
        Test.stopTest();

        dto = GeoTabApiController.abortAllDeviceStatusJobs();
        Set<Id> abortedIds = (Set<Id>)dto.values.get('JOB_ABORT_IDS');
        System.assert(dto.isSuccess);
        System.assert(!abortedIds.isEmpty());


    }

    @IsTest
    static void test_retrieveScheduledJobInfo() {

        List<String> jobStatuses = new List<String>{'queued'};
        List<String> apexClassNames = new List<String>{'GeoTab_Sch_QueueableLocRefresh'};

        Test.startTest();
        ResponseDto dto = GeoTabApiController.retrieveScheduledJobInfo(apexClassNames,jobStatuses);
        System.debug('--->dtorick='+dto);
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAuthMdt() {

        Test.startTest();

        ResponseDto dto = GeoTabApiController.retrieveAuthMdt();
        System.assertEquals(true,dto.isSuccess);
        API_Setting__mdt authMdt = (API_Setting__mdt)dto.values.get(GeoTabApiController.MAP_KEY_AUTH_MDT);
        System.assert(authMdt != null);

        Test.stopTest();
    }

    @IsTest
    static void test_retrievePlatformCacheAuth() {

        String testAuthRespJson = GeoTabUtils.testAuthResJson;
        GeoTabAuthJsonToApex auth = GeoTabAuthJsonToApex.parse(testAuthRespJson);

        Test.startTest();
        GeoTabPlatformCacheSvc.putAuthResp(auth);
        Test.stopTest();


        ResponseDto dto = GeoTabApiController.retrievePlatformCacheAuth();
        System.assertEquals(true,dto.isSuccess);
        GeoTabApiController.CredentialsWrapper credentialsWrapper =
                (GeoTabApiController.CredentialsWrapper)dto.values.get(GeoTabApiController.MAP_KEY_AUTH_CACHE);
        System.assert(credentialsWrapper != null);
        System.assertEquals(auth.result.credentials.userName,credentialsWrapper.userName);

    }

    @IsTest
    static void test_retrieveServiceResourceState() {
        Test.startTest();
        ResponseDto dto = GeoTabApiController.retrieveCurrentServiceResourceState();
        GeoTabApiController.ServiceResourceState state =
                (GeoTabApiController.ServiceResourceState)dto.values.get(GeoTabApiController.MAP_KEY_SERVICE_RESOURCE_STATE);
        System.assert(state.totalActiveServiceResources > 0);
        Test.stopTest();
    }

    @IsTest
    static void test_calcSpeedMph_zero() {
        Test.startTest();
        System.assertEquals(0,GeoTabApiController.calcSpeedMph(0));
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveLogListWithinHours() {

        Test.startTest();

        String jobName = 'testjobname';
        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);
        log.Overall_Job_Status__c = 'Success';
        insert log;
        List<Accel_Application_Error__c> logs = GeoTabApiController.retrieveLogListWithinHours(1000, 2, new Set<String>{
                jobName}, new Set<String>{'Success','Failed'});
        System.assert(!logs.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAppLogs() {

        Test.startTest();
        String jobName = 'testjobname';
        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);
        log.Overall_Job_Status__c = 'Success';
        insert log;

        ResponseDto dto = GeoTabApiController.retrieveAppLogs(1000,2,new List<String> {jobName},new List<String>{'Success','Failed'});
        System.assert(dto.isSuccess);
        List<Accel_Application_Error__c> logs = (List<Accel_Application_Error__c>)dto.values.get(GeoTabApiController.MAP_KEY_APP_LOGS);
        System.assert(!logs.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllUsers() {

        Test.startTest();
        ResponseDto dto = GeoTabApiController.retrieveAllUsers(1);
        Test.stopTest();
    }


    static  MockHttpResponseHandler.SimpleMockResponse buildMockResp(String httpMethod, String jsonResp,Integer httpStatusCode) {
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(httpMethod, jsonResp);
        getResp.statusCode = httpStatusCode;
        return getResp;
    }

}