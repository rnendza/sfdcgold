@IsTest
private class TEST_BatchSample {

    public static String USERNAME_ADMIN = 'acceladmintest@accel.com';

    @testSetup
    static void setup() {

        Integer iNmbrOfMunis=2, iNbrOfAccountsPerMuni = 20;

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {

            List<Municipality__c> munis = TestUtils.createMunicipalities('TEST Muni', iNmbrOfMunis);
            List<Account> accounts = buildAccountsForMunis(munis,iNbrOfAccountsPerMuni);
            insert accounts;
        }
    }

    @isTest
    static void test_fireBatch_Success() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;

            BatchSample b = new BatchSample(iBatchSize);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Success');
        }
    }
    @isTest
    static void test_fireBatch_PartialSuccess() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;

            BatchSample.FORCE_PARTIAL_DML_EXCEPTION = true;
            BatchSample b = new BatchSample(iBatchSize);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            //System.assertEquals(log.Overall_Job_Status__c,'Success');
        }
    }
    /**
     * @param munis
     * @param iNmbrOfAccountsPerMuni
     *
     * @return
     * @todo move to TestUtils
     */
    static List<Account> buildAccountsForMunis(List<Municipality__c> munis,Integer iNmbrOfAccountsPerMuni) {
        List<Account> accounts = new List<Account>();

        for (Municipality__c muni : munis) {
            for (Integer i = 0; i < iNmbrOfAccountsPerMuni; i++) {
                Account account = TestUtils.buildAccount('Test Account ' + i, muni.Id);
                accounts.add(account);
            }
        }
        return accounts;
    }
}