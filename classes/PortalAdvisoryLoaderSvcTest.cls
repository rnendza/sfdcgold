@IsTest
private class PortalAdvisoryLoaderSvcTest {

    @TestSetup
    static void setupData() {
        Test.startTest();

        Map<String,Object> mPortalAdminData = PortalAdminTestUtils.createAllPaData();

        Test.stopTest();
    }

    @IsTest
    static void testRetrieveNumAdvisoryRecords() {
        Test.startTest();

        System.assertEquals(PortalAdvisoryLoaderSvc.retrieveNumAdvisoryRecords(),PortalAdminTestUtils.NUM_PA_ADVISORIES);

        Test.stopTest();
    }

    @IsTest
    static void testRetrieveAdvisoryDateRecords() {
        Test.startTest();

        Date dtMin = PortalAdvisoryLoaderSvc.retrieveMinAdvisoryDate();
        Date dtMax = PortalAdvisoryLoaderSvc.retrieveMaxAdvisoryDate();
        System.assert(dtMin !=null && dtMax != null && dtMax >= dtMin);

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisories_withbase64_success() {
        Test.startTest();

        Map<Id,PA_Advisory__c> mAdvisoriesByIds = new Map<Id,PA_Advisory__c>([
                SELECT Id
                FROM   PA_Advisory__c
        ]);
        List<PA_Advisory__c> paAdvisories = PortalAdvisoryLoaderSvc.retrievePaAdvisories(mAdvisoriesByIds.keySet(),null);
        System.assertEquals(mAdvisoriesByIds.size(),paAdvisories.size());
        for(PA_Advisory__c pa : paAdvisories) {
            System.assert(String.isBlank(pa.Image_Base_64_String__c));
        }

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisories_withoutbase64_success() {
        Test.startTest();

        Map<Id,PA_Advisory__c> mAdvisoriesByIds = new Map<Id,PA_Advisory__c>([
                SELECT Id
                FROM   PA_Advisory__c
        ]);
        List<PA_Advisory__c> paAdvisories = PortalAdvisoryLoaderSvc.retrievePaAdvisories(mAdvisoriesByIds.keySet());
        System.assertEquals(mAdvisoriesByIds.size(),paAdvisories.size());
        for(PA_Advisory__c pa : paAdvisories) {
            System.assert(String.isBlank(pa.Image_Base_64_String__c));
        }
        Test.stopTest();
    }

    @IsTest
    static void testParseXmlRecords_Success() {
        Test.startTest();

        String xml = PortalAdvisoryLoaderSvc.retrieveMockXml();

        List<PortalAdvisoryLoaderSvc.UserRecord> userRecords =
                PortalAdvisoryLoaderSvc.parsePaXmlRecords(xml,true,true,true);

        System.assert(!userRecords.isEmpty());
        for(PortalAdvisoryLoaderSvc.UserRecord ur : userRecords) {
            System.assert(ur.advisoryNumberAndType != null);
        }

        Test.stopTest();
    }

    @IsTest
    static void testParseXmlRecord_Success() {

        Test.startTest();

        String xml = PortalAdvisoryLoaderSvc.retrieveMockXml_1record();

        List<PortalAdvisoryLoaderSvc.UserRecord> userRecords =
                PortalAdvisoryLoaderSvc.parsePaXmlRecords(xml,true,true,true);
        System.assert(!userRecords.isEmpty());

        System.assert(!userRecords.isEmpty());
        System.assert(userRecords.size() == 1);
        for(PortalAdvisoryLoaderSvc.UserRecord ur : userRecords) {
            System.assert(ur.advisoryNumberAndType != null);
        }

        Test.stopTest();
    }

    @IsTest
    static void testParseXmlRecord_NoResults_Success() {
        Test.startTest();

        String xml = PortalAdvisoryLoaderSvc.retrieveMockNoResultsXml();

        List<PortalAdvisoryLoaderSvc.UserRecord> userRecords =
                PortalAdvisoryLoaderSvc.parsePaXmlRecords(xml,true,true,true);
        System.assert(userRecords.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void testParseErrorXmlRecords_Success() {
        Test.startTest();

        String xml = PortalAdvisoryLoaderSvc.retrieveMockErrorXml();

        List<String> errors = PortalAdvisoryLoaderSvc.findProviderErrors(xml);
        System.assert(!errors.isEmpty());
        for(String error : errors) {
            System.assert(error.contains('Error'));
        }

        Test.stopTest();
    }

    @IsTest
    static void testUpsertPaRecords_Success() {
        Test.startTest();

        String xml = PortalAdvisoryLoaderSvc.retrieveMockXml();

        List<PortalAdvisoryLoaderSvc.UserRecord> userRecords =
                PortalAdvisoryLoaderSvc.parsePaXmlRecords(xml,true,true,true);

        List<PA_Advisory__c> paAdvisories = PortalAdvisoryLoaderSvc.upsertPaRecords(userRecords);
        System.assert(!paAdvisories.isEmpty());

        Map<String,PA_Advisory__c>  mKey_Pa = new Map<String,PA_Advisory__c>();
        for(PA_Advisory__c pa : paAdvisories) {
            mKey_Pa.put(pa.Advisory_Number_And_Type__c,pa);
        }

        for(PortalAdvisoryLoaderSvc.UserRecord ur : userRecords) {
            System.assert(mKey_Pa.containsKey(ur.advisoryNumberAndType));
        }

        Test.stopTest();
    }
}