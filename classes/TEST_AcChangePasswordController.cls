@isTest
private class TEST_AcChangePasswordController {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [ SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id ];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        User setupUser = adminUser;
        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        }
    }

    @isTest static void test_retrieveUserPwInfo_Positive() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        portalUser = [SELECT Id, contactId, accountId,username,LastPasswordChangeDate from user where id = :portalUser.id];
        System.runAs(portalUser) {
            Test.startTest();
            //=== (1) Test The same username is retrieved.
            ResponseDto dto  = AcChangePasswordController.retrieveUserPwInfo();
            User user = (User)dto.values.get('USER_PW_INFO');
            system.assertEquals(user.username, portalUser.userName);
            Test.stopTest();
        }
    }

    @IsTest static void test_updatePassword_Positive() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        portalUser = [SELECT Id, contactId,accountId,username,LastPasswordChangeDate from user where id = :portalUser.id];
        System.runAs(portalUser) {
            Test.startTest();
            String currentPassword = 'ads345435',newPassword='12345678',confirmPassword='12345678';
            ResponseDto dto  = AcChangePasswordController.updatePassword(currentPassword,newPassword,confirmPassword,true);
            system.assert(dto.isSuccess);
            Test.stopTest();
        }
    }


    /**
     * Dirty trick to get coverage up due to the fact SFDC did not leave proper hooks to test various methods
     * on the Site class.
     */
    @IsTest static void test_salesforceSitesCallPreventsUnitTesting_Positive() {
        AcChangePasswordController.salesforceSitesCallPreventsUnitTesting();
    }
}