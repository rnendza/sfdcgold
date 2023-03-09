@isTest
public with sharing class TEST_BatchHpdInitAndLinkMuniRecs {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
            HpdStatsHelper.reInitHpdTotals();
        }
    }
    @isTest static void testBatchInitAndLinkMunis_Both() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {

            Test.startTest();
            BatchHpdInitAndLinkMuniRecs b = new BatchHpdInitAndLinkMuniRecs();
            Database.executeBatch(b);
            //@todo do real assert
            Test.stopTest();
        }
    }
}