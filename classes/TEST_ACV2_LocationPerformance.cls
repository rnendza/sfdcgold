/**
 *  RJN 8-12-2019 SFCOMM-291515455  Added some real testing for this..
 *  @TODO negative test cases / multiple test cases for stuff other then vgt live date.
 */
@isTest
private class TEST_ACV2_LocationPerformance {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP        = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME    = 'mollys unit test';
    public static String PROFILENAMECP  = 'Accel Customer Community';
    public static String ROLENAME       = 'AdminRoleName';

    /**
     * Setup test data.
     */
    @TestSetup static void setup() {
        User adminUser = TestUtils.createAdminUserWithRole(UNAMEADMIN,ROLENAME);
        UserRole adminRole = new UserRole(DeveloperName = 'TestAdminRole', Name = 'TestAdminRole');
        insert adminRole;
        adminUser = [ SELECT Id, UserRoleId,ContactId FROM User WHERE Id = :adminUser.Id ];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        System.runAs(adminUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
            List<Account> accounts = [ SELECT Id, Accel_VGT_Live_Date__c, Type FROM Account];
            TestUtils.updateAccountsToLiveAccelAccount(accounts);

            List<Hold_Per_Day__c> holdPerDays = TestUtils.buildAccountHoldPerDays(accounts, 2, 'Monthly HPD');
            insert holdPerDays;
            for(Hold_Per_Day__c hpd : holdPerDays) {
                hpd.Date__c = Date.today().toStartOfMonth();
            }
            List<Hold_Per_Day__c> holdPerDaysDaily = TestUtils.buildAccountHoldPerDays(accounts, 2, 'Daily HPD');
            for(Hold_Per_Day__c hpd : holdPerDaysDaily) {
                hpd.Date__c = Date.today();
            }
            insert holdPerDaysDaily;
        }
    }

