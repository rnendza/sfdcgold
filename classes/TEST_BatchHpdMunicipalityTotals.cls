@isTest
private class TEST_BatchHpdMunicipalityTotals{
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        TestUtils.createTestHoldPerDays();
        HpdStatsHelper.reInitHpdTotals();
    }
    @isTest static void testBatchUpdateHpdMunicipalityTotals() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            BatchHpdMunicipalityTotals b = new BatchHpdMunicipalityTotals('Monthly');
            Database.executeBatch(b);

            Test.stopTest();
        }
    }
}