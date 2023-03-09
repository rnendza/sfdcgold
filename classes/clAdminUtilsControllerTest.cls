@IsTest
private class clAdminUtilsControllerTest {

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
    static void test_search_routes_keyword_positive() {

        Route__c route = [SELECT Id, Name, Cycle_Number__c FROM Route__c LIMIT 1];
        String searchKey = route.name, sortBy = 'Name', sortDirection = 'desc';
        Integer iLimit = 5;

        Test.startTest();

        List<Route__c> routes = clAdminUtilsController.retrieveRoutes(searchKey,sortBy,sortDirection,iLimit,null);

        Test.stopTest();
    }

    @IsTest
    static void test_search_routes_cyclenumber_positive() {

        Route__c route = [SELECT Id, Name, Cycle_Number__c FROM Route__c LIMIT 1];
        String searchKey = route.name, sortBy = 'Name', sortDirection = 'desc';
        Integer iLimit = 5;
        if(route.Cycle_Number__c == null) {
            route.Cycle_Number__c = 1;
            update route;
        }

        Test.startTest();

        List<Route__c> routes = clAdminUtilsController.retrieveRoutes('',sortBy,sortDirection,iLimit,1);

        Test.stopTest();
    }

    @IsTest
    static void test_search_routeschedule_keyword_positive() {

        Route_Schedule__c routeSchedule = [SELECT Id, Name, Route_Collection_Date__c FROM Route_Schedule__c LIMIT 1];
        String searchKey = routeSchedule.name;
        Integer iLimit = 5;
        Date collectionDate = null;

        Test.startTest();

        List<clAdminUtilsController.RouteScheduleWrapper> routeSchedules = clAdminUtilsController.retrieveRouteSchedules(searchKey,collectionDate,iLimit);
        Test.stopTest();
    }

    @IsTest
    static void test_search_routeschedule_positive() {

        Route_Schedule__c routeSchedule = [SELECT Id, Name, Route_Collection_Date__c FROM Route_Schedule__c LIMIT 1];
        String searchKey = routeSchedule.name;
        Integer iLimit = 5;
        Date collectionDate = null;

        Test.startTest();

        List<clAdminUtilsController.RouteScheduleWrapper> routeSchedules = clAdminUtilsController.retrieveRouteSchedules(searchKey,collectionDate,iLimit);

        collectionDate = Date.today();
        routeSchedules = clAdminUtilsController.retrieveRouteSchedules(null,collectionDate,iLimit);

        routeSchedules = clAdminUtilsController.retrieveRouteSchedules(searchKey,null,iLimit);

        Test.stopTest();
    }
}