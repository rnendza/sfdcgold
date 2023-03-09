@IsTest
private class TEST_BatchSA_HistoricalSolutions{

    public static String USERNAME_ADMIN             = 'acceltestadmin@accelentertainment.com';

    @TestSetup
    static void setup() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            //  @todo params should be set to use more then 1 record but I'm afraid to do anything in bulk these days
            //  as eventually an additional process builder or flow gets added to the stack and trips CPU
            //  Timeout limits and they arch of those is beyond my control.
            TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
            TestUtils.createAllDataToServiceAppointments( params );
            Test.stopTest();
        }
    }

    @IsTest
    static void test_fireBatchSaHistoricalSolutions_Commit_Success() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        List<String> plValues = new List<String>();
        List<Schema.PicklistEntry> plEntries = ServiceAppointment.Solution__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry plEntry : plEntries) {  //  Dyna find good PL Values.
            if(plEntry.active) {
                plValues.add(plEntry.getValue());
            }
        }
        List<ServiceAppointment> testServiceAppointments = [
                SELECT  Id, Solution__c, Accel_Solution__c, Accel_Solution__r.Name
                FROM    ServiceAppointment
        ];
        for(ServiceAppointment sa : testServiceAppointments) {
            sa.Solution__c = plValues[0];  //  Update the SA to have PL val
            sa.Accel_Solution__c = null;
        }
        update testServiceAppointments;
        insert ( new Solution__c(Name = plValues[0] , Status__c = 'Active' ) );

        Integer iTotalSasThatShouldBeUpdated = testServiceAppointments.size();

        System.runAs(adminUser) {
            Test.startTest();

            List<String> emails = new List<String> {'rick@chicagosalesforceconsulting.com'};
            Boolean bCommit = true;
            BatchSA_HistoricalSolutions b = new BatchSA_HistoricalSolutions(emails,bCommit);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            List<ServiceAppointment> serviceAppointmentsUpdated = [
                    SELECT Id, Accel_Solution__c, Solution__c
                    FROM   ServiceAppointment
                    WHERE  Accel_Solution__c != NULL
            ];
            System.assertEquals(serviceAppointmentsUpdated.size(), iTotalSasThatShouldBeUpdated,
                    '# of Service appointments updated should eq ' + iTotalSasThatShouldBeUpdated + ' it does not!');
        }
    }

    @IsTest
    static void test_fireBatchSaHistoricalSolutions_Rollback() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        List<String> plValues = new List<String>();
        List<Schema.PicklistEntry> plEntries = ServiceAppointment.Solution__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry plEntry : plEntries) {  //  Dyna find good PL Values.
            if(plEntry.active) {
                plValues.add(plEntry.getValue());
            }
        }
        List<ServiceAppointment> testServiceAppointments = [
                SELECT  Id, Solution__c, Accel_Solution__c, Accel_Solution__r.Name
                FROM    ServiceAppointment
        ];
        for(ServiceAppointment sa : testServiceAppointments) {
            sa.Solution__c = plValues[0];  //  Update the SA to have PL val
            sa.Accel_Solution__c = null;
        }
        update testServiceAppointments;
        insert ( new Solution__c(Name = plValues[0] , Status__c = 'Active' ) );

        System.runAs(adminUser) {
            Test.startTest();

            BatchSA_HistoricalSolutions b = new BatchSA_HistoricalSolutions();
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            List<ServiceAppointment> serviceAppointmentsUpdated = [
                    SELECT Id, Accel_Solution__c, Solution__c
                    FROM   ServiceAppointment
                    WHERE  Accel_Solution__c != NULL
            ];
            System.assert(serviceAppointmentsUpdated.isEmpty(),'We should not have updated any Service' +
                    ' appointments on a rollback. There were updates.');
        }
    }

    @IsTest
    static void test_fireBatchSaHistoricalSolutions_Commit_ForceException() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        List<String> plValues = new List<String>();
        List<Schema.PicklistEntry> plEntries = ServiceAppointment.Solution__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry plEntry : plEntries) {  //  Dyna find good PL Values.
            if(plEntry.active) {
                plValues.add(plEntry.getValue());
            }
        }
        List<ServiceAppointment> testServiceAppointments = [
                SELECT  Id, Solution__c, Accel_Solution__c, Accel_Solution__r.Name
                FROM    ServiceAppointment
        ];
        for(ServiceAppointment sa : testServiceAppointments) {
            sa.Solution__c = plValues[0];  //  Update the SA to have PL val
            sa.Accel_Solution__c = null;
        }
        update testServiceAppointments;
        insert ( new Solution__c(Name = plValues[0] , Status__c = 'Active' ) );

        System.runAs(adminUser) {
            Test.startTest();

            List<String> emails = new List<String> {'rick@chicagosalesforceconsulting.com'};
            Boolean bCommit = true, bFakeException = true;

            BatchSA_HistoricalSolutions b = new BatchSA_HistoricalSolutions(emails,bCommit, 'TEST_ASYNC_JOB_NAME', bFakeException);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            List<ServiceAppointment> serviceAppointmentsUpdated = [
                    SELECT Id, Accel_Solution__c, Solution__c
                    FROM   ServiceAppointment
                    WHERE  Accel_Solution__c != NULL
            ];
            System.assert(serviceAppointmentsUpdated.isEmpty());
        }
    }
}