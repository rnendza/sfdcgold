@IsTest
private class clMeterSvcTest {

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
            System.assert(!clMeterSvc.retrieveRpsMeterReadings(rpsWrapper.rpsId).isEmpty());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsMeterSummary() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();
        System.runAs(collector) {
            System.assert(!clMeterSvc.retrieveRpsMeterReadingsSummary(rpsWrapper.rpsId).isEmpty());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsMeterReadings_by_record_type() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Test.startTest();
        System.runAs(collector) {
            System.assert(!clMeterSvc.retrieveRpsMeterReadings(rpsWrapper.rpsId,'VGT').isEmpty());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsMeterReading() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];
        Map<Id,Meter_Reading__c> mMeterReadings  = clMeterSvc.retrieveRpsMeterReadings(rpsWrapper.rpsId,'VGT');

        Test.startTest();
        System.runAs(collector) {
            System.assert( clMeterSvc.retrieveMeterReading(mMeterReadings.values()[0].Id) != null);
            System.assert( clMeterSvc.retrieveSingleMeterReading(mMeterReadings.values()[0].Id) != null);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveCollectorMeterDetail() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];
        Map<Id,Meter_Reading__c> mMeterReadings  = clMeterSvc.retrieveRpsMeterReadings(rpsWrapper.rpsId,'VGT');


        Test.startTest();
        System.runAs(collector) {
            System.assert( clMeterSvc.retrieveCollectorMeterDetail(mMeterReadings.values()[0].Id) != null);
        }
        Test.stopTest();
    }

}