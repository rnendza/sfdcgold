@IsTest
private class PortalAdvisoryLoaderControllerTest {

    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String, Object> mPortalAdminData = PortalAdminTestUtils.createAllPaData();
        Test.stopTest();

        PA_Advisory__c paAdvisory = PortalAdminTestUtils.buildPaAdvisoryData(1)[0];
        paAdvisory.Advisory_Number__c = 'VGT-000864'; //  this is in the mock xml
        insert paAdvisory;
    }


    @IsTest
    static void testRetrieveCurrentPaAdvisoryObjectState() {
        Test.startTest();

        ResponseDto dto = PortalAdvisoryLoaderController.retrieveCurrentPaAdvisoryObjectState();
        PortalAdvisoryLoaderController.PaAdvisoryState state =
                (PortalAdvisoryLoaderController.PaAdvisoryState)dto.values.get(PortalAdvisoryLoaderController.MAP_KEY_PA_ADVISORY_STATE);
        System.assert(state != null);
        Test.stopTest();
    }

    @IsTest
    static void testBuildPaAdvisoryState() {
        Test.startTest();
        PortalAdvisoryLoaderController.PaAdvisoryState state = PortalAdvisoryLoaderController.buildPaAdvisoryState();
        System.assert(state != null);
        Test.stopTest();
    }

    @IsTest
    static void testDoLiveSearch_success() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = Date.today().addDays(-2);
        params.dEndDate = Date.today();
        params.customMdtDevName = 'PGCBSelfExclusionService_Prod';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doLiveSearch(params);

        Test.stopTest();
    }

    @IsTest
    static void testDoLiveSearch_nodata() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = Date.today().addDays(-2);
        params.dEndDate = Date.today();
        params.customMdtDevName = 'PGCBSelfExclusionService_Prod';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockNoResultsXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doLiveSearch(params);

        Test.stopTest();
    }

    @IsTest
    static void testDoLiveSearch_http500() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = Date.today().addDays(-2);
        params.dEndDate = Date.today();
        params.customMdtDevName = 'PGCBSelfExclusionService_Prod';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockErrorXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);
        getResp.statusCode = 500;

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doLiveSearch(params);

        Test.stopTest();
    }

    @IsTest
    static void testDoLiveSearch_badMdtPassed() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = Date.today().addDays(-2);
        params.dEndDate = Date.today();
        params.customMdtDevName = 'bogus_mdtname';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doLiveSearch(params);

        Test.stopTest();
    }

    @IsTest
    static void testDoLiveSearch_nullDateParam() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = null;
        params.dEndDate = Date.today();
        params.customMdtDevName = 'bogus_mdtname';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doLiveSearch(params);

        Test.stopTest();
    }

    @IsTest
    static void testDoLiveSearch_matchtoSfdc_success() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = Date.today().addDays(-2);
        params.dEndDate = Date.today();
        params.customMdtDevName = 'PGCBSelfExclusionService_Prod';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;
        params.matchToSfdcRecs = true;

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doLiveSearch(params);

        Test.stopTest();
    }

    @IsTest
    static void testUpsertPaRecords_success() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = Date.today().addDays(-2);
        params.dEndDate = Date.today();
        params.customMdtDevName = 'PGCBSelfExclusionService_Prod';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doUpsertPaRecords(params);

        Test.stopTest();
    }

    @IsTest
    static void testUpsertPaRecords_error() {

        PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
        params.dStartDate = Date.today().addDays(-3000);
        params.dEndDate = Date.today().addDays(-2000);
        params.customMdtDevName = 'PGCBSelfExclusionService_Prodxxxxx';
        params.debugUserRecords = true;
        params.debugXmlBody = true;
        params.pullImageData = true;

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        ResponseDto dto  = PortalAdvisoryLoaderController.doUpsertPaRecords(params);

        Test.stopTest();
    }

}