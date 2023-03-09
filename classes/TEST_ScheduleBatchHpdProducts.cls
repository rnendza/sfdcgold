@isTest
private class TEST_ScheduleBatchHpdProducts {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        TestUtils.createTestHoldPerDays();
    }
    @isTest static void testScheduleBatchHpdProducts() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            ScheduleBatchHpdProducts.scheduleIt(System.now());
            ScheduleBatchHpdProducts scheduleBatchHpdProducts = new ScheduleBatchHpdProducts();
            String sch = '0 0 23 * * ?';
            system.schedule('Test schedule batch hpd products...', sch, scheduleBatchHpdProducts);

            Test.stopTest();
        }
    }

}