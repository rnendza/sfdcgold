@IsTest
private class Accel_RouteScheduleTriggerTest {
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
    static void test_updateCollectionStatus() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT  Id,Status__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c IN :rpss];

        Test.startTest();
        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Current_Lifetime_Cash_In__c = 1;
        }
        update meterReadings;

        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Status__c = 'Complete';
        }
        //  fires rollup summary to parent route schedule
        update rpss;

        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Current_Lifetime_Cash_In__c = 0;
        }
        update meterReadings;

        Test.stopTest();
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
    static void test_updateRouteEndTime() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id,Route_End_Timestamp__c FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT  Id,Status__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c IN :rpss];
        for(Meter_Reading__c meterReading : meterReadings) {
            meterReading.Current_Lifetime_Cash_In__c = 1;
            meterReading.Snapshot__c = 'http://www.bogus.com';
        }
        update meterReadings;

        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Status__c = 'Complete';
            rps.Redemption_Terminal_Status__c = 'Complete';
        }
        //  fires rollup summary to parent route schedule
        update rpss;

        Test.startTest();
        routeSchedule.Route_End_Timestamp__c = System.now();
        update routeSchedule;
        Test.stopTest();
    }

    @IsTest
    static void test_fire_platform_event() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id,Route_End_Timestamp__c FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT  Id,Status__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Current_Lifetime_Cash_In__c,Reading_Status__c FROM Meter_Reading__c WHERE Route_Processing_Sheet__c IN :rpss];

        Test.startTest();
            clRouteScheduleTriggerHandler.firePlatformEvent(new Map<Id,Route_Schedule__c> {routeSchedule.Id => routeSchedule} );
        Test.stopTest();
    }
}