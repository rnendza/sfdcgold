@IsTest
private class clRouteScheduleSvcTest {

    @TestVisible private static String DEFAULT_OWA_EMAIL_ADDRESS = 'crm@accelentertainment.com';
    
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
    static void test_retrieveRouteSchedulesForProcessor() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            List<Route_Schedule__c> rss = clRouteScheduleSvc.retrieveRouteSchedulesForProcessor(processor.id, tomorrow,'fill');
            //System.assert(!rss.isEmpty());
        }

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveRouteSchedulesForProcessorGroups() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date yesterday = Date.today().addDays(-1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            Set<Id> processorIds = new Set<Id> {processor.id};
            List<clRouteScheduleSvc.RouteScheduleGrouping> rss = clRouteScheduleSvc.retrieveRouteSchedulesForProcessorGroups(processorIds, yesterday);
            System.assert(!rss.isEmpty());
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteSchedulesForFillerGroups() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date yesterday = Date.today().addDays(-1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            Set<Id> processorIds = new Set<Id> {processor.id};
            List<clRouteScheduleSvc.RouteScheduleFillGrouping> rss = clRouteScheduleSvc.retrieveRouteSchedulesForFillersGroups(processorIds, 14,yesterday);
            System.assert(!rss.isEmpty());
        }

        Test.stopTest();
    }
    @IsTest
    static void test_retrieveRouteSchedules() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Map<Id,Route_Schedule__c> m = clRouteScheduleSvc.retrieveRouteSchedules(collector.id, tomorrow);
            System.assert(!m.isEmpty());
        }

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveUserInfo() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();


        System.runAs(collector) {
            User u = clRouteScheduleSvc.retrieveUserInfo(collector.Id);
            System.assert(u != null);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrievePlValues() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();


        System.runAs(collector) {
            List<Schema.PicklistEntry> ples = clRouteScheduleSvc.retrievePlValues('User','Default_Collector_Location__c');
            System.assert(ples != null);
        }

        Test.stopTest();
    }


    /**
     * RJN
     */
    @IsTest
    static void test_retrieveRegionRouteSchedules() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        List<Route_Schedule__c> routeSchedules = [
                SELECT Id, Processing_Location__c
                FROM Route_Schedule__c
        ];
        for(Route_Schedule__c rs : routeSchedules) {
            rs.Processing_Location__c = 'Burr Ridge';
        }
        update routeSchedules;

        Test.startTest();
        User u = [SELECT Id, Default_Collector_Location__c FROM User WHERE Id = :collector.Id];
        u.Default_Collector_Location__c = 'Burr Ridge';
        update u;


        System.runAs(collector) {
            Map<Id,Route_Schedule__c> m = clRouteScheduleSvc.retrieveRegionRouteSchedules(tomorrow,'Burr Ridge',null);
            System.assert(!m.isEmpty());
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllTodaysRouteSchedules() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Map<Id,Route_Schedule__c> m = clRouteScheduleSvc.retrieveRouteSchedules(tomorrow);
            System.assert(!m.isEmpty());
        }

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveRouteSchedule() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Route_Schedule__c rs =  clRouteScheduleSvc.retrieveRouteSchedule(routeSchedule.id);
            System.assert(rs != null);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateRouteSchedule() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Database.SaveResult sr = clRouteScheduleSvc.updateRouteSchedule(routeSchedule);
            System.assert(sr.isSuccess());
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveSetting() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Cash_Logistics_Setting__mdt mdt = clRouteScheduleSvc.retrieveSetting('Scheduler');
            System.assert(mdt != null);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_sendRouteScheduleCompletedEmail() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(DEFAULT_OWA_EMAIL_ADDRESS);
        EmailTemplate template = [SELECT Id,Name,DeveloperName FROM EmailTemplate WHERE DeveloperName = :clQueueableRpsEmailer.DEFAULT_TEMPLATE_DEV_NAME];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        User adminUser = new User(Id=UserInfo.getUserId());

        System.runAs(adminUser) {
            EmailTemplate emailTemplate = TestUtils.buildEmailTemplate(template.name,template.DeveloperName, 'html', adminUser.Id,'templateSubject');
        }

        Test.startTest();

        System.runAs(collector) {
            Id jobId = clRouteScheduleSvc.sendRouteScheduleCompletedEmail(routeSchedule.Id);
            System.assert(jobId != null);
        }

        Test.stopTest();
    }
}