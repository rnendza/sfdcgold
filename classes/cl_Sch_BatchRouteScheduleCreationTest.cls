@IsTest
private class cl_Sch_BatchRouteScheduleCreationTest {

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
    static void test_exeSchedule_positive_region_arg() {

        DELETE [SELECT Id FROM Route__c];
        DELETE [SELECT Id FROM Route_Schedule__c];

        Route__c tinleyRoute = new Route__c();
        tinleyRoute.Processing_Location__c = 'Tinley Park';
        tinleyRoute.Name = 'Blah Tinley 1';
        tinleyRoute.Cycle_Number__c = 1;
        insert tinleyRoute;

        Account account = [SELECT Id FROM Account lIMIT 1];
        Route_Account__c ra = new Route_Account__c();
        ra.Route__c = tinleyRoute.Id;
        ra.Account__c = account.Id;
        insert ra;

        Test.startTest();
        String region = 'Tinley Park';
        cl_Sch_BatchRouteScheduleCreation schJob = new cl_Sch_BatchRouteScheduleCreation(region);
        String cron = '0 0 23 * * ?';
        Id jobId = system.schedule('jobName', cron, schJob);
        System.assert(jobId != null);
        Test.stopTest();

    }

    @IsTest
    static void test_exeSchedule_positive_no_args() {

        Test.startTest();

        cl_Sch_BatchRouteScheduleCreation schJob = new cl_Sch_BatchRouteScheduleCreation();
        String cron = '0 0 23 * * ?';
        Id jobId = system.schedule('jobName', cron, schJob);
        System.assert(jobId != null);

        Test.stopTest();
    }
}