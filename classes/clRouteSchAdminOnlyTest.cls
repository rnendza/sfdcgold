@IsTest
private class clRouteSchAdminOnlyTest {

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
    static void test_retrieveRoutes() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteSchAdminOnly.retrieveRoutes();
            System.assert(dto.isSuccess);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_cloneRoutes() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT Id, Cycle_Number__c, Name FROM Route__c LIMIT 1];

        Id oldRouteId = route.Id;
        String newRouteName = route.Name + ' - cloned';
        Integer cycleNumber = Integer.valueOf(route.Cycle_Number__c) + 1;
        Date collectionDate = Date.today().addDays(1);
        String processingLoc = 'Burr Ridge';

        Test.startTest();

        System.runAs(collector) {

            ResponseDto dto = clRouteSchAdminOnly.cloneRoute(oldRouteId,newRouteName,cycleNumber,processingLoc);
            System.assert(dto.isSuccess);
        }

        Test.stopTest();
    }
}