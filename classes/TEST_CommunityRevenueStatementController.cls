@isTest
private class TEST_CommunityRevenueStatementController {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP        = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME    = 'mollys unit test';
    public static String PROFILENAMECP  = 'Accel Customer Community';
    public static String ROLENAME       = 'AdminRoleName';
    /**
     * Setup test data.
     * @TODO Refactor into generic TEST Util!
     */
    @testSetup static void setup() {
        User adminUser = TestUtils.createAdminUserWithRole(UNAMEADMIN,ROLENAME);

        system.runAs(adminUser) {
            User user = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
            Contact contact = [select id,accountId from contact where id = :user.contactId];
            Account account = [select id, IGB_License__c,type from account where id = :contact.AccountId];
            account.IGB_License__c = '6666666';
            account.type = 'Accel Account';
            update account;
            License__c license = TestUtils.buildGenericIgbLicense(account.Id);
            insert license;
            account.active_igb_gaming_license__C = license.id;
            update account;

            List<Asset> assets = new List<Asset>();
            Asset ass1 = TestUtils.buildAsset('ass1',account.id,'VGT');
            Asset ass2 = TestUtils.buildAsset('ass2',account.id,'VGT');
            assets.add(ass1);assets.add(ass2);
            insert assets;

            List<Hold_Per_Day__c> holdPerDaysAssets = TestUtils.buildAssetHoldPerDays(assets, 2,'Daily HPD');
            insert holdPerDaysAssets;

        }

    }
    /**
     * @TODO Real asserts! This is Weak ass testing..
     */
    @isTest static void testRetrieveAccounts() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            ResponseDto dto = Accel_RevenueStatementController.retrieveAccounts();
            List<Account> accounts = (List<Account>) dto.values.get(Accel_RevenueStatementController.MAP_KEY_ACCOUNT_LIST);
            system.assert(accounts.size() > 0);


            Test.stopTest();
        }
    }
    /**
     * @TODO Real asserts! This is Weak ass testing..
     */
    @isTest static void testRetrieveHoldPerDayByAccount() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        Contact contact = [select id,accountId from contact where id = :communityUser.contactId];
        Account account = [select id, IGB_License__c,type from account where id = :contact.AccountId];

        System.runAs(communityUser) {

            Test.startTest();

            String sStartDate = JSON.serialize(System.today().addDays(-35));
            String sEndDate = JSON.serialize(System.today());

            ResponseDto dto = Accel_RevenueStatementController.retrieveHoldPerDayByAccount(account.Id,sStartDate,sEndDate);
            List<HpdWrapper> hpdWraps = (List<HpdWrapper>) dto.values.get('HPD_WRAPPER_LIST');
            system.assert(hpdWraps.size() > 0);


            Test.stopTest();
        }
    }
}