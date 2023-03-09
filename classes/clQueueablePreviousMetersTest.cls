@IsTest
private class clQueueablePreviousMetersTest {

    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }
    @IsTest
    static void test_prevMeterReadings_success() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        //  Just add 1 meter reading to fire the trigger / queueable again (after the ones initially created in the setup method)
        Meter_Reading__c mr = new Meter_Reading__c(
                Route_Processing_Sheet__c = rps.Id,
                Asset__c = meterReadings[0].Asset__c,
                Current_Lifetime_Cash_In__c = 12313
        );
        insert mr; // fires the queueable from the trigger but let's negate that run.
        mr.Previous_Meter_Reading__c = null;
        update mr;

        Test.startTest();
        clQueueablePreviousMeters q = new clQueueablePreviousMeters(new Map<Id,Meter_Reading__c> { mr.Id => mr});
        Id jobId = System.enqueueJob(q);
        Test.stopTest();

        Meter_Reading__c updatedMr = [
                SELECT   Id, Previous_Meter_Reading__c
                FROM     Meter_Reading__c
                WHERE    Id = :mr.Id
        ];
        System.assert(updatedMr.Previous_Meter_Reading__c != null);
        Accel_Application_Error__c log = [
                SELECT Id
                FROM   Accel_Application_Error__c
                WHERE  Initiating_Job_Id__c = :jobId
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }
    @IsTest
    static void test_prevMeterReadings_missing_asset() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        //  Just add 1 meter reading to fire the trigger / queueable again (after the ones initially created in the setup method)
        Meter_Reading__c mr = new Meter_Reading__c(
                Route_Processing_Sheet__c = rps.Id,
                Asset__c = meterReadings[0].Asset__c,
                Current_Lifetime_Cash_In__c = 12313
        );
        insert mr; // fires the queueable from the trigger but let's negate that run.
        mr.Previous_Meter_Reading__c = null;
        mr.Asset__c = null;
        update mr;

        Test.startTest();
        clQueueablePreviousMeters q = new clQueueablePreviousMeters(new Map<Id,Meter_Reading__c> { mr.Id => mr});
        Id jobId = System.enqueueJob(q);
        Test.stopTest();

        Meter_Reading__c updatedMr = [
                SELECT   Id, Previous_Meter_Reading__c
                FROM     Meter_Reading__c
                WHERE    Id = :mr.Id
        ];
        System.assert(updatedMr.Previous_Meter_Reading__c == null);
    }
    @IsTest
    static void test_prevMeterReadings_all_errors_on_update() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        //  Just add 1 meter reading to fire the trigger / queueable again (after the ones initially created in the setup method)
        Meter_Reading__c mr = new Meter_Reading__c(
                Route_Processing_Sheet__c = rps.Id,
                Asset__c = meterReadings[0].Asset__c,
                Current_Lifetime_Cash_In__c = 12313
        );
        insert mr; // fires the queueable from the trigger but let's negate that run.
        mr.Previous_Meter_Reading__c = null;
        update mr;

        Test.startTest();
        clQueueablePreviousMeters.FORCE_PARTIAL_DML_EXCEPTION = TRUE;
        clQueueablePreviousMeters q = new clQueueablePreviousMeters(new Map<Id,Meter_Reading__c> { mr.Id => mr});
        Id jobId = System.enqueueJob(q);
        Test.stopTest();

        Meter_Reading__c updatedMr = [
                SELECT   Id, Previous_Meter_Reading__c
                FROM     Meter_Reading__c
                WHERE    Id = :mr.Id
        ];
        System.assert(updatedMr.Previous_Meter_Reading__c == null);

        Accel_Application_Error__c log = [
                SELECT Id
                FROM   Accel_Application_Error__c
                WHERE  Initiating_Job_Id__c = :jobId
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_FAILED);
    }

    @IsTest
    static void test_prevMeterReadings_exception_on_update() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        //  Just add 1 meter reading to fire the trigger / queueable again (after the ones initially created in the setup method)
        Meter_Reading__c mr = new Meter_Reading__c(
                Route_Processing_Sheet__c = rps.Id,
                Asset__c = meterReadings[0].Asset__c,
                Current_Lifetime_Cash_In__c = 12313
        );
        insert mr; // fires the queueable from the trigger but let's negate that run.
        mr.Previous_Meter_Reading__c = null;
        update mr;

        Test.startTest();
        clQueueablePreviousMeters.FORCE_FULL_EXCEPTION = TRUE;
        clQueueablePreviousMeters q = new clQueueablePreviousMeters(new Map<Id,Meter_Reading__c> { mr.Id => mr});
        Id jobId = System.enqueueJob(q);
        Test.stopTest();

        Meter_Reading__c updatedMr = [
                SELECT   Id, Previous_Meter_Reading__c
                FROM     Meter_Reading__c
                WHERE    Id = :mr.Id
        ];
//        System.assert(updatedMr.Previous_Meter_Reading__c == null);
//
//        Accel_Application_Error__c log = [
//                SELECT Id
//                FROM   Accel_Application_Error__c
//                WHERE  Initiating_Job_Id__c = :jobId
//        ];
//        log = AppLogSvc.retrieveLog(log.Id);
//        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_FAILED);
    }

    @IsTest
    static void test_prevMeterReadings_partial_success_update() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        //  Just add 2 new meter readings to fire the trigger / queueable again (after the ones initially created in the setup method)
        List<Meter_Reading__c> newMeterReadings = new List<Meter_Reading__c>();
        newMeterReadings.add(new Meter_Reading__c(
                Route_Processing_Sheet__c = rps.Id,
                Asset__c = meterReadings[0].Asset__c,
                Current_Lifetime_Cash_In__c = 1111
        ));
        newMeterReadings.add(new Meter_Reading__c(
                Route_Processing_Sheet__c = rps.Id,
                Asset__c = meterReadings[0].Asset__c,
                Current_Lifetime_Cash_In__c = 2222
        ));
        insert  newMeterReadings; // fires the queueable from the trigger but let's negate that run.
        for(Meter_Reading__c mr : newMeterReadings) {
            mr.Previous_Meter_Reading__c = null;
        }
        update newMeterReadings;

        Test.startTest();
        clQueueablePreviousMeters.FORCE_PARTIAL_DML_EXCEPTION = TRUE;
        clQueueablePreviousMeters q = new clQueueablePreviousMeters(new Map<Id,Meter_Reading__c>(newMeterReadings));
        Id jobId = System.enqueueJob(q);
        Test.stopTest();

        List<Meter_Reading__c> updatedMrs = [
                SELECT   Id, Previous_Meter_Reading__c
                FROM     Meter_Reading__c
                WHERE    Id = :newMeterReadings
        ];
        // TEST Error forced on first MR only
        Integer iNumFailed = 0;
        for(Meter_Reading__c newMr : updatedMrs) {
            if(newMr.Previous_Meter_Reading__c == null) {
                iNumFailed++;
            }
        }
        System.assert(iNumFailed == 1);
    }
}