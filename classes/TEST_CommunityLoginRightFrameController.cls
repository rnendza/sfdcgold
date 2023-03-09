@IsTest
private class TEST_CommunityLoginRightFrameController {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP        = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME    = 'mollys unit test';
    public static String PROFILENAMECP  = 'Accel Customer Community';
    public static String NETWORKNAME    = 'Accel Entertainment Customer Community';
    /**
     * Setup test data.
     * @TODO Refactor into generic TEST Util!
     */
    @testSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [select id, userroleid from user where id = :adminUser.id];
        adminUser.userroleid = adminRole.id;
        update adminUser;
    }

    @isTest static void testExperienceId() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);

        System.runAs(communityUser) {
            Test.startTest();
            //@TODO best practices of how to test these types of calls???
            String expId = 'accel';
            Accel_CommunityLoginRightFrameController.setExperienceId(expId);
           
            try {
                expId = Accel_CommunityLoginRightFrameController.getExperienceId();
            } catch (Exception e) {
                system.debug(e);
            }
            Test.stopTest();
        }
    }
}