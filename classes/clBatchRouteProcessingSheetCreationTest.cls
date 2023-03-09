@IsTest
private class clBatchRouteProcessingSheetCreationTest {

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
    static void test_exeBatch_fill_date() {

        Test.startTest();
        Date fillDate = Date.today().addDays(1);
        clBatchRouteProcessingSheetCreation  b = new clBatchRouteProcessingSheetCreation(fillDate);
        Database.executeBatch(b,2000);

        Test.stopTest();
    }

    @IsTest
    static void test_exeBatch_route_schedule_id() {

        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT 1];

        Test.startTest();

        Date collectionDate = Date.today().addDays(1);
        clBatchRouteProcessingSheetCreation  b = new clBatchRouteProcessingSheetCreation(routeSchedule.Id,clTESTUTILS.DEFAULT_PROCESSING_LOC);
        Database.executeBatch(b,2000);

        Test.stopTest();
    }
    //public clBatchRouteProcessingSheetCreation(Date pRouteFillDate, String region) {
    @IsTest
    static void test_exeBatch_fill_date_region() {
        Test.startTest();
        Date fillDate = Date.today().addDays(1);
        clBatchRouteProcessingSheetCreation  b = new clBatchRouteProcessingSheetCreation(fillDate,'Burr Ridge');
        Database.executeBatch(b,2000);

        Test.stopTest();
    }

    @IsTest
    static void test_remove_second_meter_from_creation() {

        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        Route_Schedule_Account__c rsa = new Route_Schedule_Account__c();
        rsa.Route_Schedule__c= routeSchedule.Id;
        rsa.Account__c= [SELECT ID From Account LIMIT 1].ID;
        rsa.Collection_Type__c = 'Regular - 2nd RT';
        rsa.Redemption_Type_From_Asset__c = 'M3T';
        insert rsa;

        Route_Processing_Sheet__c rps = new Route_Processing_Sheet__c();
        rps.Route_Schedule__c = routeSchedule.Id;
        rps.Route_Schedule_Account__c = rsa.Id;
        rps.Collection_Type__c = rsa.Collection_Type__c;
        rps.Account__c = rsa.Account__c;
        insert rps;


        Test.startTest();

        clBatchRouteProcessingSheetCreation  b = new clBatchRouteProcessingSheetCreation(routeSchedule.Id,clTESTUTILS.DEFAULT_PROCESSING_LOC);
        Set<Id> filteredIds = b.remove2ndRtFromMeterCreation(new Set<Id> {rps.Id});
        System.assert(!filteredIds.contains(rps.Id));

        Test.stopTest();
    }

    @IsTest
    static void test_remove_second_meter_from_creation_regular_rt_only() {

        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        Route_Schedule_Account__c rsa = new Route_Schedule_Account__c();
        rsa.Route_Schedule__c= routeSchedule.Id;
        rsa.Account__c= [SELECT ID From Account LIMIT 1].ID;
        rsa.Collection_Type__c = 'Regular - RT Only';
        rsa.Redemption_Type_From_Asset__c = 'M3T';
        insert rsa;

        Route_Processing_Sheet__c rps = new Route_Processing_Sheet__c();
        rps.Route_Schedule__c = routeSchedule.Id;
        rps.Route_Schedule_Account__c = rsa.Id;
        rps.Collection_Type__c = rsa.Collection_Type__c;
        rps.Account__c = rsa.Account__c;
        insert rps;


        Test.startTest();

        clBatchRouteProcessingSheetCreation  b = new clBatchRouteProcessingSheetCreation(routeSchedule.Id,clTESTUTILS.DEFAULT_PROCESSING_LOC);
        Set<Id> filteredIds = b.remove2ndRtFromMeterCreation(new Set<Id> {rps.Id});
        System.assert(!filteredIds.contains(rps.Id));

        Test.stopTest();
    }
}