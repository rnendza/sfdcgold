@IsTest
private class Accel_MeterReadingTriggerTest {
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
    static void test_delete_meter_readings() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];
        Cash_Logistics_Automation_Setting__mdt mdt = clAutomationSvc.retrieveAutomationSetting(clAutomationSvc.MR_TRIGGER_PREVENT_DELETE);

        Test.startTest();

        DmlException dmlEx;
        try {
            delete meterReadings;
        } catch (DmlException ex) {
            dmlEx = ex;
        }
        if(mdt.Prevent_Record_Delete__c) {
            System.assert(dmlEx != null);
        } else {
            System.assert(dmlEx == null);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_modifyReadingStatus() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        Test.startTest();

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Current_Lifetime_Cash_In__c = 1;
        }
        update meterReadings;

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Current_Lifetime_Cash_In__c = 0;
        }
        update meterReadings;

        Test.stopTest();
    }

    @IsTest
    static void test_modifyCannotCollect() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Cannot_Collect__c,Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        Test.startTest();

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Cannot_Collect__c = true;
        }
        update meterReadings;

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Cannot_Collect__c = false;
        }
        update meterReadings;

        Test.stopTest();
    }

    @IsTest
    static void test_modifyProcessingStatus() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Actual_Drop__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        Test.startTest();

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Actual_Drop__c = 1;
        }
        update meterReadings;

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Actual_Drop__c = 0;
        }
        update meterReadings;

        Test.stopTest();
    }

    /**
     * UT Case for Actual Drop of Zero
     * @see https://accel-entertainment.monday.com/boards/942883797/pulses/3235121723?asset_id=605436499
     */
    @IsTest
    static void test_modifyProcessingStatus_onezero_meter_reading() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Actual_Drop__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        //  Assume proper rt info was entered.
        //  ie. artificially modify for this specific unit test as we don't have a ui.. (not a SIT test)
        rps.Processor_RT_Status__c = 'Complete';
        update rps;

        Test.startTest();

        Integer iNumMeterReadings = meterReadings.size();
        Integer i = 1;
        for(Meter_Reading__c meterReading : meterReadings) {
            if(i < iNumMeterReadings) {
                meterReading.Actual_Drop__c = 1;
            } else {
                meterReading.Actual_Drop__c = 0;
            }
            i++;
        }
        update meterReadings;

        Test.stopTest();

        rps = [
                SELECT  Id,Processing_Process_Status__c,Redemption_Terminal_Status__c
                FROM Route_Processing_Sheet__c
                WHERE Id = :rps.Id LIMIT 1
        ];
        //  (3)  Ensure all the rollups and everything else set the RPS.Processing_Process_Status__c to COMPLETED PROCESSING.
        System.assertEquals(rps.Processing_Process_Status__c,'COMPLETED PROCESSING');


    }

    @IsTest
    static void test_prevMeterReadings() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        Test.startTest();
        //  Just add 1 meter reading to fire the trigger / queueable again (after the ones initially created in the setup method)
        Meter_Reading__c mr = new Meter_Reading__c(
                Route_Processing_Sheet__c = rps.Id,
                Asset__c = meterReadings[0].Asset__c,
                Current_Lifetime_Cash_In__c = 12313
        );
        insert mr;
        Test.stopTest();

        Meter_Reading__c updatedMr = [
                SELECT   Id, Previous_Meter_Reading__c
                FROM     Meter_Reading__c
                WHERE    Id = :mr.Id
        ];
        System.assert(updatedMr.Previous_Meter_Reading__c != null);
    }

    @IsTest
    static void test_modifyProcessingStatus_Cannot_Collect_Checked() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [
                SELECT  Id,Processor_RT_Status__c,Redemption_Terminal_Status__c
                FROM Route_Processing_Sheet__c
                WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1
        ];
        List<Meter_Reading__c> meterReadings = [
                SELECT Id, Actual_Drop__c,Reading_Status__c
                FROM Meter_Reading__c
                WHERE Route_Processing_Sheet__c = :rps.Id
        ];

        Test.startTest();
        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Cannot_Collect__c = TRUE;
        }
        update meterReadings;

        Test.stopTest();

        meterReadings = [
                SELECT Id, Actual_Drop__c,Reading_Status__c,Processing_Status__c
                FROM Meter_Reading__c
                WHERE Route_Processing_Sheet__c = :rps.Id
        ];

        //  (1) Ensure Meter Reading collection status is Cannot Collect
        for(Meter_Reading__c meterReading : meterReadings) {
            System.assertEquals(meterReading.Reading_Status__c, MeterReadingTriggerHandler.CANNOT_COLLECT_STATUS);
        }
        //  (2) Ensure Meter Reading processing status is completed
        for(Meter_Reading__c meterReading : meterReadings) {
            System.assertEquals(meterReading.Processing_Status__c, MeterReadingTriggerHandler.COMPLETED_STATUS);
        }

        //     (2a) assume proper rt info was entered.
        //          ie. artificially modify for this specific unit test as we don't have a ui.. (not a SIT test)
        rps.Processor_RT_Status__c = 'Complete';
        update rps;
        rps = [
                SELECT  Id,Processing_Process_Status__c,Redemption_Terminal_Status__c
                FROM Route_Processing_Sheet__c
                WHERE Id = :rps.Id LIMIT 1
        ];
        //  (3)  Ensure all the rollups and everything else set the RPS.Processing_Process_Status__c to COMPLETED PROCESSING.
        System.assertEquals(rps.Processing_Process_Status__c,'COMPLETED PROCESSING');

    }
}