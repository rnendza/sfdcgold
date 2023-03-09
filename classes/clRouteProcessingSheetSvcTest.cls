@IsTest
private class clRouteProcessingSheetSvcTest {

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
    static void test_retrieveRouteProcessingSheet() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Route_Processing_Sheet__c testRps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
            System.assertEquals(testRps.Id,rps.Id);
        }

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveRouteProcessingSheet_collector3() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id,Assigned_Driver__c,User__c,Collector_1__c,Collector_3__c FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        routeSchedule.Assigned_Driver__c = null;
        routeSchedule.User__c = null;
        routeSchedule.Collector_1__c = null;
        routeSchedule.Collector_3__c = collector.Id;
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Route_Processing_Sheet__c testRps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
            System.assertEquals(testRps.Id,rps.Id);
        }

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveRouteProcessingSheets() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            List<Route_Processing_Sheet__c> rpss = clRouteProcessingSheetSvc.retrieveRouteProcessingSheets(collector.Id,tomorrow);
            System.assertEquals(rpss.isEmpty(),false);
            rpss = clRouteProcessingSheetSvc.retrieveRouteProcessingSheets(routeSchedule.Id);
            System.assertEquals(rpss.isEmpty(),false);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllRouteProcessingSheets() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            List<Route_Processing_Sheet__c> rpss = clRouteProcessingSheetSvc.retrieveAllRouteProcessingSheets();
            System.assertEquals(rpss.isEmpty(),false);
        }

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveRouteProcessingSheetsForProcessor() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            List<Route_Processing_Sheet__c> rpss = clRouteProcessingSheetSvc.retrieveRouteProcessingSheetsForProcessor(null,processor.Id,routeSchedule.Id,tomorrow);
            System.assertEquals(rpss.isEmpty(),false);
        }

        Test.stopTest();
    }


    @IsTest
    static void test_deleteScheduleRpsAndMeterRecords() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            try {
                //@todo check custom mdt for delete access!
                Map<String, Object> m = clRouteProcessingSheetSvc.deleteScheduleRpsAndMeterRecords(routeSchedule.Id);
                //System.assertEquals(((List<Meter_Reading__c>) m.get('DELETED_METER_RECS')).isEmpty(), false);
                //System.assertEquals(((List<Route_Processing_Sheet__c>) m.get('DELETED_RPS_RECS')).isEmpty(), false);
            } catch (Exception e ) {
                System.debug(LoggingLevel.ERROR,e);
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void test_deleteScheduleMeterRecords() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            try {
                List<Meter_Reading__c> meterReadings = clRouteProcessingSheetSvc.deleteScheduleMeterRecords(routeSchedule.Id);
                System.assertEquals(meterReadings.isEmpty(), false);
            }catch (Exception e) {
                //@todo assert
            }
        }

        Test.stopTest();
    }
}