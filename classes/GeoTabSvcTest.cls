@IsTest
private class GeoTabSvcTest {

    static String LOG_RECORD_TYPE   = 'Salesforce_CRM';

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
    static void test_requestAuth_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String json = GeoTabUtils.testAuthResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,json,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex auth = GeoTabSvc.requestAuth(req);
        System.assert(auth.result.credentials.sessionId != null);

        Test.stopTest();
    }

    @IsTest
    static void test_requestAuth_positive_from_cache() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String json = GeoTabUtils.testAuthResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,json,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex auth = GeoTabSvc.requestAuth(req);
        System.assert(auth.result.credentials.sessionId != null);

        GeoTabAuthJsonToApex authCached = GeoTabSvc.requestAuth(req);
        System.assertEquals(auth,authCached);


        Test.stopTest();
    }

    @IsTest
    static void test_requestAuth_write_platform_cache_negative() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String json = GeoTabUtils.testAuthResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,json,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        HttpRequest req = new HttpRequest();
        GeoTabPlatformCacheSvc.GEOTAB_PARTITION = 'bogus';
        GeoTabAuthJsonToApex auth = GeoTabSvc.requestAuth(req);
       // System.assert(auth.result.credentials.sessionId != null);


        Test.stopTest();
    }

    @IsTest
    static void test_requestAuth_exception() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String json = GeoTabUtils.testAuthResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,json,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        Accel_Application_Error__c log = AppLogSvc.buildLog(LOG_RECORD_TYPE,GeoTabSvcTest.class.getName());
        insert log; // <---- force exception by firing dml before callout.
        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex auth = GeoTabSvc.requestAuth(req);
        System.assert(auth.ex instanceof CalloutException);
        System.assert(auth.ex.getMessage().contains('uncommitted work pending'));

        Test.stopTest();
    }


    @IsTest
    static void test_sendRequest_primary_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        HttpRequest req = new HttpRequest();
        GeoTabDeviceSearch deviceSearch = new GeoTabDeviceSearch();         // nothing to set to get all
        GeoTabSearchParams params = new GeoTabSearchParams(deviceSearch);
        HttpResponse res = GeoTabSvc.sendRequest(
                req,
                GeoTabUtils.generateId(),
                GeoTabSvc.GET_METHOD,
                GeoTabSvc.DEVICESTATUSINFO_TYPE,
                params,
                GeoTabSvc.DEFAULT_RESULTS_LIMIT
        );
        System.assertEquals(res.getStatusCode(),HttpStatusCodes.OK);
        GeoTabDeviceStatusInfoResult deviceStatusInfoResult =
                (GeoTabDeviceStatusInfoResult) Json.deserialize(res.getBody(),GeoTabDeviceStatusInfoResult.class);

        System.assert(deviceStatusInfoResult.error == null);
        for(GeoTabDeviceStatusInfo deviceStatusInfo : deviceStatusInfoResult.result) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(deviceStatusInfo.device.id));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_sendRequest_primary_null_params_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        HttpRequest req = new HttpRequest();
        HttpResponse res = GeoTabSvc.sendRequest(
                req,
                GeoTabUtils.generateId(),
                GeoTabSvc.GET_METHOD,
                GeoTabSvc.DEVICESTATUSINFO_TYPE,
                null,
                GeoTabSvc.DEFAULT_RESULTS_LIMIT
        );
        System.assertEquals(res.getStatusCode(),HttpStatusCodes.OK);
        GeoTabDeviceStatusInfoResult deviceStatusInfoResult =
                (GeoTabDeviceStatusInfoResult) Json.deserialize(res.getBody(),GeoTabDeviceStatusInfoResult.class);

        System.assert(deviceStatusInfoResult.error == null);
        for(GeoTabDeviceStatusInfo deviceStatusInfo : deviceStatusInfoResult.result) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(deviceStatusInfo.device.id));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_sendRequest_default_limit_no_params_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        HttpRequest req = new HttpRequest();

        HttpResponse res = GeoTabSvc.sendRequest(
                req,
                GeoTabUtils.generateId(),
                GeoTabSvc.GET_METHOD,
                GeoTabSvc.DEVICESTATUSINFO_TYPE
        );
        System.assertEquals(res.getStatusCode(),HttpStatusCodes.OK);
        GeoTabDeviceStatusInfoResult deviceStatusInfoResult =
                (GeoTabDeviceStatusInfoResult) Json.deserialize(res.getBody(),GeoTabDeviceStatusInfoResult.class);

        System.assert(deviceStatusInfoResult.error == null);
        for(GeoTabDeviceStatusInfo deviceStatusInfo : deviceStatusInfoResult.result) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(deviceStatusInfo.device.id));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_sendRequest_result_limit_no_params_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        HttpRequest req = new HttpRequest();

        HttpResponse res = GeoTabSvc.sendRequest(
                req,
                GeoTabSvc.GET_METHOD,
                GeoTabSvc.DEVICESTATUSINFO_TYPE,
                GeoTabUtils.generateId(),
                10
        );
        System.assertEquals(res.getStatusCode(),HttpStatusCodes.OK);
        GeoTabDeviceStatusInfoResult deviceStatusInfoResult =
                (GeoTabDeviceStatusInfoResult) Json.deserialize(res.getBody(),GeoTabDeviceStatusInfoResult.class);

        System.assert(deviceStatusInfoResult.error == null);
        for(GeoTabDeviceStatusInfo deviceStatusInfo : deviceStatusInfoResult.result) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(deviceStatusInfo.device.id));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_getCountOf_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getCountOfJson = GeoTabUtils.testGetCountOfResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse countOfMockRes = buildMockResp(mdtApi.Http_Method__c,getCountOfJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, countOfMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabCountResult countResult = GeoTabSvc.getCountOf(GeoTabSvc.DEVICE_TYPE,GeoTabUtils.generateId());
        System.assertEquals(countResult.result,GeoTabUtils.TEST_GET_COUNT_OF);

        Test.stopTest();
    }

    @IsTest
    static void test_getDevices_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getDeviceJson = GeoTabUtils.testGetDevicesResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse countOfMockRes = buildMockResp(mdtApi.Http_Method__c,getDeviceJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, countOfMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabDeviceResult devicesResult = GeoTabSvc.getDevices(GeoTabUtils.generateId(),null,2);

        for(GeoTabDevice device : devicesResult.result) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(device.id));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_getDevices_auth_error_negative() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authErrorJson = GeoTabUtils.testAuthErrorResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authErrorJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabSvc.FORCE_AUTH_ERROR = true;

        GeoTabDeviceResult deviceResult = GeoTabSvc.getDevices(GeoTabUtils.generateId(),null,2);
        System.assert(deviceResult.result == null);
        System.assert(deviceResult.error.error.data.type == 'InvalidUserException');

        Test.stopTest();
    }
    @IsTest
    static void test_getUsers_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String getUsersJson = GeoTabUtils.testGetUsersResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse usersMockRes = buildMockResp(mdtApi.Http_Method__c,getUsersJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, usersMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabUserResult usersResult = GeoTabSvc.getUsers(GeoTabUtils.generateId(),null,2);

        for(GeoTabUser user : usersResult.result) {
            System.assert(user.id != null);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_getUsers_auth_error_negative() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authErrorJson = GeoTabUtils.testAuthErrorResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authErrorJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabSvc.FORCE_AUTH_ERROR = true;

        GeoTabUserResult usersResult = GeoTabSvc.getUsers(GeoTabUtils.generateId(),null,2);

        System.assert(usersResult.result == null);
        System.assert(usersResult.error.error.data.type == 'InvalidUserException');

        Test.stopTest();
    }

    @IsTest
    static void test_getLogRecords_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String logRecordsJson = GeoTabUtils.testGetLogRecordsResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse logRecordsMockRes = buildMockResp(mdtApi.Http_Method__c,logRecordsJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, logRecordsMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabLogRecordsResult logRecordsResult = GeoTabSvc.getLogRecords(GeoTabUtils.generateId(),null,2);

        for(GeoTabLogRecord logRecord : logRecordsResult.result) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(logRecord.device.id));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_getDeviceStatusInfo_positive() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testGetDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabDeviceStatusInfoResult deviceStatusInfoResult = GeoTabSvc.getDeviceStatusInfo(GeoTabUtils.generateId(),null,2);

        for(GeoTabDeviceStatusInfo deviceStatusInfo : deviceStatusInfoResult.result) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(deviceStatusInfo.device.id));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_getDeviceStatusInfo_badhttpresp_negative() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String badRequestResp = GeoTabUtils.testBadRequestResponse;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,badRequestResp,HttpStatusCodes.BAD_REQUEST);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabSearchParams p = new GeoTabSearchParams();
        p.id = '23322323';  // bad heirachy level

        GeoTabDeviceStatusInfoResult deviceStatusInfoResult = GeoTabSvc.getDeviceStatusInfo(GeoTabUtils.generateId(),p,2);
        System.assertEquals(deviceStatusInfoResult.httpStatusCode,HttpStatusCodes.BAD_REQUEST);

        Test.stopTest();
    }
    @IsTest
    static void test_getDeviceStatusInfo_auth_error_negative() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String authErrorJson = GeoTabUtils.testAuthErrorResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authErrorJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        GeoTabSvc.FORCE_AUTH_ERROR = true;

        GeoTabDeviceStatusInfoResult deviceStatusInfoResult = GeoTabSvc.getDeviceStatusInfo(GeoTabUtils.generateId(),null,2);
        System.assert(deviceStatusInfoResult.result == null);
        System.assert(deviceStatusInfoResult.error.error.data.type == 'InvalidUserException');

        Test.stopTest();
    }

    @IsTest
    static void test_overLimitException_negative() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String overlimitJson = GeoTabUtils.testOverLimitException;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,overlimitJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);

        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex res = GeoTabSvc.requestAuth(req);
        System.assertEquals(res.error.error.data.type,'OverLimitException');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveServiceResources() {

        Test.startTest();

        //  Get all service resources..
        List<ServiceResource> srs = GeoTabSvc.retrieveServiceResources(null);
        System.assert( !srs.isEmpty() );

        //  Get designated service resources
        Map<Id,ServiceResource> m = new Map<Id,ServiceResource>([SELECT Id FROM ServiceResource]);
        srs = GeoTabSvc.retrieveServiceResources(m.keySet());
        System.assert( !srs.isEmpty() );

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveServiceResourcesForUpdate() {

        Set<String> geoTabIds = new Set<String>();
        geoTabIds.addAll(GeoTabUtils.TEST_DEVICE_IDS);

        Test.startTest();

        Map<Id,ServiceResource> mSrs = GeoTabSvc.retrieveServiceResourcesForUpdate(geoTabIds);
        System.assert( !mSrs.isEmpty() );

        for(ServiceResource sr : mSrs.values()) {
            System.assert(GeoTabUtils.TEST_DEVICE_IDS.contains(sr.GeotabId__c));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveServiceResourcesForUpdate_inactive() {

        Set<String> geoTabIds = new Set<String>();
        geoTabIds.addAll(GeoTabUtils.TEST_DEVICE_IDS);

        List<ServiceResource> srsWithGeoTabIDs = [
              SELECT Id,GeotabId__c,IsActive
              FROM   ServiceResource
        ];
        for(ServiceResource srs : srsWithGeoTabIDs) {
            srs.IsActive = false;
        }
        update srsWithGeoTabIDs;

        Test.startTest();

        Map<Id,ServiceResource> mSrs = GeoTabSvc.retrieveServiceResourcesForUpdate(geoTabIds);
        System.assert( mSrs.isEmpty() );

        Test.stopTest();
    }

    @IsTest
    static void test_queryForMetadata() {

        Test.startTest();

        GeoTab_Setting__mdt mdt = GeoTabSvc.queryForMetadata(GeoTabSvc.MDT_DEV_NAME_AUTH);
        System.assert( mdt != null );

        Test.stopTest();
    }

    @IsTest
    static void test_buildHttpRequest_defaultApiSettingName() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        HttpRequest req = new HttpRequest();

        Test.startTest();

        req = GeoTabSvc.buildHttpRequest(req, GeoTabTransaction.AUTH);
        System.assertEquals(req.getEndpoint(),mdtApi.Endpoint__c +'/'+mdtApi.API_Method__c);
        System.assertEquals(req.getMethod(),mdtApi.Http_Method__c);

        GeoTabAuth auth = (GeoTabAuth)JSON.deserialize(req.getBody(),GeoTabAuth.class);
        System.assertEquals(auth.params.database,mdtApi.Database__c);
        System.assertEquals(auth.params.userName,mdtApi.Username__c);
        System.assertEquals(auth.params.password,mdtApi.Password__c);

        Test.stopTest();
    }

    @IsTest
    static void test_buildHttpRequest_specificApiSettingName() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        HttpRequest req = new HttpRequest();

        Test.startTest();

        req = GeoTabSvc.buildHttpRequest(req, GeoTabTransaction.AUTH,GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        System.assertEquals(req.getEndpoint(),mdtApi.Endpoint__c +'/'+mdtApi.API_Method__c);
        System.assertEquals(req.getMethod(),mdtApi.Http_Method__c);

        GeoTabAuth auth = (GeoTabAuth)JSON.deserialize(req.getBody(),GeoTabAuth.class);
        System.assertEquals(auth.params.database,mdtApi.Database__c);
        System.assertEquals(auth.params.userName,mdtApi.Username__c);
        System.assertEquals(auth.params.password,mdtApi.Password__c);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveNumActiveServiceResources() {
        List<ServiceResource> srs = [SELECT Id FROM ServiceResource WHERE IsActive = TRUE];

        Test.startTest();
        System.assertEquals(srs.size(),GeoTabSvc.retrieveNumActiveServiceResources());
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveNumActiveServiceResourcesWithGeoTabId() {
        List<ServiceResource> srs = [SELECT Id FROM ServiceResource WHERE IsActive = TRUE AND GeotabId__c != NULL];

        Test.startTest();
        System.assertEquals(srs.size(),GeoTabSvc.retrieveNumActiveServiceResourcesWithGeoTabId());
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveNumActiveServiceResourcesWithoutGeoTabId() {
        List<ServiceResource> srs = [SELECT Id FROM ServiceResource WHERE IsActive = TRUE aND GeotabId__c = NULL];

        Test.startTest();
        System.assertEquals(srs.size(),GeoTabSvc.retrieveNumActiveServiceResourcesWithoutGeoTabId());
        Test.stopTest();
    }

    static  MockHttpResponseHandler.SimpleMockResponse buildMockResp(String httpMethod, String jsonResp,Integer httpStatusCode) {
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(httpMethod, jsonResp);
        getResp.statusCode = httpStatusCode;
        return getResp;
    }
}