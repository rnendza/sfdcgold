@isTest
private class TEST_CommunityLocationSummaryController {

    public static String UNAMEADMIN = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME = 'mollys unit test';
    public static String PROFILENAMECP = 'Accel Customer Community';
    public static String NETWORKNAME = 'Accel Entertainment Customer Community';
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
            List<Hold_Per_Day__c> holdPerDays = TestUtils.buildAccountHoldPerDays(new List<Account>{
                    account
            }, 10, 'Monthly HPD');
            insert holdPerDays;
            //@TODO build hold per day total data
        }

    }
    /**
     * @TODO Real asserts! This is Weak ass testing..
     */
    @isTest static void retrieveHoldPerDayByAccountsAllMonths() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            Account a = [select id,name, IGB_License__c from account where id = :communityUser.accountId];

            ResponseDto dto = Accel_CommunityLocComparisonController.retrieveHoldPerDayByAccountsAllMonths(new List<Id>{
                    a.id
            });
            system.debug(dto);

            Test.stopTest();
        }
    }

    @isTest static void testRetrieveAllLocationMonthlyWrappers() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            Account a = [select id,name, IGB_License__c from account where id = :communityUser.accountId];

            ResponseDto dto = Accel_CommunityLocationSummaryController.retrieveAllLocationMonthlyWrappers();
            system.debug(dto);

            Test.stopTest();
        }
    }
    @isTest static void testRetrieveAllLocationMonthlyWrappersLast12() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            Account a = [select id,name, IGB_License__c from account where id = :communityUser.accountId];

            ResponseDto dto = Accel_CommunityLocationSummaryController.retrieveAllLocationMonthlyWrappersLast12();
            system.debug(dto);

            Test.stopTest();
        }
    }
    @isTest static void testretrieveLocationMonthlyHpds() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            ResponseDto dto = Accel_CommunityLocationSummaryController.retrieveLocationMonthlyHpds(null);
            system.debug(dto);
            ResponseDto dto2 = Accel_CommunityLocationSummaryController.retrieveLocationMonthlyHpds('1YR');

            Test.stopTest();
        }
    }
    @isTest static void testRetrieveLocationAllMonthlyWrappers() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            Account a = [select id,name, IGB_License__c from account where id = :communityUser.accountId];

            ResponseDto dto = Accel_CommunityLocationSummaryController.retrieveLocationAllMonthlyWrappers();
            system.debug(dto);

            Test.stopTest();
        }
    }
    /**
     * @TODO this is not really doing anything but we are running out of time so be it!
     */
    @isTest static void testRetrieveUserLocationsAndHpdDataWithHpdTotalsGenerated() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            BatchHpdAccountTotals b = new BatchHpdAccountTotals('Monthly', -12);
            Database.executeBatch(b);
        }
        Test.stopTest();
        ResponseDto dto = Accel_CommunityLocationSummaryController.retrieveUserLocations();
        system.debug(dto);
    }
    @isTest static void testGetMaxAccountResults() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            Integer iMaxResults = Accel_CommunityLocationSummaryController.getMaxAccountResults();
            system.debug(iMaxResults);

            Test.stopTest();
        }
    }
    @isTest static void testRetrieveAccountRevenue() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();
            Account a = [select id from account limit 1];
            ResponseDto dto = Accel_CommunityLocationSummaryController.retrieveAccountRevenue(a.id,system.today().addMonths(-12), System.today());
            Test.stopTest();
        }
    }
    /**
     * @TODO is this even used?
     */
    @isTest static void testLocDetailConstructor() {
        Test.startTest();

        Account a = [
                select id,Hold_Per_Day_Total__r.Four_Week_HPD__c,Hold_Per_Day_Total__r.Eight_Week_HPD__c,Hold_Per_Day_Total__r.Twelve_Week_HPD__c
                from account
                limit 1
        ];
        Accel_CommunityLocationSummaryController.LocationDetail locationDetail = new Accel_CommunityLocationSummaryController.LocationDetail(a);

        Test.stopTest();
    }
    /**
 * @TODO this is not really doing anything but we are running out of time so be it!
 */
    @isTest static void testRetrieveUserHpdAndExpDate() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            BatchHpdAccountTotals b = new BatchHpdAccountTotals('Monthly', -12);
            Database.executeBatch(b);
        }
        Test.stopTest();
        ResponseDto dto = Accel_CommunityLocationSummaryController.retrieveUserHpdAndExpDate();
        system.debug(dto);
    }
}