   /**
    * Test the Accel_LocationPerformanceV2.retrieveCommunitySettings (positive)
    * (1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
    */
    @IsTest static void test_RetrieveCommunityUsereSettings_Positive() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(communityUser.Id, communityUser.ContactId);
        insert cus;

        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_LocationPerformanceV2.retrieveCommunityUserSettings();
            //--(1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting != null);
            System.assert(communityUserSetting.User__c == communityUser.Id);
            Test.stopTest();
        }
    }
    /**
     * Test the Accel_LocationPerformanceV2.retrieveCommunitySettings (negative)
     * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with the running community user
     */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_Negative() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        DELETE [Select Id FROM Community_User_Setting__c];
        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_LocationPerformanceV2.retrieveCommunityUserSettings();
            //--(1) Test that we could *NOT* find the Community_User_Setting__c sObject associated with the running community user.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting == null);
            Test.stopTest();
        }
    }
    /**
     * Test the Accel_LocationPerformanceV2.retrieveCommunitySettings (negative)
     * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with a non community admin user.
     */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_AsAdmin_Negative() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            ResponseDto dto = Accel_LocationPerformanceV2.retrieveCommunityUserSettings();
            Community_User_Setting__c communityUserSetting;
            communityUserSetting = (Community_User_Setting__c) dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting == null);
            System.assert(!dto.isSuccess);
            System.assert(dto.technicalMsg.contains('You are not a valid community user'));
            System.debug(dto);
            Test.stopTest();
        }
    }


    /**
     * @TODO fix this!!
     */
    @isTest static void testAll(){

        Test.startTest();

        ResponseDto dto;
        dto = Accel_LocationPerformanceV2.retrieveAccounts();
        dto = Accel_LocationPerformanceV2.retrieveMonthlyHpdDates();
        // SFCOMM-291515455 Moved call to retrieveAggregateLiveTimeHpdData below.
        dto = Accel_LocationPerformanceV2.retrieveAggregateMonthlyAverages();



        Test.stopTest();
    }
    /**
     * SFCOMM-291515455
     *
     * (1) Test that the response returned successfully when retrieving Agg Lifetime HPD Data.
     * (2) Test that the wrap Accel VGT Live date property was returned to the client.
     */
    @IsTest
    public static void test_retrieveAggregateLifetimeHpdData() {
        User customerPortalUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        System.runAs(customerPortalUser) {

            Test.startTest();
            ResponseDto dto = Accel_LocationPerformanceV2.retrieveAggregateLifetimeHpdData();
            //--(1) Test that the response returned successfully when retrieving Agg Lifetime HPD Data.
            System.assert(dto.isSuccess);
            List<HpdWrapper> aggregateLifeTimeHpdWrappers = (List<HpdWrapper>) dto.values.get(Accel_LocationPerformanceV2.MAP_KEY_HPD_LIST);
            //--(2) Test that the wrap Accel VGT Live date property was returned to the client.
            for (HpdWrapper hpdWrap : aggregateLifeTimeHpdWrappers) {
                System.assert(hpdWrap.accountAccelVgtLiveDate == System.today());
            }
            Test.stopTest();
        }
    }
    /**
     * SFCOMM-291515455
     *
     * (1) Test that the response returned successfully when retrieving Agg Custom HPD Data called.
     * (2) Test that the wrap Accel VGT Live date property was returned to the client.
     * (3) Test that he wrap Accel VGT Live date property was returned to the client.
     */
    @IsTest
    public static void test_retrieveAggregateCustomHpdData() {
        User customerPortalUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        System.runAs(customerPortalUser) {

            Test.startTest();

            String sStartDate = String.valueOf(Date.today().addDays(-180));
            String sEndDate   = String.valueOf(Date.today());
            ResponseDto dto  = Accel_LocationPerformanceV2.retrieveAggregateCustomHpdData(sStartDate,sEndDate);
            //--(1) Test that the response returned successfully when retrieving Agg Custom HPD Data called.
            System.assert(dto.isSuccess);
            List<HpdWrapper> aggregateCustomWrappers = (List<HpdWrapper>) dto.values.get(Accel_LocationPerformanceV2.MAP_KEY_HPD_CUSTOM_DATA);
            //--(2) Test that the wrap Accel VGT Live date property was returned to the client.
            List<Id> accountIds = new List<Id>();
            for (HpdWrapper hpdWrap : aggregateCustomWrappers) {
                System.assert(hpdWrap.accountAccelVgtLiveDate == System.today());
                //--(3) Test that we grouped by account id properly
                System.assert(!accountIds.contains(hpdWrap.accountId));
                accountIds.add(hpdWrap.accountId);
            }
            Test.stopTest();
        }
    }

    /**
     * SFCOMM-291515455
     *
     * (1) Test that the response returned successfully when retrieving Agg Custom HPD Data called.
     * (2) Test that the wrap Accel VGT Live date property was returned to the client.
     */
    @IsTest
    public static void test_retrieveAggregateMonthlyHpdData() {
        User customerPortalUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        System.runAs(customerPortalUser) {

            Test.startTest();

            String sStartOfThisMonth = String.valueOf(Date.today().toStartOfMonth());
            ResponseDto dto  = Accel_LocationPerformanceV2.retrieveAggregateMonthlyHpdData(sStartOfThisMonth);
            //--(1) Test that the response returned successfully when retrieving Agg Custom HPD Data called.
            System.assert(dto.isSuccess);
            List<HpdWrapper> wraps = (List<HpdWrapper>) dto.values.get(Accel_LocationPerformanceV2.MAP_KEY_HPD_MONTHLY_DATA);
            //--(2) Test that the wrap Accel VGT Live date property was returned to the client.
            for (HpdWrapper hpdWrap : wraps) {
                System.assert(hpdWrap.accountAccelVgtLiveDate == System.today());
            }
            Test.stopTest();
        }
    }
    /**
     * Not enhancement related. Just noticed it was not covered
     */
    @IsTest
    public static void test_retrieveSingleAccountAggregateMonthlyAverages() {
        User customerPortalUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        System.runAs(customerPortalUser) {

            Test.startTest();

            Id singleAccountId = [SELECT Id from Account Where Id in (Select Account__c From Hold_Per_Day__c) LIMIT 1].Id;
            ResponseDto dto  = Accel_LocationPerformanceV2.retrieveSingleAccountAggregateMonthlyAverages(singleAccountId);
            //--(1) Test that the response returned successfully when retrieving Agg Custom HPD Data called.
            System.assert(dto.isSuccess);
            //@TODO Test business results.
            Test.stopTest();
        }
    }
}