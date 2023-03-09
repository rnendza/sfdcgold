/**
 * Created by ricknendza on 1/31/22.
 */
@IsTest
private class clBatchPreviousMetersTest {
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }


    @IsTest
    static void test_prevMeterReadings_0args_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;


        Test.startTest();

        clBatchPreviousMeters b = new clBatchPreviousMeters();
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
            } else {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }
        Accel_Application_Error__c log = [
                SELECT Id,Name,Job_Name__c,JobType__c,Initiating_Job_Id__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }

    @IsTest
    static void test_prevMeterReadings_custom_soql_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;

        String region = 'Burr Ridge';
        String createdByName = UserInfo.getName();
        Datetime createdDateStart = Date.today().addDays(-1);
        Datetime createdDateEnd = Date.today().addDays(2);
        String sCreatedDateStart, sCreatedDateEnd;

        sCreatedDateStart = createdDateStart.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        sCreatedDateEnd =  createdDateEnd.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');

        String soql = '';
        soql += ' SELECT asset__c, id, Previous_Meter_Reading__c, createddate ';
        soql += ' FROM   meter_reading__c ';
        soql += ' WHERE  ( route_processing_sheet__r.processing_location__c = \''+region+'\' and asset__c != null and Cannot_Collect__c != true) ';
        soql += '         or (createddate>='+sCreatedDateStart+' and createddate<'+sCreatedDateEnd;
        soql += '              and createdby.name = \''+createdByName+'\')  ';
        soql += ' ORDER BY asset__c, createddate desc ';

        Test.startTest();
        System.debug('test soql: '+ soql);
        clBatchPreviousMeters b = new clBatchPreviousMeters(soql, 200);
        Id jobId = Database.executeBatch(b,200);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
               // System.debug('asset prev meter1='+assetMeter.Previous_Meter_Reading__c);
//                System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
            } else {
              //  System.debug('asset prev meter2='+assetMeter.Previous_Meter_Reading__c);
//                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }
        Accel_Application_Error__c log = [
                SELECT Id,Name,Job_Name__c,JobType__c,Initiating_Job_Id__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }

    @IsTest
    static void test_prevMeterReadings_2args_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;


        Test.startTest();

        clBatchPreviousMeters b = new clBatchPreviousMeters(clBatchPreviousMeters.DEFAULT_BATCH_SIZE,clBatchPreviousMeters.DEFAULT_COMMIT);
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
            } else {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }
        Accel_Application_Error__c log = [
                SELECT Id,Name,Job_Name__c,JobType__c,Initiating_Job_Id__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }

    @IsTest
    static void test_prevMeterReadings_assetId_filter_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;


        Test.startTest();

        clBatchPreviousMeters b = new clBatchPreviousMeters(new Set<Id> {asset.Id});
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
            } else {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }
        Accel_Application_Error__c log = [
                SELECT Id,Name,Job_Name__c,JobType__c,Initiating_Job_Id__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }

    @IsTest
    static void test_prevMeterReadings_accountId_filter_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Account account = [
                SELECT Id
                FROM   Account
                WHERE  Id IN (SELECT Account__c FROM Route_Processing_Sheet__c)
                LIMIT 1
        ];
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                AND    AccountId = :account.Id
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                AND    Route_Processing_Sheet__r.Account__c = :account.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;


        Test.startTest();

        clBatchPreviousMeters b = new clBatchPreviousMeters(new List<Id> {account.Id});
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                AND    Route_Processing_Sheet__r.Account__c = :account.Id
                ORDER  By CreatedDate DESC
        ];
//        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
//        for(Meter_Reading__c assetMeter : assetMeters) {
//            if(i < iTotalMeters) {
//                System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
//            } else {
//                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
//            }
//            i++;
//        }
        Accel_Application_Error__c log = [
                SELECT Id,Name,Job_Name__c,JobType__c,Initiating_Job_Id__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }

    @IsTest
    static void test_prevMeterReadings_startdate_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;


        Test.startTest();

        clBatchPreviousMeters b = new clBatchPreviousMeters(clBatchPreviousMeters.DEFAULT_BATCH_SIZE,clBatchPreviousMeters.DEFAULT_COMMIT,Date.today().addDays(-1));
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
            } else {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }
        Accel_Application_Error__c log = [
                SELECT Id,Name,Job_Name__c,JobType__c,Initiating_Job_Id__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }

    @IsTest
    static void test_prevMeterReadings_startenddate_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;


        Test.startTest();

        clBatchPreviousMeters b = new clBatchPreviousMeters(clBatchPreviousMeters.DEFAULT_BATCH_SIZE,
                                                            clBatchPreviousMeters.DEFAULT_COMMIT,
                                                            Date.today().addDays(-1),
                                                            Date.today().addDays(1));
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
                //System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
            } else {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }
        Accel_Application_Error__c log = [
                SELECT Id,Name,Job_Name__c,JobType__c,Initiating_Job_Id__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
    }

    @IsTest
    static void test_prevMeterReadings_missing_asset_success() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        assetMeters[0].Asset__c = null;
        Id meterIdWithoutAsset = assetMeters[0].clone(true).Id;
        update assetMeters;


        Test.startTest();

        clBatchPreviousMeters b = new clBatchPreviousMeters(clBatchPreviousMeters.DEFAULT_BATCH_SIZE,clBatchPreviousMeters.DEFAULT_COMMIT);
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,assetMeters[i+1].Id);
            } else {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }

        Accel_Application_Error__c log = [
                SELECT Id
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_SUCCESS);
        System.assert(log.Stack_Trace__c.contains(meterIdWithoutAsset));
    }

    @IsTest
    static void test_prevMeterReadings_partial_errors_on_update() {

        //  Clear out results of already inserted meters where prev meter was set in queueable (fired by trigger)
        Asset asset = [
                SELECT Id
                FROM   Asset
                WHERE  Id IN (SELECT Asset__c FROM Meter_Reading__c)
                LIMIT 1
        ];
        List<Meter_Reading__c> assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        for(Meter_Reading__c meterReading : assetMeters) {
            meterReading.Previous_Meter_Reading__c =null;
        }
        update assetMeters;


        Test.startTest();
        clBatchPreviousMeters.FORCE_PARTIAL_DML_EXCEPTION = true;
        clBatchPreviousMeters b = new clBatchPreviousMeters(clBatchPreviousMeters.DEFAULT_BATCH_SIZE,clBatchPreviousMeters.DEFAULT_COMMIT);
        Id jobId = Database.executeBatch(b,clBatchPreviousMeters.DEFAULT_BATCH_SIZE);

        Test.stopTest();

        assetMeters = [
                SELECT Id,Previous_Meter_Reading__c,CreatedDate,Cannot_Collect__c,Asset__c
                FROM   Meter_Reading__c
                WHERE  Asset__c = :asset.Id
                ORDER  By CreatedDate DESC
        ];
        Integer iTotalMeters = assetMeters.size() - 1, i = 0;
        for(Meter_Reading__c assetMeter : assetMeters) {
            if(i < iTotalMeters) {
                if(i == 0) {
                    System.assert(assetMeter.Previous_Meter_Reading__c == null);
                } else {
                    System.assertEquals(assetMeter.Previous_Meter_Reading__c, assetMeters[i + 1].Id);
                }
            } else {
                System.assertEquals(assetMeter.Previous_Meter_Reading__c,null);
            }
            i++;
        }
        Accel_Application_Error__c log = [
                SELECT Id
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchPreviousMeters'
        ];
        log = AppLogSvc.retrieveLog(log.Id);
        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_PARTIAL_SUCCESS);
    }

