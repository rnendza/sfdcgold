@isTest
private class TEST_CommunityHpdController {

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

        system.runAs(adminUser) {
            User user  = TestUtils.getPortalUserForTest(PROFILENAMECP,ACCOUNTNAME,UNAMECP);
            Contact contact = [select id,accountId from contact where id = :user.contactId];
            Account account = [select id, IGB_License__c,type from account where id = :contact.AccountId];
            account.IGB_License__c = '6666666';
            account.type = 'Accel Account';
            update account;
            License__c license = TestUtils.buildGenericIgbLicense(account.Id);
            insert license;
            account.active_igb_gaming_license__C = license.id;
            update account;
            List<Hold_Per_Day__c> holdPerDays = TestUtils.buildAccountHoldPerDays(new List<Account>{account},10,'Monthly HPD');
            insert holdPerDays;
            //@TODO build hold per day total data
        }

    }
    /**
     * @TODO Real asserts! This is Weak ass testing..
     */
    @isTest static void testRetrieveUserLocationsAndHpdData() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId ,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();
            system.debug('running test as cp user='+communityUser + ' accountId='+communityUser);
            ResponseDto dto = Accel_CommunityHpdController.retrieveAccounts();
            List<Account> accounts = (List<Account>)dto.values.get(Accel_CommunityHpdController.MAP_KEY_ACCOUNT_LIST);
            Accel_CommunityHpdController.retrieveAccountHpds(accounts[0].id);
            system.debug(dto);
            Test.stopTest();
        }
    }
    @isTest static void testRetrieveUserLocationsAndHpdDataNegative() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId ,username from user where id = :communityUser.id];
        Id badAccountId = communityUser.id;


        System.runAs(communityUser) {
            Test.startTest();
            Accel_CommunityHpdController.retrieveAccountHpds(communityUser.id);
            Test.stopTest();
        }
    }
}