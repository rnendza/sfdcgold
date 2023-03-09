@isTest
public with sharing class TEST_BatchHpdLinkAccountRecs {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
            HpdStatsHelper.reInitHpdTotals();
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
    @isTest static void testBatchLinkAccountReqsWithHpdTotals_Monthly() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            BatchHpdLinkAccountRecsWithHpdTotals b = new BatchHpdLinkAccountRecsWithHpdTotals('Monthly', false);
            Database.executeBatch(b);
            //@TODO this is not calling the execute method why? batchsize?
            //@todo do real assert
            Test.stopTest();
        }
    }
}