//    @IsTest
//    static void test_prevMeterReadings_all_errors_on_update() {
//
//        Route__c route = [SELECT ID From Route__c LIMIT 1];
//        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
//        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
//        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];
//
//        //  Just add 1 meter reading to fire the trigger / queueable again (after the ones initially created in the setup method)
//        Meter_Reading__c mr = new Meter_Reading__c(
//                Route_Processing_Sheet__c = rps.Id,
//                Asset__c = meterReadings[0].Asset__c,
//                Current_Lifetime_Cash_In__c = 12313
//        );
//        insert mr; // fires the queueable from the trigger but let's negate that run.
//        mr.Previous_Meter_Reading__c = null;
//        update mr;
//
//        Test.startTest();
//        clQueueablePreviousMeters.FORCE_PARTIAL_DML_EXCEPTION = TRUE;
//        clQueueablePreviousMeters q = new clQueueablePreviousMeters(new Map<Id,Meter_Reading__c> { mr.Id => mr});
//        Id jobId = System.enqueueJob(q);
//        Test.stopTest();
//
//        Meter_Reading__c updatedMr = [
//                SELECT   Id, Previous_Meter_Reading__c
//                FROM     Meter_Reading__c
//                WHERE    Id = :mr.Id
//        ];
//        System.assert(updatedMr.Previous_Meter_Reading__c == null);
//
//        Accel_Application_Error__c log = [
//                SELECT Id
//                FROM   Accel_Application_Error__c
//                WHERE  Initiating_Job_Id__c = :jobId
//        ];
//        log = AppLogSvc.retrieveLog(log.Id);
//        System.assertEquals(log.Overall_Job_Status__c,AppLogSvc.JOB_STATUS_FAILED);
//    }
//    @IsTest
//    static void test_prevMeterReadings_partial_success_update() {
//
//        Route__c route = [SELECT ID From Route__c LIMIT 1];
//        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
//        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
//        List<Meter_Reading__c> meterReadings = [SELECT Id, Collection_Date__c,Actual_Drop__c,Reading_Status__c,Asset__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];
//
//        //  Just add 2 new meter readings to fire the trigger / queueable again (after the ones initially created in the setup method)
//        List<Meter_Reading__c> newMeterReadings = new List<Meter_Reading__c>();
//        newMeterReadings.add(new Meter_Reading__c(
//                Route_Processing_Sheet__c = rps.Id,
//                Asset__c = meterReadings[0].Asset__c,
//                Current_Lifetime_Cash_In__c = 1111
//        ));
//        newMeterReadings.add(new Meter_Reading__c(
//                Route_Processing_Sheet__c = rps.Id,
//                Asset__c = meterReadings[0].Asset__c,
//                Current_Lifetime_Cash_In__c = 2222
//        ));
//        insert  newMeterReadings; // fires the queueable from the trigger but let's negate that run.
//        for(Meter_Reading__c mr : newMeterReadings) {
//            mr.Previous_Meter_Reading__c = null;
//        }
//        update newMeterReadings;
//
//        Test.startTest();
//        clQueueablePreviousMeters.FORCE_PARTIAL_DML_EXCEPTION = TRUE;
//        clQueueablePreviousMeters q = new clQueueablePreviousMeters(new Map<Id,Meter_Reading__c>(newMeterReadings));
//        Id jobId = System.enqueueJob(q);
//        Test.stopTest();
//
//        List<Meter_Reading__c> updatedMrs = [
//                SELECT   Id, Previous_Meter_Reading__c
//                FROM     Meter_Reading__c
//                WHERE    Id = :newMeterReadings
//        ];
//        // TEST Error forced on first MR only
//        Integer iNumFailed = 0;
//        for(Meter_Reading__c newMr : updatedMrs) {
//            if(newMr.Previous_Meter_Reading__c == null) {
//                iNumFailed++;
//            }
//        }
//        System.assert(iNumFailed == 1);
//    }
}