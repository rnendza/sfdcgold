@IsTest
private class Accel_RPSTriggerTest {
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

        List<Route_Schedule__c> routeSchedules = [
                SELECT Id,Name,(Select Id, Name,Account__r.Name,Account__c FROM Route_Schedule_Accounts__r)
                       ,(Select Id,Route_Schedule__r.Name,Name,Account__c,Account__r.Name FROM Route_Processing_Sheets__r)
                FROM   Route_Schedule__c
        ];
        for(Route_Schedule__c rs: routeSchedules) {
            System.debug('-----> rs='+rs.Name + '__'+rs.Id);
            List<Route_Schedule_Account__c> accts = rs.Route_Schedule_Accounts__r;
            List<Route_Processing_Sheet__c> rpss = rs.Route_Processing_Sheets__r;
            for(Route_Schedule_Account__c acct : accts) {
                System.debug('--> acct='+acct.Account__r.Name +'__'+acct.Account__c);
            }
            for(Route_Processing_Sheet__c rps : rpss) {
                System.debug('rps='+rps.Name +'.. rsName='+rps.Route_Schedule__r.Name+'.. acctname='+rps.Account__r.Name);
            }
        }

//        Map<Id,Id> mNewAccountId_RpsId = new Map<Id,Id>();
//        Map<Id,clQueueablePreviousRps.PreviousCollectionType> mUpdateRpsId_prevRps = new Map<Id,clQueueablePreviousRps.PreviousCollectionType>();
//
//        for(Route_Processing_Sheet__c rpsNew : mRps.values()) {
//            mNewAccountId_RpsId.put(rpsNew.Account__c,rpsNew.Id);
//        }

