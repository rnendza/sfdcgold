@IsTest
private class clRouteScheduleAccountSvcTest {

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
    static void retrieve_RouteScheduleAccounts_test() {
        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);

        Map<Id, Route_Schedule_Account__c> mRsas = new Map<Id, Route_Schedule_Account__c>([
                SELECT Id
                FROM Route_Schedule_Account__c
        ]);

        Test.startTest();

        System.runAs(processor) {
            List<Route_Schedule_Account__c> routeScheduleAccounts = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds(mRsas.keySet());
            System.assertEquals(mRsas.size(),routeScheduleAccounts.size());
        }

        Test.stopTest();

    }
}