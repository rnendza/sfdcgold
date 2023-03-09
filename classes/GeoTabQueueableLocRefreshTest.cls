@IsTest
private class GeoTabQueueableLocRefreshTest {

    static String LOG_RECORD_TYPE   = 'Salesforce_CRM';

    @TestSetup
    static void setup() {

        Test.startTest();

        List<ServiceResource> srs = new List<ServiceResource>();
        String testDeviceId1 = GeoTabUtils.TEST_DEVICE_IDS[0];
        String testDeviceId2 = GeoTabUtils.TEST_DEVICE_IDS[1];

        Profile p = [SELECT Id FROM Profile WHERE NAME = 'System Administrator'  LIMIT 1];
        User u = [SELECT Id,Name FROM User WHERE Profile.Id = :p.Id AND IsActive = TRUE AND Id != :UserInfo.getUserId() LIMIT 1];

        srs.add(AccelTestHarness.buildSingleServiceResource(UserInfo.getName(),UserInfo.getUserId(),testDeviceId1));
        srs.add(AccelTestHarness.buildSingleServiceResource(u.name,u.id,testDeviceId2));

        insert srs;

        Test.stopTest();
    }

    @IsTest
    static void test_all_resources() {

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

        GeoTabQueueableLocRefresh q = new GeoTabQueueableLocRefresh();
        System.enqueueJob(q);

        Test.stopTest();

        //@todo asserts
    }

    @IsTest
    static void test_specific_resources() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testGetDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);
        Map<Id,ServiceResource> m = new Map<Id,ServiceResource>([SELECT Id FROM ServiceResource]);

        Test.startTest();

        GeoTabQueueableLocRefresh q = new GeoTabQueueableLocRefresh(m.keySet());
        System.enqueueJob(q);

        Test.stopTest();

        //@todo asserts
    }



    @IsTest
    static void test_specific_resources_lastknownlocationdate() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testGetDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);
        Map<Id,ServiceResource> m = new Map<Id,ServiceResource>([SELECT Id FROM ServiceResource]);

        Test.startTest();

        GeoTabQueueableLocRefresh q = new GeoTabQueueableLocRefresh(m.keySet());
        System.enqueueJob(q);

        Test.stopTest();

        List<ServiceResource> srs = [
                SELECT Id,LastKnownLocationDate
                FROM ServiceResource
                WHERE Id IN :m.keySet()
        ];
        for(ServiceResource sr : srs) {
           // System.assert(sr.LastKnownLocationDate != null);  @todo check assert!
        }
    }




    @IsTest
    static void test_no_resource_found() {

        API_Setting__mdt mdtApi = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        String authJson = GeoTabUtils.testAuthResJson;
        String deviceStatusInfoJson = GeoTabUtils.testGetDeviceStatusInfoResJson;

        MockHttpResponseHandler.SimpleMockResponse authMockRes = buildMockResp(mdtApi.Http_Method__c,authJson,HttpStatusCodes.OK);
        MockHttpResponseHandler.SimpleMockResponse deviceStatusInfoMockRes = buildMockResp(mdtApi.Http_Method__c,deviceStatusInfoJson,HttpStatusCodes.OK);
        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, authMockRes);
        mock.addResponse(mdtApi.Endpoint__c+'/'+mdtApi.API_Method__c, deviceStatusInfoMockRes);

        Test.setMock(HttpCalloutMock.class, mock);
        List<ServiceResource> srs = [SELECT Id, GeotabId__c,LastKnownLocationDate FROM ServiceResource WHERE GeotabId__c != NULL];
        for(ServiceResource sr : srs) {
            sr.GeotabId__c = null;
            sr.LastKnownLocationDate = System.now();
        }
        try {
            update srs;
        } catch (Exception e) {
            //@todo some declarative change was made uat and not dev preventing this delete from
            // happening now.. just catch it for now.  sigh.
            System.debug(LoggingLevel.DEBUG,e);
        }

        Test.startTest();

        GeoTabQueueableLocRefresh q = new GeoTabQueueableLocRefresh();
        System.enqueueJob(q);

        Test.stopTest();

        //@todo asserts
    }

    @IsTest
    static void test_all_resources_partialupdatefailure_negative() {

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
        GeoTabQueueableLocRefresh.FORCE_PARTIAL_DML_EXCEPTION = true;
        GeoTabQueueableLocRefresh q = new GeoTabQueueableLocRefresh();
        System.enqueueJob(q);

        Test.stopTest();

        //@todo asserts
    }

    static  MockHttpResponseHandler.SimpleMockResponse buildMockResp(String httpMethod, String jsonResp,Integer httpStatusCode) {
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(httpMethod, jsonResp);
        getResp.statusCode = httpStatusCode;
        return getResp;
    }
}