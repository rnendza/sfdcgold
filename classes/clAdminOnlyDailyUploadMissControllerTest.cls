@IsTest
private class clAdminOnlyDailyUploadMissControllerTest {

    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_fireRsJob_negative() {
        Test.startTest();

        ResponseDto dto = clAdminOnlyDailyUploadMissController.fireRsJob(null,null,null,2,4);
        System.assert(!dto.isSuccess);
        System.assertEquals(dto.severity,'error');
        System.assert(dto.message.contains(clAdminOnlyDailyUploadMissController.ERROR_MSG_INVALID_PARAMS));

        Test.stopTest();
    }

    @IsTest
    static void test_fireRsJob_positive() {
        String mdtDevName = 'Scheduler';
        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)oMdt;
        Integer iNextCycle = Integer.valueOf(mdt.Next_Cycle__c);
        System.debug('---> running with cycle number:'+iNextCycle);

        // Note I still don't understand this original_date ? next_fill_date stuff? but the next cycle must
        // be correct in the tgt org which is stored in custom mdt otherwise this test will fail
        List<Route__c> routes = [
                SELECT Id,Origination_Date__c,Next_Fill_Date__c
                FROM   Route__c
                WHERE  Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
                AND    Cycle_Number__c = :iNextCycle
        ];
        System.debug('---> routes='+routes);

        List<Meter_Reading__c> metersToDelete = [
                SELECT Id,Route_Processing_Sheet__r.Processing_Location__c,CreatedDate
                FROM   Meter_Reading__c
                WHERE  CreatedDate = TODAY
                AND    Route_Processing_Sheet__r.Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
        ];
        List<Route_Schedule__c> routeSchedulesToDelete = [
                SELECT Id,Route_Fill_Date__c
                FROM   Route_Schedule__c
                WHERE  CreatedDate = TODAY
                AND    Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
        ];
        System.debug('route schedules to delete='+routeSchedulesToDelete);
        List<Route_Processing_Sheet__c> rpsSheetsToDelete = [
                SELECT Id
                FROM   Route_Processing_Sheet__c
                WHERE  CreatedDate = TODAY
                AND    Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
        ];

        String processingLoc = clTESTUTILS.DEFAULT_PROCESSING_LOC;

        Test.startTest();
        Boolean deletesFailed = false;
        try {
            ResponseDto dto = clAdminOnlyDailyUploadMissController.fireRsJob(processingLoc, iNextCycle,metersToDelete[0].CreatedDate,2,4);
            System.assert(dto.isSuccess);

            List<clAdminOnlyDailyUploadMissController.SyncResult> syncResults =
                    (List<clAdminOnlyDailyUploadMissController.SyncResult>)
                            dto.values.get(clAdminOnlyDailyUploadMissController.MAP_KEY_SYNC_RESULTS);
            System.debug('---> syncResults=' + syncResults);


            List<Meter_Reading__c> allDeletedMeters = [
                    SELECT Id
                    FROM Meter_Reading__c
                    WHERE IsDeleted = TRUE
                    ALL ROWS
            ];
           // System.assertEquals(allDeletedMeters.size(), metersToDelete.size());

            List<Route_Schedule__c> allRouteSchedulesDeleted = [
                    SELECT Id
                    FROM Route_Schedule__c
                    WHERE IsDeleted = TRUE
                    ALL ROWS
            ];
            // System.assertEquals(allRouteSchedulesDeleted.size(), routeSchedulesToDelete.size());

            List<Route_Processing_Sheet__c> allRpsSheetsDeleted = [
                    SELECT Id
                    FROM Route_Processing_Sheet__c
                    WHERE IsDeleted = TRUE
                    ALL ROWS
            ];
            // System.assertEquals(allRpsSheetsDeleted.size(), rpsSheetsToDelete.size());
        } catch (Exception e) {
            //@todo proper asserts
            deletesFailed = true;
            System.debug(LoggingLevel.INFO,e); // will fail when org is set up to not allow deleted
        }

