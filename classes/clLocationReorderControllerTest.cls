@IsTest
private class clLocationReorderControllerTest {

    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_retrieve_Route_Locs() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];


        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clLocationReorderController.retrieveLocations('Route__c',route.Id);
            System.assert(dto.isSuccess);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_update_Route_Locs() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        ResponseDto dto = clLocationReorderController.retrieveLocations('Route__c',route.Id);
        List<clLocationReorderController.clLocation> clLocs =
                (List<clLocationReorderController.clLocation>)dto.values.get(clLocationReorderController.MAP_KEY_LOCATIONS);
        List<Route_Account__c> routeAccounts = new List<Route_Account__c>();

        Integer i = 1;
        for(clLocationReorderController.clLocation clLoc : clLocs) {
            Route_Account__c ra = new Route_Account__c(Id=clLoc.recordId, Stop_Number__c =i+1);
            routeAccounts.add(ra);
        }

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoUpd = clLocationReorderController.doUpdateStopNumbers(routeAccounts);
            System.assert(dtoUpd.isSuccess);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieve_Route_Schedule_Locs() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id limit 1];


        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clLocationReorderController.retrieveLocations('Route_Schedule__c',routeSchedule.Id);
            System.assert(dto.isSuccess);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_getFormattedLocName() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();

        System.runAs(collector) {
            String name = clLocationReorderController.getFormattedLocName('Test Name',2);
            System.assert(name.containsIgnoreCase('2'));
            name = clLocationReorderController.getFormattedLocName('Test Name',null);
            System.assert(name.containsIgnoreCase('(0)'));
        }
        Test.stopTest();
    }
}