        List<Route_Processing_Sheet__c> rps = [SELECT Id, Previous_RT_Collection__c,Previous_VGT_Collection__c FROM Route_Processing_Sheet__c where Previous_VGT_Collection__c != null];
        System.debug('---->'+rps);
    }

    @IsTest
    static void test_rps_delete() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processing_Status__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        Cash_Logistics_Automation_Setting__mdt mdt = clAutomationSvc.retrieveAutomationSetting(clAutomationSvc.RPS_TRIGGER_PREVENT_DELETE);

        Test.startTest();
        DmlException dmlEx;
        try {
            delete rps;
        } catch (DmlException ex) {
            dmlEx = ex;
        }
        if(mdt.Prevent_Record_Delete__c) {
            //System.assert(dmlEx != null);
        } else {
            //System.assert(dmlEx == null);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_updateProcessorFillStatus() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processing_Status__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        rps.Processing_Status__c = 'COMPLETED FILL';
        update rps;

        Test.stopTest();
    }

    @IsTest
    static void test_collection_status_completed_NRT_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        Route_Schedule_Account__c rsa = [SELECT Id,Redemption_Type_From_Asset__c FROM Route_Schedule_Account__c WHERE Id = :rps.Route_Schedule_Account__c];
        rsa.Redemption_Type_From_Asset__c = 'NRT';
        update rsa;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.debug('--> REDEMPTION TYPE FROM ASSET='+rps.Redemption_Type_From_Asset__c);

        List<Meter_Reading__c> mrs = [
                SELECT Id,Current_Lifetime_Cash_In__c, Reading_Status__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        for(Meter_Reading__c mr : mrs) {
            mr.Current_Lifetime_Cash_In__c = 1;
        }
        System.debug('--> calling update on child meters');
        update mrs;

        rps.Cassette_1_Note_Count__c = 1;
        rps.Cassette_2_Note_Count__c = 1;
        rps.Cassette_3_Note_Count__c = 1;
        rps.Cassette_4_Note_Count__c = 1;
        rps.BV_Value__c = 1;
        System.debug('---> calling update on rps rt fields');
        update rps;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals(clRPSTriggerHandler.RPS_COLLECTION_STATUS_COMPLETE,rps.Status__c);

        Test.stopTest();
    }
    @IsTest
    static void test_collection_status_completed_add_fill_vgt_only_positivie() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        rps.Collection_Type__c = 'Additional Fill – VGT Only';
        update rps;
        Route_Schedule_Account__c rsa = [SELECT Id,Redemption_Type_From_Asset__c FROM Route_Schedule_Account__c WHERE Id = :rps.Route_Schedule_Account__c];
        rsa.Redemption_Type_From_Asset__c = 'NRT';
        update rsa;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);

        List<Meter_Reading__c> mrs = [
                SELECT Id,Current_Lifetime_Cash_In__c, Reading_Status__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        for(Meter_Reading__c mr : mrs) {
            mr.Current_Lifetime_Cash_In__c = 1;
        }
        System.debug('--> calling update on child meters');
        update mrs;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals(clRPSTriggerHandler.RPS_COLLECTION_STATUS_COMPLETE,rps.Status__c);

        Test.stopTest();
    }

    @IsTest
    static void test_collection_status_completed_regular_vgt_only_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        rps.Collection_Type__c = 'Regular - VGT Only';
        update rps;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);

        List<Meter_Reading__c> mrs = [
                SELECT Id,Current_Lifetime_Cash_In__c, Reading_Status__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        for(Meter_Reading__c mr : mrs) {
            mr.Current_Lifetime_Cash_In__c = 1;
        }
        System.debug('--> calling update on child meters');
        update mrs;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals(clRPSTriggerHandler.RPS_COLLECTION_STATUS_COMPLETE,rps.Status__c);

        Test.stopTest();
    }

    @IsTest
    static void test_processing_status_completed_regular_vgt_only_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        rps.Collection_Type__c = 'Regular - VGT Only';
        update rps;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);

        List<Meter_Reading__c> mrs = [
                SELECT Id,Current_Lifetime_Cash_In__c, Reading_Status__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        for(Meter_Reading__c mr : mrs) {
            mr.Current_Lifetime_Cash_In__c = 1;
            mr.Processing_Status__c = 'Completed';
            mr.Reading_Status__c = 'Completed';
        }
        System.debug('--> calling update on child meters');
        update mrs;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals('COMPLETED PROCESSING',rps.Processing_Process_Status__c);

        Test.stopTest();
    }

    @IsTest
    static void test_processing_status_completed_regular_rt_only_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        rps.Collection_Type__c = 'Regular - RT Only';
        update rps;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);

        rps.Enter_Total_Drop__c = 1;
        rps.Cassette_1_Note_Count_Drop__c = 1;
        rps.Cassette_5_Note_Count_Drop__c = 1;
        rps.Cassette_20_Note_Count_Drop__c = 1;
        rps.Cassette_50_Note_Count_Drop__c = 1;
        rps.Cassette_100_Note_Count_Drop__c = 1;
        rps.Reject_Drop_Total__c = 1;
        rps.Processor_RT_Status__c = 'Complete';




        update rps;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals('COMPLETED PROCESSING',rps.Processing_Process_Status__c);

        Test.stopTest();
    }
    @IsTest
    static void test_processing_status_completed_addition_fill_rt_only_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        rps.Collection_Type__c = 'Additional Fill – RT Only';
        update rps;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);

        rps.Enter_Total_Drop__c = 1;
        rps.Cassette_1_Note_Count_Drop__c = 1;
        rps.Cassette_5_Note_Count_Drop__c = 1;
        rps.Cassette_20_Note_Count_Drop__c = 1;
        rps.Cassette_50_Note_Count_Drop__c = 1;
        rps.Cassette_100_Note_Count_Drop__c = 1;
        rps.Reject_Drop_Total__c = 1;
        rps.Processor_RT_Status__c = 'Complete';
        update rps;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals('COMPLETED PROCESSING',rps.Processing_Process_Status__c);

        Test.stopTest();
    }

    @IsTest
    static void test_processing_status_processingincomplete_addition_fill_rt_only_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        rps.Collection_Type__c = 'Additional Fill – RT Only';
        update rps;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals('Processing Incomplete',rps.Processing_Process_Status__c);

        Test.stopTest();
    }

    @IsTest
    static void test_collection_status_completed_M3T_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Schedule_Account__c,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        Route_Schedule_Account__c rsa = [SELECT Id,Redemption_Type_From_Asset__c FROM Route_Schedule_Account__c WHERE Id = :rps.Route_Schedule_Account__c];
        rsa.Redemption_Type_From_Asset__c = 'M3T';
        update rsa;

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.debug('--> REDEMPTION TYPE FROM ASSET='+rps.Redemption_Type_From_Asset__c);

        List<Meter_Reading__c> mrs = [
                SELECT Id,Current_Lifetime_Cash_In__c, Reading_Status__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        for(Meter_Reading__c mr : mrs) {
            mr.Current_Lifetime_Cash_In__c = 1;
        }
        System.debug('--> calling update on child meters');
        update mrs;

        rps.Cassette_1_Value__c = 1;
        rps.Cassette_2_Value__c = 2;
        rps.Cassette_3_Value__c = 3;
        rps.Cassette_4_Value__c = 4;
        rps.Cassette_5_Value__c = 5;

        System.debug('---> calling update on rps rt fields');
        update rps;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals(clRPSTriggerHandler.RPS_COLLECTION_STATUS_COMPLETE,rps.Status__c);

        Test.stopTest();
    }
    @IsTest
    static void test_collection_status_rts_incomplete() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processing_Status__c,Redemption_Type_From_Asset__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.debug('--> REDEMPTION TYPE FROM ASSET='+rps.Redemption_Type_From_Asset__c);

        List<Meter_Reading__c> mrs = [
                SELECT Id,Current_Lifetime_Cash_In__c, Reading_Status__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        for(Meter_Reading__c mr : mrs) {
            mr.Current_Lifetime_Cash_In__c = 1;
        }
        System.debug('--> calling update on child meters');
        update mrs;

        if(rps.Redemption_Type_From_Asset__c == 'NRT') {
            rps.Cassette_1_Note_Count__c = 1;
            rps.Cassette_2_Note_Count__c = 1;

//            rps.Cassette_3_Note_Count__c = 1;
//            rps.Cassette_4_Note_Count__c = 1;
//            rps.BV_Value__c = 1;
        } else if (rps.Redemption_Type_From_Asset__c == 'M3T') {
            rps.Cassette_1_Value__c = 1;
            rps.Cassette_2_Value__c = 2;
//            rps.Cassette_3_Value__c = 3;
//            rps.Cassette_4_Value__c = 4;
//            rps.Cassette_5_Value__c = 5;
        }
        System.debug('---> calling update on rps rt fields');
        update  rps;

        Test.startTest();

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assertEquals(clRPSTriggerHandler.RPS_COLLECTION_STATUS_IN_PROGRESS,rps.Status__c);

        Test.stopTest();

    }


    @IsTest
    static void test_updateCollectionStatusToSkipped() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processing_Status__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        rps.Status__c = clRPSTriggerHandler.RPS_COLLECTION_STATUS_SKIPPED;
        update rps;

        Test.stopTest();

        List<Meter_Reading__c> mrs = [SELECT Id, Cannot_Collect__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];
        // (1)  check that meters were auto set to Cannot Collect.
        for(Meter_Reading__c mr : mrs) {
            System.assertEquals(mr.Cannot_Collect__c,TRUE);
        }
        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        // (2)  check that the collection status was set to 'Skipped'
        System.assertEquals(clRPSTriggerHandler.RPS_COLLECTION_STATUS_SKIPPED,rps.Status__c);
        // (3)  check that the processing status was set to 'COMPLETED PROCESSING'
        System.assertEquals('COMPLETED PROCESSING',rps.Processing_Process_Status__c);
    }

    @IsTest
    static void test_updateProcessorProcessStatus() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        Test.startTest();

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Current_Lifetime_Cash_In__c = 1;
            meterReading.Processing_Status__c = 'Completed';
            meterReading.Reading_Status__c = 'Completed';
        }
        update meterReadings;

        rps.Processor_RT_Status__c = 'Complete';
        update rps;

        Test.stopTest();
    }


    @IsTest
    static void test_updateCollectorStatus() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,BV_Value__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        Test.startTest();

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Current_Lifetime_Cash_In__c = 1;
            meterReading.Snapshot__c = 'http://www.google.com';
        }
        update meterReadings;

        rps.BV_Value__c = 1;
        update rps;

        Test.stopTest();
    }

    @IsTest
    static void test_notes_update() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,BV_Value__c,Notes__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];

        Test.startTest();
        rps.Notes__c = '';
        for(Integer i=0; i<257;i++) {
            rps.Notes__c +=i;
        }
        update rps;

        Test.stopTest();
    }