        Test.stopTest();
        if(!deletesFailed) {
            Integer iNumRoutes = [
                    SELECT Count()
                    FROM Route__c
                    WHERE Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
                    AND Cycle_Number__c = :iNextCycle
            ];

            Map<Id, Route_Schedule__c> mNewRouteSchedules = new Map<Id, Route_Schedule__c>([
                    SELECT Id, Route_Fill_Date__c
                    FROM Route_Schedule__c
                    WHERE CreatedDate = TODAY
                    AND Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
                    AND Route__r.Cycle_Number__c = :iNextCycle
            ]);
            System.debug('new routeschedules=' + mNewRouteSchedules);
            System.assertEquals(iNumRoutes, mNewRouteSchedules.values().size());

            Integer iNumRouteScheduleAccounts = [
                    SELECT Count()
                    FROM Route_Schedule_Account__c
                    WHERE Route_Schedule__r.Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
                    AND Route_Schedule__r.Route__r.Cycle_Number__c = :iNextCycle
            ];
            List<Route_Processing_Sheet__c> newRpss = [
                    SELECT Id
                    FROM Route_Processing_Sheet__c
                    WHERE CreatedDate = TODAY
                    AND Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
                    AND Route_Schedule__r.Route_Fill_Date__c = :clAdminOnlyDailyUploadMissController.DEFAULT_ROUTE_FILL_DATE
            ];
         //   System.assertEquals(iNumRouteScheduleAccounts, newRpss.size());
        }
    }

    @IsTest
    static void test_fireRpsJob_positive() {

        String processingLoc = clTESTUTILS.DEFAULT_PROCESSING_LOC;

        clAdminOnlyDailyUploadMissController.DEFAULT_BATCH_SIZE = 2000;
        Test.startTest();
        try {
            ResponseDto dto = clAdminOnlyDailyUploadMissController.fireRpsJob(processingLoc);
            System.assert(dto.isSuccess);
        } catch (Exception e) {
            //@todo proper asserts
            System.debug(LoggingLevel.INFO,e); // will fail when org is set up to not allow deleted
        }
    }

    @IsTest
    static void test_fireRpsJob_negative() {

        String processingLoc = null;

        clAdminOnlyDailyUploadMissController.DEFAULT_BATCH_SIZE = 2000;
        Test.startTest();
        try {
            ResponseDto dto = clAdminOnlyDailyUploadMissController.fireRpsJob(processingLoc);
            System.assert(!dto.isSuccess);
        } catch (Exception e) {
            //@todo proper asserts
            System.debug(LoggingLevel.INFO,e); // will fail when org is set up to not allow deleted
        }
    }

