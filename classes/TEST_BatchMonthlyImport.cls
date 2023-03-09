@IsTest
private class TEST_BatchMonthlyImport{

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static Date   CURRENT_DATE_OVERRIDE  = Date.today();

    public static final String HPD_MONTHLY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Monthly_HPD').getName();

    @TestSetup
    static void setup() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            Date TODAY = CURRENT_DATE_OVERRIDE;
            TestUtils.createTestHoldPerDays();
            TestUtils.updateAllHoldPerDaysDate(HPD_MONTHLY_RTNAME,TODAY.addDays(-1));
            //---- clone the Monthly Hpds to 1 year ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-1).addYears(-1));
            //---- clone the Monthly Hpds to 1 year 1 month ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-1).addMonths(-1).addYears(-1));

            Test.stopTest();
        }
    }

    @IsTest
    static void test_fireBatchMonthlyImport_0_Args() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            BatchHpdMonthlyImport b = new BatchHpdMonthlyImport();
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_fireBatchMonthlyImport_1_Args() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            BatchHpdMonthlyImport b = new BatchHpdMonthlyImport(null);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_fireBatchMonthlyImport_2_Args() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            BatchHpdMonthlyImport b = new BatchHpdMonthlyImport(null,true);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_fireBatchMonthlyImport_3_Args() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            List<String> emails = new List<String> { 'blah@blah.com'};
            BatchHpdMonthlyImport b = new BatchHpdMonthlyImport( emails,true,'testjobname');
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_fireBatchMonthlyImport_ForceExceptions() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            BatchHpdMonthlyImport b = new BatchHpdMonthlyImport(null,true,'testjobname',true);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

        }
    }
    @IsTest
    static void test_fireBatchMonthlyImport_Rollback() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            BatchHpdMonthlyImport b = new BatchHpdMonthlyImport(null,false,'testjobna');
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();
        }
    }
}