//    @IsTest
//    static void test_prevRps() {
//
//        Route__c route = [SELECT ID From Route__c LIMIT 1];
//        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
//        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
//
//
//        Test.startTest();
//        //  Just add 1 RPS reading to fire the trigger / queueable again (after the ones initially created in the setup method)
//        Route_Schedule_Account__c rsa = [SELECT Id,Account__c FROM Route_Schedule_Account__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
//        Route_Processing_Sheet__c rpsTmp = new Route_Processing_Sheet__c(
//                Route_Schedule__c = routeSchedule.Id,
//                Route_Schedule_Account__c = rsa.Id,
//                Account__c = rsa.Account__c,
//                Collection_Type__c = 'Regular - RT & VGT'
//        );
//        insert rpsTmp;
//        Test.stopTest();
//
//        Route_Processing_Sheet__c updatedRps = [
//                SELECT   Id, Previous_VGT_Collection__c
//                FROM     Route_Processing_Sheet__c
//                WHERE    Id = :rpsTmp.Id
//        ];
//        System.assert(updatedRps.Previous_VGT_Collection__c != null);
//    }
//
//    @IsTest
//    static void test_prevRps_Single() {
//
//        Route__c route = [SELECT ID From Route__c LIMIT 1];
//        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
//        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
//
//
//        Test.startTest();
//        //  Just add 1 RPS reading to fire the trigger / queueable again (after the ones initially created in the setup method)
//        Route_Schedule_Account__c rsa = [SELECT Id,Account__c FROM Route_Schedule_Account__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
//        Route_Processing_Sheet__c rpsTmp = new Route_Processing_Sheet__c(
//                Route_Schedule__c = routeSchedule.Id,
//                Route_Schedule_Account__c = rsa.Id,
//                Account__c = rsa.Account__c,
//                Collection_Type__c = 'Regular - RT & VGT'
//        );
//        insert rpsTmp;
//        Test.stopTest();
//
//        Route_Processing_Sheet__c updatedRps = [
//                SELECT   Id, Previous_VGT_Collection__c
//                FROM     Route_Processing_Sheet__c
//                WHERE    Id = :rpsTmp.Id
//        ];
//        System.assert(updatedRps.Previous_VGT_Collection__c != null);
//    }
}