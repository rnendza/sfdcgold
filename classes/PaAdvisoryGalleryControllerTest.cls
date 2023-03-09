@IsTest
private class PaAdvisoryGalleryControllerTest {
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
    static void testRetrievePaAdvisories_success() {

        List<PA_Advisory__c> allRecords = [SELECT Id FROM PA_Advisory__c];

        Test.startTest();

        PaAdvisoryGalleryController.AdvisorySearchParams params = new PaAdvisoryGalleryController.AdvisorySearchParams();
        ResponseDto dto = PaAdvisoryGalleryController.retrievePaAdvisories(params);

        List<PaAdvisoryGalleryController.AdvisoryWrapper> advisories =
                (List<PaAdvisoryGalleryController.AdvisoryWrapper>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_WRAPS);
        System.assertEquals(allRecords.size(), advisories.size());

        dto = PaAdvisoryGalleryController.retrievePaAdvisories(null);
        advisories = (List<PaAdvisoryGalleryController.AdvisoryWrapper>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_WRAPS);
        System.assertEquals(allRecords.size(), advisories.size());

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisoriesAdvancedSearch_success() {

        List<PA_Advisory__c> allRecords = [SELECT Id FROM PA_Advisory__c];

        Test.startTest();

        PaAdvisoryGalleryController.AdvisorySearchParams params = new PaAdvisoryGalleryController.AdvisorySearchParams();
        params.iOffset = 2;
        params.iLimit = 6;

        ResponseDto dto = PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchDeclarative(params);

        List<PaAdvisoryGalleryController.AdvisoryWrapper> advisories =
                (List<PaAdvisoryGalleryController.AdvisoryWrapper>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_WRAPS);
        System.assertEquals(params.iLimit, advisories.size());

        dto = PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchImperative(params);
        advisories = (List<PaAdvisoryGalleryController.AdvisoryWrapper>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_WRAPS);
        System.assertEquals(params.iLimit, advisories.size());

        dto = PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchDeclarative(null);
        advisories = (List<PaAdvisoryGalleryController.AdvisoryWrapper>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_WRAPS);
        System.assertEquals(advisories,null);

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisoriesAdvancedSearchTotalRecords_success() {

        List<PA_Advisory__c> allRecords = [SELECT Id FROM PA_Advisory__c];

        Test.startTest();

        PaAdvisoryGalleryController.AdvisorySearchParams params = new PaAdvisoryGalleryController.AdvisorySearchParams();
        params.iOffset = 2;
        params.iLimit = 6;

        ResponseDto dto = PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchDeclarativeTotalRecords(params);
        Integer iTotal = (Integer) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT);
        System.assertEquals(params.iLimit, iTotal);

//        dto = PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchTotalRecords(params);
//        advisories = (List<PaAdvisoryGalleryController.AdvisoryWrapper>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_WRAPS);
//        System.assertEquals(params.iLimit, advisories.size());
//
        dto = PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchDeclarativeTotalRecords(null);
        iTotal = (Integer) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT);
        System.assertEquals(null, iTotal);

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaUserDetail_success() {

        PA_Advisory__c oneRecord = [SELECT Id FROM PA_Advisory__c LIMIT 1];

        Test.startTest();

        ResponseDto dto = PaAdvisoryGalleryController.retrievePaAdvisoryDetail(oneRecord.Id);
        PA_Advisory__c advisory = (PA_Advisory__c) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_RECORD);
        System.assertEquals(oneRecord.Id,advisory.Id);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveScheduledJobInfo() {

        List<String> jobStatuses = new List<String>{'queued'};
        List<String> apexClassNames = new List<String>{'blah'};

        Test.startTest();
        ResponseDto dto = PaAdvisoryGalleryController.retrieveScheduledJobInfo(apexClassNames,jobStatuses);
        System.debug('--->dtorick='+dto);
        Test.stopTest();
    }
    @IsTest
    static void test_firePaImportJob() {

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);



        Test.startTest();
        ResponseDto dto = PaAdvisoryGalleryController.firePaImportJob();
        System.debug('--> dto='+dto);
        Id jobId = (Id)dto.values.get(PaAdvisoryGalleryController.MAP_KEY_JOB_FIRE_STATUS);
        System.debug('--> jobId = '+jobId);
        System.assert(dto.isSuccess);
        System.assert(jobId != null);
        Test.stopTest();
    }
    @IsTest
    static void test_AbortPaImportJob() {

        String xmlResponse = PortalAdvisoryLoaderSvc.retrieveMockXml();
        string ep = 'http://callout.pamock.com';

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', xmlResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);


        ResponseDto dto = PaAdvisoryGalleryController.firePaImportJob();

        Test.startTest();

        dto = PaAdvisoryGalleryController.abortPaImportJob();
        List<Id> jobIds = (List<Id>)dto.values.get(PaAdvisoryGalleryController.MAP_KEY_JOB_ABORT_IDS);
        System.assert(dto.isSuccess);
        System.assert(jobIds != null && !jobIds.isEmpty());


        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisoryExportData_success() {

        List<PA_Advisory__c> allRecords = [SELECT Id FROM PA_Advisory__c WHERE Visible__c = TRUE];
        List<PA_Advisory__c> visibleRecords = [SELECT Id FROM PA_Advisory__c];

        Test.startTest();

        PaAdvisoryGalleryController.AdvisorySearchParams params = new PaAdvisoryGalleryController.AdvisorySearchParams();
        params.isVisible = true;

        ResponseDto dto = PaAdvisoryGalleryController.retrievePaAdvisoriesExportData(params);
        List<PA_Advisory__c> advisories = (List<PA_Advisory__c>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_EXPORT);
        System.assertEquals(visibleRecords.size(), advisories.size());

        params.isVisible = null;
        dto = PaAdvisoryGalleryController.retrievePaAdvisoriesExportData(params);
        advisories = (List<PA_Advisory__c>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_EXPORT);
        System.assertEquals(allRecords.size(), advisories.size());

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisoriesForPdfExport_success() {

        Map<Id,PA_Advisory__c> mPas = new Map<Id,PA_Advisory__c>([SELECT Id FROM PA_Advisory__c WHERE Visible__c = TRUE]);

        Test.startTest();


        ResponseDto dto = PaAdvisoryGalleryController.retrievePaAdvisoriesForPdfExport(new List<Id>(mPas.keySet()));

        List<PaAdvisoryGalleryController.AdvisoryWrapper> advisorywraps =
                (List<PaAdvisoryGalleryController.AdvisoryWrapper>) dto.values.get(PaAdvisoryGalleryController.MAP_KEY_ADVISORY_WRAPS);
        System.assertEquals(mPas.size(), advisorywraps.size());

        Test.stopTest();
    }
}