@IsTest
private class TEST_Sch_QueueableCountyUpdater {

    public static String UNAME = 'acceltest@accel.com';
    
    /**
     * Generally just fires the scheduled job.
     */
    @IsTest
    static void test_Sch_Queueable_County_Updater_Positive() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();
            Sch_QueueableCountyUpdater schJob = new Sch_QueueableCountyUpdater(1,50,'jobName');
            String cron = '0 0 23 * * ?';
            system.schedule('jobName', cron, schJob);
            Test.stopTest();
        }
    }
}