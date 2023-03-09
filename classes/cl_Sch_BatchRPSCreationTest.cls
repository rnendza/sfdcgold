@IsTest
private class cl_Sch_BatchRPSCreationTest {
    /**
     * NOTE start / stop test merely there to reset gov limits as creating non cl data takes forever given
     * all the processors / flows and eventually will bust cpu time outs on it's own.
     */
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_exeSchedule_positive() {

        Test.startTest();

        cl_Sch_BatchRouteProcessingSheetCreation schJob = new cl_Sch_BatchRouteProcessingSheetCreation();
        String cron = '0 0 23 * * ?';
        Id jobId = system.schedule('jobName', cron, schJob);
        System.assert(jobId != null);

        Test.stopTest();
    }
}