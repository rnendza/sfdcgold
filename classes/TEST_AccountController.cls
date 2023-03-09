@isTest
private class TEST_AccountController {
    public static String UNAME = 'acceltest@accel.com';
    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        TestUtils.createTestHoldPerDays();
        HoldsPerDayStatsHelper.reInitHpdTotals();
    }
    /**
     * @TODO Real asserts! This is Weak ass testing..
     */
    @isTest static void testLocationHpdComponentLoad() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();

            system.assert(AccountController.retrieveHpdAccountSettings() != null);

            List<Account> accts = [select id from account];
            Account acct = accts[0];
            ResponseDto dto = AccountController.retrieveHpds(acct.id);
            system.assert( dto.isSuccess );

            List<Hold_Per_Day__c> hpds = [select id from Hold_Per_Day__c];
            delete hpds;
            dto = AccountController.retrieveHpds(acct.id);
            system.assert( !dto.isSuccess );

            Test.stopTest();
        }
    }
    @isTest static void testLocationHpdComponentError() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();
            //---- pass wrong id.. should be an account id.
            ResponseDto dto = AccountController.retrieveHpds(null);
            system.assert( !dto.isSuccess );
            system.debug(dto.severity == 'Warning');

            Test.stopTest();
        }
    }
}