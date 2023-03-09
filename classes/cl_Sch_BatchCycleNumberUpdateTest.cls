@IsTest
private class cl_Sch_BatchCycleNumberUpdateTest {

    @IsTest
    static void test_exeSchedule_positive() {

        Test.startTest();

        cl_Sch_BatchCycleNumberUpdate schJob = new cl_Sch_BatchCycleNumberUpdate();
        String cron = '0 0 23 * * ?';
        Id jobId = system.schedule('jobName', cron, schJob);
        System.assert(jobId != null);

        Test.stopTest();
    }

}