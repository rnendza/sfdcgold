@isTest
private class TEST_BatchHpdPurge{

    public static String UNAME = 'acceltest@accel.com';
    public static Community_Async_Job_Setting__mdt setting =
            CommunityAsyncSettings.retrieveCommunityAsyncMdt(CommunityAsyncSettings.HPD_PURGE_MDT_TYPE_DEV_NAME );

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
        }
    }

    /**
     *
     */
    @isTest static void test_BatchHpdPurge_Positive() {
        User u = TestUtils.getUserForTest(UNAME);

        List<Hold_Per_Day__c> holdPerDays = [
            SELECT Id, Date__c
            FROM   Hold_Per_Day__c
        ];
        for(Hold_Per_Day__c hpd : holdPerDays) {
            hpd.Date__c = Date.today().addMonths(- Integer.valueOf(setting.Months_Back__c + 1));
        }
        update holdPerDays;

        System.runAs(u) {
            Test.startTest();

            BatchHpdPurge b = new BatchHpdPurge();
            Database.executeBatch(b,Integer.valueOf(setting.Batch_Size__c));

            Test.stopTest();
            //@todo do real calc tests!
        }
    }

    /**
     *
     */
    @isTest static void test_BatchHpdPurge_Positive_Rollback() {
        User u = TestUtils.getUserForTest(UNAME);

        List<Hold_Per_Day__c> holdPerDays = [
                SELECT Id, Date__c
                FROM   Hold_Per_Day__c
        ];
        for(Hold_Per_Day__c hpd : holdPerDays) {
            hpd.Date__c = Date.today().addMonths(- Integer.valueOf(setting.Months_Back__c + 1));
        }
        update holdPerDays;

        System.runAs(u) {
            Test.startTest();

            BatchHpdPurge b = new BatchHpdPurge(true);
            Database.executeBatch(b,Integer.valueOf(setting.Batch_Size__c));

            Test.stopTest();
            //@todo do real calc tests!
        }
    }

    /**
     *
     */
    @isTest static void test_BatchHpdPurge_handleErrors() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();

            Hold_Per_Day__c holdPerDay = [SELECT Id FROM Hold_Per_Day__c LIMIT 1];
            holdPerDay.addError('RecordTypeId','TEST ERROR MSG');
            List<Database.Error> errors = holdPerDay.getErrors();

            BatchHpdPurge b = new BatchHpdPurge();
            b.handleErrors(holdPerDay.Id,errors);

            Test.stopTest();
            //@todo do real calc tests!
        }
    }
}