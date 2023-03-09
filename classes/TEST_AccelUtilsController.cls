@IsTest
private class TEST_AccelUtilsController {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP        = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME    = 'Blah Random UT Account';
    public static String PROFILENAMECP  = 'Accel Customer Community';

    /**
     * Create a portal user
     */
    @TestSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [select id, userroleid from user where id = :adminUser.id];
        adminUser.userroleid = adminRole.id;
        update adminUser;

        system.runAs(adminUser) {
            User user = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        }
    }
    /**
     *
     */
    @IsTest static void test_retrieveCommunitySystemSettings_Positive() {
        User communityUser = TestUtils.getUserForTest(UNAMECP);

        System.runAs(communityUser) {
            Test.startTest();
            Community_Setting__mdt setting = AccelUtilsController.retrieveCommunitySystemSettings();
            System.assert(setting != null);
            Test.stopTest();
        }
    }
}