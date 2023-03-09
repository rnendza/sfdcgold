@IsTest
private class clMapControllerTest {
    
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
    static void test_retrieveReverseGeoAddy() {

        GeoCoordinates geoCoordinates = new GeoCoordinates();
        geoCoordinates.latitude = 1;
        geoCoordinates.longitude = -1;

        Test.startTest();

        ResponseDto dto = clMapController.retrieveReverseGeoAddy(geoCoordinates);
        System.assert(dto.isSuccess);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveCurrentRecord() {

        Route_Schedule__c routeSchedule  = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        Test.startTest();

        ResponseDto dto = clMapController.retrieveCurrentRecord(routeSchedule.Id,'Route_Schedule__c');
        System.assert(dto.isSuccess);

        Test.stopTest();
    }
}