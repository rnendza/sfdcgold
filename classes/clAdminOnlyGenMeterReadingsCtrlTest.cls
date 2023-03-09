@IsTest
private class clAdminOnlyGenMeterReadingsCtrlTest {

    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_doCreateMeterReadings() {

        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c LIMIT 1];
        List<Meter_Reading__c> meterReadings = [
                SELECT Id
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rps.Id
        ];
        delete meterReadings;

        Test.startTest();

        ResponseDto dto = clAdminOnlyGenMeterReadingsController.doCreateMeterReadings(rps.Id);
        System.assert(dto.isSuccess);
        List<Meter_Reading__c> meterReadingsInserted = (List<Meter_Reading__c>)dto.values.get(clAdminOnlyGenMeterReadingsController.MAP_KEY_METERS);
        System.assert(meterReadingsInserted.size() > 0);

        Test.stopTest();
    }

    @IsTest
    static void test_doRetrieveRps() {

        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c LIMIT 1];

        Test.startTest();

        ResponseDto dto = clAdminOnlyGenMeterReadingsController.doRetrieveRps(rps.Id);
        System.assert(dto.isSuccess);

        Test.stopTest();
    }
}