@IsTest
private class clMeterReadingDetailTest {
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
    static void test_constructor() {

        Id meterId = [SELECT Id FROM Meter_Reading__c LIMIT 1].id;
        Meter_Reading__c meter = clMeterSvc.retrieveMeterReading(meterId);
        Test.startTest();
        clMeterReadingDetail mr = new clMeterReadingDetail(meter);
        Test.stopTest();
    }
}