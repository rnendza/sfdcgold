@IsTest
private class TEST_SchBatchSweepstakesLocUpdate {

    public static String UNAME = 'acceltest@accel.com';

    /**
     * Generally just fires the scheduled job.
     */
    @IsTest
    static void test_fire_schedule() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();
            Sch_BatchSweepstakesLocUpdate schJob = new Sch_BatchSweepstakesLocUpdate();
            String cron = '0 0 23 * * ?';
            system.schedule('jobName', cron, schJob);
            Test.stopTest();
        }
    }
}