@IsTest
private class PortalAdvisoryQueueableDateIncrementTest {

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
    static void test_Increment_success() {

        Test.startTest();
        System.enqueueJob(new PortalAdvisoryQueueableDateIncrement());
        Test.stopTest();
    }
}