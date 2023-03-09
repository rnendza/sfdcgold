@IsTest
private class TEST_SvcWatchdogTimerContainerController {

    public static   String  CALLCENTERUNAME     = 'callcenterdude@dude.com';
    public static   User    uCallCenter         = TestUtils.getUserForTest( CALLCENTERUNAME );
    public static final String SVC_WATCHDOG_PERM_SET_API_NAME   = 'Service_Watchdog_Component_Access';
    public static final String SVC_WATCHDOG_PERM_SET_LABEL      = 'Service Watchdog Component Access';

    @TestSetup
    static void setup() {
        TestUtils.createPermissionSetAndAssignment(  SVC_WATCHDOG_PERM_SET_LABEL,SVC_WATCHDOG_PERM_SET_API_NAME,uCallCenter.Id );
    }

    /**
     *  Test that no custom setting exists.
     */
    @IsTest static void test_retrieveSvcWatchdogUtilityBarSettings_negative() {
        System.runAs(uCallCenter) {
            Test.startTest();

            Service_Utility_Bar_Config__c configSetting = SvcWatchdogTimerContainerController.retrieveSvcWatchdogUtilityBarSettings();
            System.assert(configSetting.Id == null);

            Test.stopTest();
        }
    }
    /**
     *  Test that custom setting does exist.
     */
    @IsTest static void test_retrieveSvcWatchdogUtilityBarSettings_positive() {
        TestUtils.createSvcWatchdogUtilityBarSettings(uCallCenter);
        System.runAs(uCallCenter) {
            Test.startTest();

            Service_Utility_Bar_Config__c configSetting = SvcWatchdogTimerContainerController.retrieveSvcWatchdogUtilityBarSettings();
            System.assert(configSetting.Id != null);

            Test.stopTest();
        }
    }
    @IsTest static void test_RetrieveUsersPermissionSetAssignments_Positive() {
        System.runAs(uCallCenter) {
            Test.startTest();
            //-- test that we retrieve every PSA available for the user and that one of thm was the one created in setup.
            System.assert(SvcWatchdogTimerContainerController.isUserInPermissionSet(SVC_WATCHDOG_PERM_SET_API_NAME));
            Test.stopTest();
        }
    }
    @IsTest static void test_RetrieveUsersPermissionSetAssignments_Negative() {
        System.runAs(uCallCenter) {
            Test.startTest();
            System.assert(!SvcWatchdogTimerContainerController.isUserInPermissionSet('blah bogus'));
            Test.stopTest();
        }
    }
}