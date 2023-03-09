@IsTest
private class TEST_Sch_SvcAutomatedNotifications {
    public static String UNAME = 'acceltest@accel.com';

    @IsTest
    static void test_Sch_Queueable_Svc_Automated_Notifications_Positive() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();
            Sch_QueueableSvcAutomationNotifications schJob = new Sch_QueueableSvcAutomationNotifications(3);
            String cron = '0 0 23 * * ?';
            system.schedule(Sch_QueueableSvcAutomationNotifications.JOB_NAME, cron, schJob);
            Test.stopTest();
        }
    }
    
}