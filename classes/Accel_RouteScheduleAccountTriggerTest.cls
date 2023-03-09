@IsTest
private class Accel_RouteScheduleAccountTriggerTest {

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
    static void test_deleteRsas() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        List<Route_Schedule_Account__c> rsas = [SELECT ID FROM Route_Schedule_Account__c WHERE Route_Schedule__c = :routeSchedule.Id];

        Test.startTest();

        try {
            delete rsas;
            rpss = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
            System.assert(rpss.size() == 0);
        } catch (Exception e) {
            //  @todo proper asserts
            System.debug(LoggingLevel.INFO,'stopped from deleting rsas on cascade '+ e);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateStopNumberRsas() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT  Id,Stop_Number__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        List<Route_Schedule_Account__c> rsas = [SELECT ID,Stop_Number__c FROM Route_Schedule_Account__c WHERE Route_Schedule__c = :routeSchedule.Id];

        Test.startTest();

        System.assertEquals(rpss.size(),rsas.size());
        for(Route_Schedule_Account__c rsa : rsas) {
            rsa.Stop_Number__c = rsa.Stop_Number__c + 1;
        }
        update rsas;

        rpss =  [SELECT  Id,Stop_Number__c,Route_Schedule_Account__r.Stop_Number__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        for(Route_Processing_Sheet__c rps : rpss) {
            System.assertEquals(rps.Stop_Number__c,rps.Route_Schedule_Account__r.Stop_Number__c);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_createAdditionalFill() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        
        Route_Schedule_Account__c routeScheduleAccount = new Route_Schedule_Account__c();
        routeScheduleAccount.Route_Schedule__c = routeSchedule.Id;
        routeScheduleAccount.Account__c = account.Id;
        routeScheduleAccount.Collection_Type__c = new List<String>(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES)[0];
        insert routeScheduleAccount;

        Test.stopTest();
    }

}