@IsTest
private class clQueueableRpsEmailerTest {

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
    static void test_fireQueueable_allargs_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT Id,Notes__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];

        Integer i = 0;
        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Notes__c = 'blah notes ' + i;
            i++;
        }
        update rpss;

        Test.startTest();

        System.runAs(processor) {
            clQueueableRpsEmailer queueable =
                    new clQueueableRpsEmailer(routeSchedule.Id,clTESTUTILS.PUBLIC_GROUP_NAME, clQueueableRpsEmailer.DEFAULT_TEMPLATE_DEV_NAME);
            Id jobId = System.enqueueJob(queueable);
        }
        Test.stopTest();
        // @todo asserts here...
    }


    @IsTest
    static void test_fireQueueable_onearg_positive() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [
                SELECT Id,Notes__c,M3T_Crash_Bag_Number__c,NRT_20_Cassette_Number__c,
                        Coin_Bag_Number__c,Location_Funds_In_Field_Value__c,Crash_Bag_Number__c,
                        Route_End_Email_Sent_by__c,Route_End_Email_Sent_Date__c
                FROM Route_Processing_Sheet__c
                WHERE Route_Schedule__c = :routeSchedule.Id
        ];

        Integer i = 0;
        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Notes__c = 'blah notes ' + i;
            //rps.Location_Funds_In_Field_Value__c ='dfasdfs';
            rps.Crash_Bag_Number__c = 'adfsdsa';
        }
        update rpss;

        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(DEFAULT_OWA_EMAIL_ADDRESS);
        EmailTemplate template = [SELECT Id,Name,DeveloperName FROM EmailTemplate WHERE DeveloperName = :clQueueableRpsEmailer.DEFAULT_TEMPLATE_DEV_NAME];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        User adminUser = new User(Id=UserInfo.getUserId());

        Test.startTest();

        System.runAs(adminUser) {
            EmailTemplate emailTemplate = TestUtils.buildEmailTemplate(template.name,template.DeveloperName, 'html', adminUser.Id,'templateSubject');

            clQueueableRpsEmailer queueable = new clQueueableRpsEmailer(routeSchedule.Id);
            Id jobId = System.enqueueJob(queueable);
        }
        Test.stopTest();

        Route_Schedule__c rs = [
                SELECT Id, Route_End_Email_Sent_Date__c,Route_End_Email_Sent_By__c
                FROM   Route_Schedule__c
                WHERE  Id = :routeSchedule.Id
        ];
        System.assertEquals(rs.Route_End_Email_Sent_by__c,UserInfo.getUserId());
        System.assertNotEquals(rs,null); //  too difficult to try to assert by the millisecond.


        List<Route_Processing_Sheet__c> rpssDone = [
                SELECT Id,Route_End_Email_Sent_by__c,Route_End_Email_Sent_Date__c
                FROM Route_Processing_Sheet__c
                WHERE Route_Schedule__c = :routeSchedule.Id
        ];
        for(Route_Processing_Sheet__c rpsDone : rpssDone) {
            System.assertEquals(rpsDone.Route_End_Email_Sent_by__c,UserInfo.getUserId());
            System.assertNotEquals(rpsDone.Route_End_Email_Sent_Date__c,null); //  too difficult to try to assert by the millisecond.
        }
    }
    @IsTest
    static void test_fireQueueable_skipped_status() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [
                SELECT Id,Notes__c,M3T_Crash_Bag_Number__c,NRT_20_Cassette_Number__c,
                        Coin_Bag_Number__c,Location_Funds_In_Field_Value__c,Crash_Bag_Number__c
                FROM Route_Processing_Sheet__c
                WHERE Route_Schedule__c = :routeSchedule.Id
        ];

        Integer i = 0;
        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Status__c = 'Skipped';
            i++;
        }
        update rpss;

        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(DEFAULT_OWA_EMAIL_ADDRESS);
        EmailTemplate template = [SELECT Id,Name,DeveloperName FROM EmailTemplate WHERE DeveloperName = :clQueueableRpsEmailer.DEFAULT_TEMPLATE_DEV_NAME];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        User adminUser = new User(Id=UserInfo.getUserId());

        Test.startTest();

        System.runAs(adminUser) {
            EmailTemplate emailTemplate = TestUtils.buildEmailTemplate(template.name,template.DeveloperName, 'html', adminUser.Id,'templateSubject');

            clQueueableRpsEmailer queueable = new clQueueableRpsEmailer(routeSchedule.Id);
            Id jobId = System.enqueueJob(queueable);
        }
        Test.stopTest();
        // @todo asserts here...
    }
    @IsTest
    static void test_fireQueueable_onearg_positive_novalues() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [
                SELECT Id,Notes__c,M3T_Crash_Bag_Number__c,NRT_20_Cassette_Number__c,
                        Coin_Bag_Number__c,Location_Funds_In_Field_Value__c,Crash_Bag_Number__c
                FROM Route_Processing_Sheet__c
                WHERE Route_Schedule__c = :routeSchedule.Id
        ];

        Integer i = 0;
        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Notes__c = null;
            i++;
        }
        update rpss;

        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(DEFAULT_OWA_EMAIL_ADDRESS);
        EmailTemplate template = [SELECT Id,Name,DeveloperName FROM EmailTemplate WHERE DeveloperName = :clQueueableRpsEmailer.DEFAULT_TEMPLATE_DEV_NAME];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        User adminUser = new User(Id=UserInfo.getUserId());

        Test.startTest();

        System.runAs(adminUser) {
            EmailTemplate emailTemplate = TestUtils.buildEmailTemplate(template.name,template.DeveloperName, 'html', adminUser.Id,'templateSubject');

            clQueueableRpsEmailer queueable = new clQueueableRpsEmailer(routeSchedule.Id);
            Id jobId = System.enqueueJob(queueable);
        }
        Test.stopTest();
        // @todo asserts here...
    }
    @IsTest
    static void test_fireQueueable_onearg_on_values_entered() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT Id,Notes__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];

        Integer i = 0;
        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Notes__c = null;
            i++;
        }
        update rpss;

        EmailTemplate template = [SELECT Id,Name,DeveloperName FROM EmailTemplate WHERE DeveloperName = :clQueueableRpsEmailer.DEFAULT_TEMPLATE_DEV_NAME];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        User adminUser = new User(Id=UserInfo.getUserId());

        Test.startTest();

        System.runAs(adminUser) {
            EmailTemplate emailTemplate = TestUtils.buildEmailTemplate(template.name,template.DeveloperName, 'html', adminUser.Id,'templateSubject');

            clQueueableRpsEmailer queueable = new clQueueableRpsEmailer(routeSchedule.Id);
            Id jobId = System.enqueueJob(queueable);
        }
        Test.stopTest();
        // @todo asserts here...
    }

    @IsTest
    static void test_isFieldBlank() {

        User adminUser = new User(Id=UserInfo.getUserId());

        Test.startTest();

        System.runAs(adminUser) {
            System.assertEquals(new clQueueableRpsEmailer().isFieldBlank(null),true);
            System.assertEquals(new clQueueableRpsEmailer().isFieldBlank(clQueueableRpsEmailer.NO_SURVEY_VALUE_DISPLAY),true);
            System.assertEquals(new clQueueableRpsEmailer().isFieldBlank(5),false);
            System.assertEquals(new clQueueableRpsEmailer().isFieldBlank('testvalue'),false);
        }
        Test.stopTest();

    }
}