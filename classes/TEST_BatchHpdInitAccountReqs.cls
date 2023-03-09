@isTest
private class TEST_BatchHpdInitAccountReqs {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
            //HpdStatsHelper.reInitHpdTotals();
        }
    }

    /**
     * 
     */
    @isTest static void testBatchInitHpdTotalAccountReqs() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            BatchHpdInitAccountRecs b = new BatchHpdInitAccountRecs();
            Database.executeBatch(b);
            //@todo do real assert
            Test.stopTest();
            List<Hold_Per_Day_Total__c> holdPerDayTotals = [select id, account__c from hold_per_day_total__c];
            system.assert(!holdPerDayTotals.isEmpty());
            system.debug(holdPerDayTotals);
        }
    }
}