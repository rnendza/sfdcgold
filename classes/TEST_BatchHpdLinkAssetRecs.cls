@isTest
public with sharing class TEST_BatchHpdLinkAssetRecs {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
            HpdStatsHelper.reInitHpdTotals(); //needed so totals are created!
        }
    }
    //@TODO for future use
//    @isTest static void testBatchLinkAccountReqsWithHpdTotals_Daily() {
//        User u = TestUtils.getUserForTest(UNAME);
//        List<Account> accounts = [select id, type, hold_per_day_total__c, hold_per_day_total_daily__c from account];
//        system.debug('--------accounts='+accounts);
//        System.runAs(u) {
//
//            Test.startTest();
//
//            BatchHpdLinkAccountRecsWithHpdTotals b = new BatchHpdLinkAccountRecsWithHpdTotals('Daily', false);
//            Database.executeBatch(b);
//            //@TODO this is not calling the execute method why? batchsize?
//            //@todo do real assert
//            Test.stopTest();
//        }
//    }
    @isTest static void testBatchLinkAssetReqsWithHpdTotals_Monthly() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            BatchHpdLinkAssetRecsWithHpdTotals b = new BatchHpdLinkAssetRecsWithHpdTotals();
            Database.executeBatch(b);
            //@TODO this is not calling the execute method why? batchsize?
            //@todo do real assert
            Test.stopTest();
        }
    }
}