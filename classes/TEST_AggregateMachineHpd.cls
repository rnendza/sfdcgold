/**
 * Note. I'm real not fluent on the exact behavior of this class but doing my best to test it as is.
 * 8-21-2019  @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
 */
@IsTest
private class TEST_AggregateMachineHpd {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';

    /**
     * Inserts an admin user,
     * Creates municipalities, accounts / monthly / daily hold per da;ys... etc (TestUtils.createTestHoldPerDays)
     * Updates the date__c on daily hold per day records to today.
     * Clones the dailies and inserts yesterdays dailies as well.
     */
    @TestSetup static void setup() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        system.runAs(adminUser) {

            TestUtils.createTestHoldPerDays();
            List<Account> accounts = [ SELECT Id, Accel_VGT_Live_Date__c, Type FROM Account];

            //There is probably some process builder or Flow something ... grrrr. that is forcing this back to 'Prospect Account on Insert
            //even though they are inserted as Accel Account.. update to get back to accel account.
            for(Account account : accounts) {
                account.Accel_VGT_Live_Date__c = Date.today();
                account.Type = 'Accel Account';
            }
            update accounts;
            List<Hold_Per_Day__c> allDailyHpds = [
                    SELECT  Id, Date__c
                    FROM    Hold_Per_Day__c
                    WHERE   RecordType.Name = 'Daily HPD'
            ];
            for(Hold_Per_Day__c hpd : allDailyHpds) {
                hpd.date__c = Date.today();
            }
            update allDailyHpds;
            List<Hold_Per_Day__c> yesterdayHpds = new List<Hold_Per_Day__c>();
            for(Hold_Per_Day__c hpdToday : allDailyHpds) {
                Hold_Per_Day__c clonedHpd = hpdToday.clone(false);
                clonedHpd.Date__c = hpdToday.Date__c.addDays(-1);
                yesterdayHpds.add(clonedHpd);
            }
            insert yesterdayHpds;
        }
    }
    /**
     *
     */
    @IsTest
    static void test_AggregateMachineHpd_Queueable_Positive() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {

            Test.startTest();
            System.enqueueJob(new AggregateMachineHpd() );
            Test.stopTest();

            List<Hold_Per_Day__c> dailyAggs = [
                    SELECT  Id, CreatedDate, Date__c, RecordType.DeveloperName
                    FROM    Hold_Per_Day__c
                    WHERE   RecordType.DeveloperName = 'Daily_Aggregate'
            ];
            System.assert(dailyAggs.size() == 5);

            for(Hold_Per_Day__c dailyAgg : dailyAggs) {
                System.assertEquals(dailyAgg.RecordType.DeveloperName,'Daily_Aggregate');
            }
        }
    }
    /**
     *  Forces a DML Exception upon
     */
    @IsTest
    static void test_AggregateMachineHpd_Queueable_NegativeDmlEx() {
        //-- @TODO Im not sure what the need is for a catch of a DML Ex on the insert is but
        //---one will need to get tricky here to force that? perhaps lock the entire HPD Object?
    }
    /**
     *
     */
    @IsTest
    static void test_AggregateMachineHpd_insertNewSpecificHpd_Positive() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {

            Test.startTest();

            new AggregateMachineHpd().insertNewSpecificHpd( Date.today().format() );

            List<Hold_Per_Day__c> dailyAggs = [
                    SELECT  Id, CreatedDate, Date__c, RecordType.DeveloperName
                    FROM    Hold_Per_Day__c
                    WHERE   RecordType.DeveloperName = 'Daily_Aggregate'
            ];
            System.assertEquals(dailyAggs.size(),4);

            for(Hold_Per_Day__c dailyAgg : dailyAggs) {
                System.assertEquals(dailyAgg.RecordType.DeveloperName,'Daily_Aggregate');
            }
            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void test_AggregateMachineHpd_insertNewSpecificHpd_NegativeDmlEx() {
        //-- @TODO Im not sure what the need is for a catch of a DML Ex on the insert is but
        //---one will need to get tricky here to force that? perhaps lock the entire HPD Object?
    }
}