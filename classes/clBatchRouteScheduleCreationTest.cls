@IsTest
private class clBatchRouteScheduleCreationTest {


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
    static void test_exeBatch_cycleonly() {

        Test.startTest();

            Integer iNextCycle = 1;
            System.debug('---> running with cycle='+iNextCycle);
            clBatchRouteScheduleCreation b = new clBatchRouteScheduleCreation(iNextCycle);
            Database.executeBatch(b,50);

        Test.stopTest();
    }

    @IsTest
    static void test_exeBatch_cycle_and_region() {

        Test.startTest();

        String region = 'Tinley Park';

        DELETE [SELECT Id FROM Route__c];
        DELETE [SELECT Id FROM Route_Schedule__c];

        Route__c tinleyRoute = new Route__c();
        tinleyRoute.Processing_Location__c = region;
        tinleyRoute.Name = 'Blah Tinley 1';
        tinleyRoute.Cycle_Number__c = 1;
        insert tinleyRoute;

        Account account = [SELECT Id FROM Account lIMIT 1];
        Route_Account__c ra = new Route_Account__c();
        ra.Route__c = tinleyRoute.Id;
        ra.Account__c = account.Id;
        insert ra;

        Integer iNextCycle = 1;
        System.debug('---> running with cycle='+iNextCycle);
        clBatchRouteScheduleCreation b = new clBatchRouteScheduleCreation(iNextCycle,region);
        Database.executeBatch(b,50);

        Test.stopTest();

        List<Route_Schedule__c> routeSchedules = [
                SELECT Id,Processing_Location__c
                FROM   Route_Schedule__c
        ];
        System.assert(!routeSchedules.isEmpty());
        for(Route_Schedule__c rs : routeSchedules) {
            System.assert(rs.Processing_Location__c == region);
        }


    }

    @IsTest
    static void test_exeBatch_chain() {

        Test.startTest();
        Integer iNextCycle = 1;
        clBatchRouteScheduleCreation b = new clBatchRouteScheduleCreation(iNextCycle,true);
        Database.executeBatch(b,50);

        Test.stopTest();
    }

    @IsTest
    static void test_exeBatch_chain_with_batchsize() {

        Test.startTest();
        Integer iNextCycle = 1;
        clBatchRouteScheduleCreation b = new clBatchRouteScheduleCreation(iNextCycle,true,50);
        Database.executeBatch(b,50);

        Test.stopTest();
    }

    @IsTest
    static void test_exeBatch_chain_with_batchsize_and_collectiondate_and_filldate() {

        Test.startTest();
        Integer iNextCycle = 1;
        Date  routeCollectionDate = Date.today().addDays(1);
        Date  routeFillDate = Date.today();
        clBatchRouteScheduleCreation b = new clBatchRouteScheduleCreation(iNextCycle,true,50,routeCollectionDate,routeFillDate);
        Database.executeBatch(b,50);

        Test.stopTest();
    }


    @IsTest
    static void test_fire_failed_PE() {

        Test.startTest();
        clBatchRouteScheduleCreation b = new clBatchRouteScheduleCreation(1);
        b.fireFailurePlatformEvent();
        Test.stopTest();
    }
}