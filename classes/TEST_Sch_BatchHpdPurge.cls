@IsTest
private class TEST_Sch_BatchHpdPurge {

    public static String UNAME = 'acceltest@accel.com';
    public static Community_Async_Job_Setting__mdt setting =
            CommunityAsyncSettings.retrieveCommunityAsyncMdt(CommunityAsyncSettings.HPD_PURGE_MDT_TYPE_DEV_NAME );

    /**
     * Generally just fires the scheduled job.
     */
    @IsTest
    static void test_Sch_Batch_Hpd_Purge_Positive() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();
            Sch_BatchHpdPurge schJob = new Sch_BatchHpdPurge();
            String cron = '0 0 23 * * ?';
            system.schedule( setting.Job_Name__c, cron, schJob);
            Test.stopTest();
        }
    }
}