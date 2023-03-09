@isTest
private class TEST_BatchHpdAssetTotals{
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
            HpdStatsHelper.reInitHpdTotals();
        }
    }

    /**
     *
     */
    @isTest static void testBatchUpdateHpdAssetTotals12() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            BatchHpdAssetTotals b = new BatchHpdAssetTotals(-12);
            Database.executeBatch(b);

            Test.stopTest();
            //@todo do real calc tests!
        }
    }
    /**
   *
   */
    @isTest static void testBatchUpdateHpdAssetTotals3() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            BatchHpdAssetTotals b = new BatchHpdAssetTotals(-3);
            Database.executeBatch(b);

            Test.stopTest();
            //@todo do real calc tests!
        }
    }
    /**
     *
     */
    @isTest static void testBatchUpdateHpdAssetTotals2() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            BatchHpdAssetTotals b = new BatchHpdAssetTotals(-2);
            Database.executeBatch(b);

            Test.stopTest();
            //@todo do real calc tests!
        }
    }
    /**
     *
     */
    @isTest static void testBatchUpdateHpdAssetTotals1() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            BatchHpdAssetTotals b = new BatchHpdAssetTotals(-1);
            Database.executeBatch(b);

            Test.stopTest();
            //@todo do real calc tests!
        }
    }
}