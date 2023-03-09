@IsTest
private class PortalAdvisory_Sch_ImportTest {

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
    static void test_Import_Without_Params_success() {

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        PortalAdvisory_Sch_Import schJob = new PortalAdvisory_Sch_Import();
        String cron = '0 0 23 * * ?';
        Id jobId = system.schedule('jobName', cron, schJob);
        System.assert(jobId != null);

        Test.stopTest();
    }

}