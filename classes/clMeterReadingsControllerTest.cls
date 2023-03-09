@IsTest
private class clMeterReadingsControllerTest {


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
        List<Route_Processing_Sheet__c> routeProcessingSheets = (List<Route_Processing_Sheet__c>) mClData.get(clTESTUTILS.SFDCRPS);

        Id singleRpsID = routeProcessingSheets[0].Id;
        List<Meter_Reading__c> meterReadings = (List<Meter_Reading__c>) mClData.get(clTESTUTILS.SFDCMETERREADINGS);


        List<Meter_Reading__c> rpsMeterReadings = new List<Meter_Reading__c>();
        for(Meter_Reading__c meterReading : meterReadings) {
            if(meterReading.Route_Processing_Sheet__c == singleRpsID) {
                System.debug('meter reading name='+meterReading.Name);
                rpsMeterReadings.add(meterReading);
            }
        }

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        System.runAs(collector) {
            List<ContentVersion> contentVersions = clTESTUTILS.createFiles(rpsMeterReadings);
        }
    }

    @IsTest
    static void test_upsertMeterReading() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();

        System.runAs(collector) {
            Meter_Reading__c mr = new Meter_Reading__c();
            mr.Route_Processing_Sheet__c = rpsWrapper.rpsId;
            mr.Asset__c = [SELECT ID From ASSET WHERE RecordType.DeveloperName = 'VGT' LIMIT 1].Id;
            ResponseDto dto = clMeterReadingsController.upsertMeterReading(mr);
            System.assert(dto.isSuccess);

            mr.Processing_Status__c = 'BOGUS STATUS GO BOOM';
            dto = clMeterReadingsController.upsertMeterReading(mr);
            System.assert(!dto.isSuccess);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_upsertMeterReadings() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();

        System.runAs(collector) {
            List<Meter_Reading__c> mrs = new List<Meter_Reading__c>();
            Id assetId = [SELECT ID From ASSET WHERE RecordType.DeveloperName = 'VGT' LIMIT 1].Id;

            for(Integer i=0;i<20;i++){
                mrs.add(new Meter_Reading__c(Route_Processing_Sheet__c = rpsWrapper.rpsId,Asset__c=assetId));
            }
            ResponseDto dto = clMeterReadingsController.upsertMeterReadings(mrs);
            System.assert(dto.isSuccess);

            mrs[0].Reading_Status__c = 'BOGUS STATUS GO BOOM';
            dto = clMeterReadingsController.upsertMeterReadings(mrs);
            System.assert(!dto.isSuccess);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsMeterReadings() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoMrs = clMeterReadingsController.retrieveRpsMeterReadings(rpsWrapper.rpsId,'VGT');
            System.assertEquals(dtoMrs.isSuccess,true);
            dtoMrs = clMeterReadingsController.retrieveRpsMeterReadings(null,'VGT');
            System.assertEquals(dtoMrs.isSuccess,false);
            dtoMrs = clMeterReadingsController.retrieveRpsMeterReadings(rpsWrapper.rpsId,'BOGUS_RECORDTYPE');
            System.assertEquals(dtoMrs.isSuccess,false);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateAllMeterReadingsToCannotCollect_Success() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();

        System.runAs(collector) {
            Id rpsId = rpsWrapper.rpsId;
            ResponseDto dto = clMeterReadingsController.updateAllMeterReadingsToCannotCollect(rpsId);
            System.assert(dto.isSuccess);
            List<Meter_Reading__c> mrs = [
                    SELECT Id,Cannot_Collect__c
                    FROM   Meter_Reading__c
                    WHERE  Route_Processing_Sheet__c = :rpsId
            ];
            for(Meter_Reading__c mr : mrs) {
                System.assertEquals(mr.Cannot_Collect__c,true);
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateAllMeterReadingsToCannotCollect_Fail() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];
        Boolean deleteFailed = false;
        try {
            DELETE [SELECT Id FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rpsWrapper.rpsId];
        } catch (Exception e) {
            deleteFailed = true;
        }

        Test.startTest();

        System.runAs(collector) {
            Id rpsId = rpsWrapper.rpsId;
            // 1 no meters.
            ResponseDto dto = clMeterReadingsController.updateAllMeterReadingsToCannotCollect(rpsId);
            if(!deleteFailed) {
                System.assert(!dto.isSuccess);
                System.assert(dto.technicalMsg.contains('No meters'));
            }
            // 2 null rpsId.
            dto = clMeterReadingsController.updateAllMeterReadingsToCannotCollect(null);
            if(!deleteFailed) {
                System.assert(!dto.isSuccess);
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsMeterReadingsSummary() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoMrs = clMeterReadingsController.retrieveRpsMeterReadingsSummary(rpsWrapper.rpsId);
            System.assertEquals(dtoMrs.isSuccess,true);
            dtoMrs = clMeterReadingsController.retrieveRpsMeterReadingsSummary(null);
            System.assertEquals(dtoMrs.isSuccess,false);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsMeterReadingsForProcessor() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        //  Just get a single RPS
        Route_Schedule__c rs = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        //(String type, Id userId, Id routeScheduleId, Date collectionDate) {
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheetsForProcessor(null,processor.Id,rs.Id,Date.today().addDays(1));
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();

        System.runAs(processor) {
            ResponseDto dtoMrs = clMeterReadingsController.retrieveRpsMeterReadingsForProcessor(rpsWrapper.rpsId,'VGT');
            System.assertEquals(dtoMrs.isSuccess,true);
            dtoMrs = clMeterReadingsController.retrieveRpsMeterReadingsForProcessor(null,'VGT');
            System.assertEquals(dtoMrs.isSuccess,false);
            dtoMrs = clMeterReadingsController.retrieveRpsMeterReadingsForProcessor(rpsWrapper.rpsId,'BOGUS_RECORDTYPE');
            System.assertEquals(dtoMrs.isSuccess,false);
        }

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveRouteProcessingSheet() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        Route_Processing_Sheet__c rps = [SELECT Id From Route_Processing_Sheet__c LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoRps = clMeterReadingsController.retrieveRouteProcessingSheet(rps.Id);
            System.assertEquals(dtoRps.isSuccess,true);
            dtoRps = clMeterReadingsController.retrieveRouteProcessingSheet(null);
            System.assertEquals(dtoRps.isSuccess,false);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_deleteDoc() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        Route_Processing_Sheet__c rps = [SELECT Id From Route_Processing_Sheet__c LIMIT 1];

        Meter_Reading__c mr = [SELECT Id FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id LIMIT 1];
        ContentDocumentLink cdl = [SELECT Id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :mr.Id ];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clMeterReadingsController.deleteDoc(cdl.ContentDocumentId,cdl.LinkedEntityId);
            System.assertEquals(dto.isSuccess,true);

            dto = clMeterReadingsController.deleteDoc(null,cdl.LinkedEntityId);
            System.assert(!dto.isSuccess);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateProcessorMeterReadings() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Route_Processing_Sheet__c rps = [
                SELECT  Id,Processor_RT_Status__c,Processing_Status__c,Processing_Process_Status__c,
                        BV_Drop_Total__c
                FROM    Route_Processing_Sheet__c
                LIMIT   1
        ];
        List<Meter_Reading__c> meterReadings = [
                SELECT Id , Actual_Drop__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        rps.BV_Drop_Total__c = 21;

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clMeterReadingsController.updateProcessorMeterReadings(meterReadings,rps);
            Route_Processing_Sheet__c rpsUpdated = (Route_Processing_Sheet__c)dto.values.get(clMeterReadingsController.MAP_KEY_ROUTE_PROCESSING_SHEET);
            System.assert(dto.isSuccess);
            System.assertEquals(rps.BV_Drop_Total__c, rpsUpdated.BV_Drop_Total__c);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateRpsVgtCollectionStartDate() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        //User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
                SELECT  Id,Collection_Type__c,Start_VGT_Collection_Date__c,Start_VGT_Collection_User__c,
                        End_VGT_Collection_Date__c,End_VGT_Collection_User__c
                FROM    Route_Processing_Sheet__c
        ]);
        Route_Processing_Sheet__c rps = mAllRps.values()[0];

        Test.startTest();

        //System.runAs(collector) {  @todo cross reference on entity error is this a real issue?
        //  Success.
        ResponseDto dto = clMeterReadingsController.updateRpsVgtCollectionStartDate(rps);
        System.assert(dto.isSuccess);
        Route_Processing_Sheet__c rpsRecord = (Route_Processing_Sheet__c)dto.values.get(clMeterReadingsController.MAP_KEY_RPS_DATA);
        System.assert(rpsRecord.Start_VGT_Collection_Date__c.date() == Date.today());
        System.assert(rpsRecord.Start_VGT_Collection_User__c == UserInfo.getUserId());

        //  Null Rps Record
        dto = clMeterReadingsController.updateRpsVgtCollectionStartDate(null);
        System.assert(!dto.isSuccess);
        System.assert(dto.severity == 'error');
        System.assert(dto.message.contains(clMeterReadingsController.MSG_FAILED_RPS_VGT_START_DATE));

        //  RPS Record update failed.
        rpsRecord = mAllRps.values()[1];
        DmlException dmlEx;
        try {
            dto.isSuccess = false;
            rps.Collection_Type__c = 'bogus';
            dto = clMeterReadingsController.updateRpsVgtCollectionStartDate(rps);
            System.assert(!dto.isSuccess);
        } catch (DmlException ex) {
            dmlEx = ex;
        }
        System.assert(dmlEx != null);
        //}

        Test.stopTest();
    }

    @IsTest
    static void test_updateRpsVgtCollectionEndDate() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        //User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
                SELECT  Id,Collection_Type__c,Start_VGT_Collection_Date__c,Start_VGT_Collection_User__c,
                        End_VGT_Collection_Date__c,End_VGT_Collection_User__c
                FROM    Route_Processing_Sheet__c
        ]);
        Route_Processing_Sheet__c rps = mAllRps.values()[0];

        Test.startTest();

        //System.runAs(collector) {  @todo cross reference on entity error is this a real issue?
        //  Success.
        ResponseDto dto = clMeterReadingsController.updateRpsVgtCollectionEndDate(rps);
        System.assert(dto.isSuccess);
        Route_Processing_Sheet__c rpsRecord = (Route_Processing_Sheet__c)dto.values.get(clMeterReadingsController.MAP_KEY_RPS_DATA);
        System.assert(rpsRecord.End_VGT_Collection_Date__c.date() == Date.today());
        System.assert(rpsRecord.End_VGT_Collection_User__c == UserInfo.getUserId());

        //  Null Rps Record
        dto = clMeterReadingsController.updateRpsVgtCollectionEndDate(null);
        System.assert(!dto.isSuccess);
        System.assert(dto.severity == 'error');
        System.assert(dto.message.contains(clMeterReadingsController.MSG_FAILED_RPS_VGT_END_DATE));

        //  RPS Record update failed.
        rpsRecord = mAllRps.values()[1];
        DmlException dmlEx;
        try {
            dto.isSuccess = false;
            rps.Collection_Type__c = 'bogus';
            dto = clMeterReadingsController.updateRpsVgtCollectionEndDate(rps);
            System.assert(!dto.isSuccess);
        } catch (DmlException ex) {
            dmlEx = ex;
        }
        System.assert(dmlEx != null);
        //}

        Test.stopTest();
    }

    @IsTest
    static void test_updateRpsCollectionStatus() {

        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
                SELECT  Id,Collection_Type__c,Start_VGT_Collection_Date__c,Start_VGT_Collection_User__c,
                        End_VGT_Collection_Date__c,End_VGT_Collection_User__c,Status__c,Name,
                        Account__r.Name
                FROM    Route_Processing_Sheet__c
        ]);
        Route_Processing_Sheet__c rps = mAllRps.values()[0];

        Test.startTest();

        //  Positive Skipped
        ResponseDto dto = clMeterReadingsController.updateRpsCollectionStatus(rps,'Skipped');
        System.assert(dto.isSuccess);
        Route_Processing_Sheet__c rpsRecord = (Route_Processing_Sheet__c)dto.values.get(clMeterReadingsController.MAP_KEY_RPS_DATA);
        System.assert(rpsRecord.Status__c == 'Skipped');

        //  Positive Not Skipped
        dto = clMeterReadingsController.updateRpsCollectionStatus(rps,'In Progress');
        System.assert(dto.isSuccess);

        //  Bad Status
        dto = clMeterReadingsController.updateRpsCollectionStatus(rps,'Bogus Status');
        System.assert(!dto.isSuccess);

        Test.stopTest();
    }
}