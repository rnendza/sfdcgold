@IsTest
public with sharing class clRouteScheduleControllerTest {
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
    static void test_retrieveRouteProcessingSheetsForProcessor_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            ResponseDto dto = clRouteScheduleController.retrieveRouteProcessingSheetsForProcessor(processor.id, tomorrow,'processor');
            sYSTEM.DEBUG('---> DTO:'+DTO);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteProcessingSheetsForProcessor_negative() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date today = Date.today();
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id,Processing_Location__c FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Test.startTest();

        System.runAs(processor) {
            ResponseDto dto = clRouteScheduleController.retrieveRouteProcessingSheetsForProcessor(processor.id, today,'processor');
            sYSTEM.DEBUG('---> DTO:'+DTO);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteProcessingSheetsForProcessorGrouping_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        System.debug('running with processor '+processor);

        Test.startTest();

        System.runAs(processor) {
            List<Route_Schedule__c> routeSchedules = [
                    SELECT  Id, Route_Collection_Date__c,Processing_Location__c,Total_Accounts__c,Total_Processing_Sheets__c,
                            Processing_Status__c
                    FROM    Route_Schedule__c
                    ORDER By Route_Collection_Date__c ASC
            ];
            //List<Route_Processing_Sheet__c> rps = [SELECT Id,Processing_Process_Status__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
            for(Route_Schedule__c rs : routeSchedules) {
                System.debug('running with rs=' + rs);
            }
            //System.debug('running with rps='+rps);
            Double cacheBust = Math.random();
            ResponseDto dto = clRouteScheduleController.retrieveRouteProcessingSheetsGroupedForProcessor(processor.id, cacheBust);
            sYSTEM.DEBUG('---> DTO:'+DTO);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteSchedulesForFillersGrouping_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        System.debug('running with processor '+processor);

        Test.startTest();

        System.runAs(processor) {
            List<Route_Schedule__c> routeSchedules = [
                    SELECT  Id, Route_Fill_Date__c,Processing_Location__c,Total_Accounts__c,Total_Processing_Sheets__c,
                            Processing_Status__c
                    FROM    Route_Schedule__c
                    ORDER By Route_Collection_Date__c ASC
            ];
            for(Route_Schedule__c rs : routeSchedules) {
                System.debug('running with rs=' + rs);
            }
            Double cacheBust = Math.random();
            ResponseDto dto = clRouteScheduleController.retrieveRouteSchedulesGroupedForFiller(processor.id, 14,cacheBust);
            System.debug('---> DTO:'+DTO);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteSchedulesForFillersGrouping_negative() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        System.debug('running with processor '+processor);

        Test.startTest();

        System.runAs(processor) {
            Map<Id,Route_Schedule__c> mRouteSchedules = new Map<Id,Route_Schedule__c>([
                    SELECT  Id
                    FROM    Route_Schedule__c
                    ORDER By Route_Collection_Date__c ASC
            ]);
            List<Route_Processing_Sheet__c> rpss = [
                    SELECT Id,Processing_Status__c
                    FROM   Route_Processing_Sheet__c
                    WHERE  Route_Schedule__c IN :mRouteSchedules.keySet()
            ];
            for(Route_Processing_Sheet__c rps : rpss) {
                rps.Processing_Status__c = 'COMPLETED FILL';
            }
            update rpss;
            Double cacheBust = Math.random();
            ResponseDto dto = clRouteScheduleController.retrieveRouteSchedulesGroupedForFiller(processor.id, 14,cacheBust);
            System.debug('---> DTO:'+DTO);
        }

        Test.stopTest();
    }
}