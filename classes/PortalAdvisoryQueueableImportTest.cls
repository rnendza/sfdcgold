@IsTest
private class PortalAdvisoryQueueableImportTest {

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
    static void test_Import_With_Params_success() {

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

        DELETE [SELECT Id FROM PA_Advisory__c];

        Test.startTest();

        System.enqueueJob(new PortalAdvisoryQueueableImport(params));

        Test.stopTest();

        List<PA_Advisory__c> advisories = [
                SELECT Id, Advisory_Date__c
                FROM   PA_Advisory__c
        ];
        System.assert(!advisories.isEmpty());
    }

    @IsTest
    static void test_Import_Without_Params_success() {

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        DELETE [SELECT Id FROM PA_Advisory__c];

        Test.startTest();

        System.enqueueJob(new PortalAdvisoryQueueableImport());

        Test.stopTest();

        List<PA_Advisory__c> advisories = [
                SELECT Id, Advisory_Date__c
                FROM   PA_Advisory__c
        ];
        System.assert(!advisories.isEmpty());
    }

    @IsTest
    static void test_Import_With_DateParams_success() {

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        DELETE [SELECT Id FROM PA_Advisory__c];

        Test.startTest();
        Date dStartDate = Date.today().addDays(-2);
        Date dEndDate = Date.today();
        System.enqueueJob(new PortalAdvisoryQueueableImport(dStartDate,dEndDate));

        Test.stopTest();

        List<PA_Advisory__c> advisories = [
                SELECT Id, Advisory_Date__c
                FROM   PA_Advisory__c
        ];
        System.assert(!advisories.isEmpty());
    }

    @IsTest
    static void test_Import_With_norecords_success() {

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockNoResultsXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        DELETE [SELECT Id FROM PA_Advisory__c];

        Test.startTest();
        Date dStartDate = Date.today().addDays(-2);
        Date dEndDate = Date.today();
        System.enqueueJob(new PortalAdvisoryQueueableImport(dStartDate,dEndDate));

        Test.stopTest();

        List<PA_Advisory__c> advisories = [
                SELECT Id, Advisory_Date__c
                FROM   PA_Advisory__c
        ];
        System.assert(advisories.isEmpty());
    }

}