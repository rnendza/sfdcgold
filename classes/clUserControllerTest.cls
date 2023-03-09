@IsTest
private class clUserControllerTest {

    public static String UNAMEADMIN = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP = 'accelcustomerportal@portal.com';
    public static String UNAMECP2 = 'accelcustomerportal2@portal.com';
    public static String ACCOUNTNAME = 'Blah Random UT Account';
    public static String PROFILENAMECP = 'Accel Customer Community';

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        //  Relationship manager user stuff for send of portal user create email
        User rmUser = TestUtils.getUserForTest('rm@accel.com');
        UserRole rmRole = new UserRole(DeveloperName = 'RMRole', Name = 'TestRMRole');
        insert rmRole;
        rmUser = [SELECT Id, UserRoleId FROM User WHERE Id = :rmUser.Id];
        rmUser.UserRoleId = rmRole.Id;
        update rmUser;


        User setupUser = adminUser;
        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP2);
        }
    }

    @IsTest
    static void test_getUserDetails() {
        User u = TestUtils.getUserForTest(UNAMECP);
        System.runAs(u) {
            u = [SELECT Id, ProfileId FROM User WHERE Id = :u.Id];
            Test.startTest();

            User tstUser = clUserController.retrieveUserDetails(u.Id);
            System.assertEquals(u.Id,tstUser.Id);

            Test.stopTest();
        }
    }
}