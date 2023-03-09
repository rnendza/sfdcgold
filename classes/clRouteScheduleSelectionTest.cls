@IsTest
private class clRouteScheduleSelectionTest {

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
    static void test_retrieveTodaysRouteSchedules() {
        Test.startTest();
        ResponseDto dto = clRouteScheduleSelection.retrieveRouteSchedules(Date.today().addDays(1));
        System.assertEquals(dto.isSuccess,true);
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveTodaysRouteSchedulesByRegion() {

        List<Route_Schedule__c> routeSchedules = [
                SELECT Id, Processing_Location__c
                FROM Route_Schedule__c
        ];
        for(Route_Schedule__c rs : routeSchedules) {
            rs.Processing_Location__c = 'Burr Ridge';
        }
        update routeSchedules;

        Test.startTest();
        User u = [SELECT Id, Default_Collector_Location__c FROM User WHERE Id = :UserInfo.getUserId()];
        u.Default_Collector_Location__c = 'Burr Ridge';
        update u;
        ResponseDto dto = clRouteScheduleSelection.retrieveRegionRouteSchedules(Date.today().addDays(1),'Burr Ridge',null);
        System.assertEquals(dto.isSuccess,true);


        delete [SELECT Id FROM Route_Schedule_Account__c];
        clRouteScheduleSelection.TEST_HIDE_INVALID_ROUTES = true;
        dto = clRouteScheduleSelection.retrieveRegionRouteSchedules(Date.today().addDays(1),'Burr Ridge',null);
        System.assertEquals(dto.isSuccess,false);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRegions() {

        Test.startTest();
        List<String> suppressValues = null;

        ResponseDto dto = clRouteScheduleSelection.retrieveCollectorLocationInfo(UserInfo.getUserId(),suppressValues);
        System.assertEquals(dto.isSuccess,true);
        List<clRouteScheduleSelection.RegionPlWrapper> plWrappers
                = (List<clRouteScheduleSelection.RegionPlWrapper>)dto.values.get(clRouteScheduleSelection.MAP_KEY_COLLECTOR_LOC_WRAPPERS);

        Boolean hasBurrRidge = false;
        for(clRouteScheduleSelection.RegionPlWrapper plWrapper : plWrappers) {
            if(plWrapper.value == 'Burr Ridge') {
                hasBurrRidge = true;
                break;
            }
        }
        System.assert( hasBurrRidge );

        suppressValues = new List<String> {'Burr Ridge'};
        dto = clRouteScheduleSelection.retrieveCollectorLocationInfo(UserInfo.getUserId(),suppressValues);
        System.assertEquals(dto.isSuccess,true);
        plWrappers = (List<clRouteScheduleSelection.RegionPlWrapper>)dto.values.get(clRouteScheduleSelection.MAP_KEY_COLLECTOR_LOC_WRAPPERS);

        hasBurrRidge = false;
        for(clRouteScheduleSelection.RegionPlWrapper plWrapper : plWrappers) {
            if(plWrapper.value == 'Burr Ridge') {
                hasBurrRidge = true;
                break;
            }
        }
        System.assert( !hasBurrRidge );


        Test.stopTest();
    }

    @IsTest
    static void test_invalidRoutes() {
        DELETE [SELECT Id From Route__c];
        DELETE [SELECT Id FROM Route_Schedule__c];
        Route__c route = new Route__c(Name = ' Route with no accounts');
        insert route;

        Test.startTest();
        clRouteScheduleSelection.TEST_HIDE_INVALID_ROUTES = TRUE;
        ResponseDto dto = clRouteScheduleSelection.retrieveRouteSchedules(Date.today().addDays(1));
        System.assertEquals(dto.isSuccess,false);
        Test.stopTest();
    }


    @IsTest
    static void test_retrieveRouteProcessingSheets() {
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT  1];

        Test.startTest();
        ResponseDto dto = clRouteScheduleSelection.retrieveRouteProcessingSheets(routeSchedule.Id);
        System.assertEquals(dto.isSuccess,true);
        Test.stopTest();
    }

    @IsTest
    static void test_doRouteScheduleSelection_positive_collector1() {
        Route_Schedule__c routeSchedule = [SELECT Id,Collector_1__c FROM Route_Schedule__c LIMIT  1];
        routeSchedule.Collector_1__c = null;
        update routeSchedule;

        Test.startTest();
        ResponseDto dto = clRouteScheduleSelection.doRouteScheduleSelection(UserInfo.getUserId(),routeSchedule.Id);
        System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }

    @IsTest
    static void test_doRouteScheduleSelection_positive_collector2() {
        Route_Schedule__c routeSchedule = [SELECT Id,User__c FROM Route_Schedule__c LIMIT  1];
        routeSchedule.User__c = null;
        update routeSchedule;

        Test.startTest();
        ResponseDto dto = clRouteScheduleSelection.doRouteScheduleSelection(UserInfo.getUserId(),routeSchedule.Id);
        System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }

    @IsTest
    static void test_doRouteScheduleSelection_allreadyscheduled() {
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT  1];

        Test.startTest();
        ResponseDto dto = clRouteScheduleSelection.doRouteScheduleSelection(UserInfo.getUserId(),routeSchedule.Id);
        System.assertEquals(dto.isSuccess,false);

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveMdt() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteScheduleSelection.retrieveMdt('Route_Selection');
            System.assert(dto.values.get(clRouteScheduleSelection.MAP_KEY_MDT_RECORD) != null);
            Cash_Logistics_Setting__mdt mdt = clRouteScheduleSelection.retrieveMdt();
        }

        Test.stopTest();
    }
}