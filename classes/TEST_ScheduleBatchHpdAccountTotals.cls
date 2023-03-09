@isTest
private class TEST_ScheduleBatchHpdAccountTotals {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        TestUtils.createTestHoldPerDays();
        HpdStatsHelper.reInitHpdTotals();
    }
    @isTest static void testScheduleBatchHpdAccountTotals() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            ScheduleBatchHpdTotals.scheduleIt(System.now());
            ScheduleBatchHpdTotals scheduleBatchHpdTotals = new ScheduleBatchHpdTotals();
            String sch = '0 0 23 * * ?';
            system.schedule('Test schedule hpd totals', sch, scheduleBatchHpdTotals);

            Test.stopTest();
        }
    }

}