//    @IsTest
//    static void test_searchForMetersToModify_positive() {
//
//        List<Meter_Reading__c> meters = [
//                SELECT Id,Route_Processing_Sheet__r.Processing_Location__c,CreatedDate
//                FROM   Meter_Reading__c
//                WHERE  CreatedDate = TODAY
//                AND    Route_Processing_Sheet__r.Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
//        ];
//
//        try {
//
//            Test.startTest();
//
////            ResponseDto dto = clAdminOnlyDailyUploadMissController.searchForMetersToModify(meters[0].CreatedDate,2,4);
//
//            Test.stopTest();
//        } catch (Exception e) {
//            //@todo proper asserts
//            System.debug(LoggingLevel.INFO, e); // will fail when org is set up to not allow deletes
//        }
//    }

    @IsTest
    static void test_retrieveScheduledJobInfo_positive() {
        String mdtDevName = 'Scheduler';
        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)oMdt;
        Integer iNextCycle = Integer.valueOf(mdt.Next_Cycle__c);

        List<Meter_Reading__c> meters = [
                SELECT Id,Route_Processing_Sheet__r.Processing_Location__c,CreatedDate
                FROM   Meter_Reading__c
                WHERE  CreatedDate = TODAY
                AND    Route_Processing_Sheet__r.Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
        ];

        String processingLoc = clTESTUTILS.DEFAULT_PROCESSING_LOC;
        try {
            ResponseDto dto = clAdminOnlyDailyUploadMissController.fireRsJob(processingLoc, iNextCycle,meters[0].CreatedDate,2,4);
            Id rsBatchJobId = (Id) dto.values.get(clAdminOnlyDailyUploadMissController.MAP_KEY_RS_BATCH_JOB_ID);


            Test.startTest();
            List<Id> jobIds = new List<Id>{
                    rsBatchJobId
            };
            List<String> apexClassNames = new List<String>{
                    'clBatchRouteScheduleCreation', 'clBatchRouteProcessingSheetCreation', 'clBatchMeterReadingsCreation'
            };
            List<String> jobStatuses = new List<String>{
                    'Queued', 'Aborted', 'Completed', 'Failed', 'Holding', 'Preparing', 'Processing'
            };

            ResponseDto dtoJobs = clAdminOnlyDailyUploadMissController.retrieveScheduledJobInfo(jobStatuses, apexClassNames, jobIds);
            Test.stopTest();
        } catch (Exception e) {
            //@todo proper asserts
            System.debug(LoggingLevel.INFO, e); // will fail when org is set up to not allow deletes
        }
    }

    @IsTest
    static void test_retrieveBatchMeterJobInfo_positive() {
        String mdtDevName = 'Scheduler';
        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)oMdt;
        Integer iNextCycle = Integer.valueOf(mdt.Next_Cycle__c);

        List<Meter_Reading__c> meters = [
                SELECT Id,Route_Processing_Sheet__r.Processing_Location__c,CreatedDate
                FROM   Meter_Reading__c
                WHERE  CreatedDate = TODAY
                AND    Route_Processing_Sheet__r.Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
        ];

        String processingLoc = clTESTUTILS.DEFAULT_PROCESSING_LOC;
        try {
            clAdminOnlyDailyUploadMissController.DEFAULT_BATCH_SIZE = 2000;
            ResponseDto dto = clAdminOnlyDailyUploadMissController.fireRsJob(processingLoc, iNextCycle,meters[0].CreatedDate,2,4);
            Id rsBatchJobId = (Id) dto.values.get(clAdminOnlyDailyUploadMissController.MAP_KEY_RS_BATCH_JOB_ID);
            clAdminOnlyDailyUploadMissController.fireRpsJob(processingLoc);

            Test.startTest();
            List<Id> jobIds = new List<Id>{
                    rsBatchJobId
            };
            List<String> apexClassNames = new List<String>{
                    'clBatchRouteScheduleCreation', 'clBatchRouteProcessingSheetCreation', 'clBatchMeterReadingsCreation'
            };
            List<String> jobStatuses = new List<String>{
                    'Queued', 'Aborted', 'Completed', 'Failed', 'Holding', 'Preparing', 'Processing'
            };

            ResponseDto dtoJobs = clAdminOnlyDailyUploadMissController.retrieveBatchMeterJobInfo('clBatchMeterReadingsCreation', jobStatuses);
            Test.stopTest();
        } catch (Exception e) {
            //@todo proper asserts
            System.debug(LoggingLevel.INFO, e); // will fail when org is set up to not allow deletes
        }

    }

    @IsTest
    static void test_retrieveDataCreationTotals_positive() {
        String mdtDevName = 'Scheduler';
        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)oMdt;
        Integer iNextCycle = Integer.valueOf(mdt.Next_Cycle__c);

        List<Meter_Reading__c> meters = [
                SELECT Id,Route_Processing_Sheet__r.Processing_Location__c,CreatedDate
                FROM   Meter_Reading__c
                WHERE  CreatedDate = TODAY
                AND    Route_Processing_Sheet__r.Processing_Location__c = :clTESTUTILS.DEFAULT_PROCESSING_LOC
        ];

        String processingLoc = clTESTUTILS.DEFAULT_PROCESSING_LOC;
        try {
            clAdminOnlyDailyUploadMissController.DEFAULT_BATCH_SIZE = 2000;
            ResponseDto dto = clAdminOnlyDailyUploadMissController.fireRsJob(processingLoc, iNextCycle,meters[0].CreatedDate,2,4);
            Id rsBatchJobId = (Id) dto.values.get(clAdminOnlyDailyUploadMissController.MAP_KEY_RS_BATCH_JOB_ID);

            clAdminOnlyDailyUploadMissController.fireRpsJob(processingLoc);

            List<Id> jobIds = new List<Id>{
                    rsBatchJobId
            };
            List<String> apexClassNames = new List<String>{
                    'clBatchRouteScheduleCreation', 'clBatchRouteProcessingSheetCreation', 'clBatchMeterReadingsCreation'
            };
            List<String> jobStatuses = new List<String>{
                    'Queued', 'Aborted', 'Completed', 'Failed', 'Holding', 'Preparing', 'Processing'
            };

            ResponseDto dtoJobs = clAdminOnlyDailyUploadMissController.retrieveBatchMeterJobInfo('clBatchMeterReadingsCreation', jobStatuses);
        } catch (Exception e) {
            //@todo proper asserts
            System.debug(LoggingLevel.INFO,e); // will fail when org is set up to not allow deletes
        }


        Test.startTest();
            clAdminOnlyDailyUploadMissController.retrieveDataCreationTotals(processingLoc,2,4);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveLatestMeterRecordsTotal_positive() {

        Meter_Reading__c meter = [
                SELECT      CreatedDate
                FROM        Meter_Reading__c
                ORDER BY    CreatedDate DESC
                LIMIT 1
        ];

        Test.startTest();

        ResponseDto dto = clAdminOnlyDailyUploadMissController.retrieveLatestMeterRecordsTotal();
        Datetime maxDate = (Datetime)dto.values.get(clAdminOnlyDailyUploadMissController.MAP_KEY_MAX_METER_CREATED_DATE);
        System.assertEquals(meter.CreatedDate,maxDate);

        Test.stopTest();

    }

    @IsTest
    static void test_retrieveLatestRouteSchedule_positive() {

        Route_Schedule__c routeSchedule = [
                SELECT      Id,CreatedDate,Processing_Location__c
                FROM        Route_Schedule__c
                ORDER BY    CreatedDate DESC
                LIMIT 1
        ];

        Test.startTest();

        ResponseDto dto = clAdminOnlyDailyUploadMissController.retrieveLatestRouteSchedule();
        Route_Schedule__c latestRs = (Route_Schedule__c)dto.values.get(clAdminOnlyDailyUploadMissController.MAP_KEY_LATEST_ROUTE_SCHEDULE);
        System.assertEquals(routeSchedule.CreatedDate,latestRs.CreatedDate);

        Test.stopTest();

    }

    @IsTest
    static void test_retrieveMetersToModTotals_positive() {


        Test.startTest();

        ResponseDto dto = clAdminOnlyDailyUploadMissController.retrieveMetersToModTotals(
                System.now(),
                clTESTUTILS.DEFAULT_PROCESSING_LOC,
                5,
                10
        );
        System.assert(dto.isSuccess);

        Test.stopTest();

    }

    @IsTest
    static void test_retrieveMetersToModTotals_negative() {


        Test.startTest();

        ResponseDto dto = clAdminOnlyDailyUploadMissController.retrieveMetersToModTotals(
                System.now().addDays(10),
                'bogusregion',
                5,
                10
        );
        System.assert(!dto.isSuccess);

        Test.stopTest();

    }

    @IsTest
    static void test_retrieveRegionsAffected_positive() {

        Test.startTest();

        Set<String> regions  = clAdminOnlyDailyUploadMissController.retrieveRegionsAffected(
                System.now(),
                clTESTUTILS.DEFAULT_PROCESSING_LOC,
                5,
                10
        );
        System.assert(regions.contains(clTESTUTILS.DEFAULT_PROCESSING_LOC));

        Test.stopTest();

    }

    @IsTest
    static void test_SyncResult_Constructors() {
        Test.startTest();

        clAdminOnlyDailyUploadMissController.SyncResult sr =
                new clAdminOnlyDailyUploadMissController.SyncResult(
                        'msg',
                        System.now(),
                        'region'
                );

        sr =
                new clAdminOnlyDailyUploadMissController.SyncResult(
                        new List<Account>{
                                new Account()
                        },
                        'region'
                );

        Test.stopTest();
    }

    @IsTest
    static void test_searchForMetersToModify_positive() {


        Test.startTest();

        ResponseDto dto = clAdminOnlyDailyUploadMissController.searchForMetersToModify(
                System.now(),
                clTESTUTILS.DEFAULT_PROCESSING_LOC,
                5,
                10
        );
        System.assert(dto.isSuccess);

        Test.stopTest();

    }
}