@IsTest
private class TEST_ACV2_LocationComparison {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    public static Date CURRENT_DATE_OVERRIDE    = Date.today();
    public static Time time_1100                = Time.newInstance(11,0,0,0);
    public static Time time_0500                = Time.newInstance(05,0,0,0);

    public static final String HPD_DAILY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Daily_HPD').getName();
    public static final String HPD_MONTHLY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Monthly_HPD').getName();

    /**
      * Inserts an admin user, sets the role on the admin user and then creates a community users.
      * Creates municipalities, accounts / monthly / daily hold per da;ys... etc (TestUtils.createTestHoldPerDays)
      * Updates accounts to be live accel accounts.
      *
      * Sets hpd dates to 1 day back
      * Creates Daily HPDs for a month ago.
      * Creates Daily HPDs for a year ago.
      * Creates Monthly HPDS for a month ago.
      * Creates Monthly HPDS for a year ago.
      * Creates Monthly HPPDS for 1 year and 1 month ago.
      *
      * Sets hpds dates to 2 days back
      * Repeat above.
      *
      * Aggregate last months dailies.
      */
    @TestSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [ SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id ];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        User setupUser = adminUser;

        Date TODAY = CURRENT_DATE_OVERRIDE;
        System.debug(LoggingLevel.DEBUG,'accel ----  running all tests with TODAY ='+TODAY+'SETUP USER ='+setupUser);

        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

            Test.startTest();

            TestUtils.createTestHoldPerDays();
            List<Account> accounts = [
                    SELECT  Id, ShippingCity,ShippingStreet,ShippingState,ShippingPostalCode,ShippingCountry
                            ,Accel_VGT_Live_Date__c, Type,ShippingLatitude,ShippingLongitude,
                            Location_Type__c
                    FROM    Account
            ];
            // update will occur in TestUtils.updateAccountToLiveAccelAccounts.
            // make sure the trigger does not try to call out to the service to get county are we will blow the
            // queuable stack depth
            QueueableMuniUpdater.makeCallout = false;
            for(Account account : accounts) {
                account.ShippingStreet = '2221 S Perryville Rd';
                account.ShippingCity = 'Rockford';
                account.ShippingPostalCode = '61108';
                account.ShippingState = 'IL';
                account.ShippingCountry ='USA';
                account.ShippingLatitude = 39.570086;
                account.ShippingLongitude = -76.070007;
                account.Location_Type__c = 'Bar';
            }
            TestUtils.updateAccountsToLiveAccelAccount(accounts);

            //--- this crap is always 1 day back so update regardless of what test utils original set as.
            TestUtils.updateAllHoldPerDaysDate(HPD_DAILY_RTNAME,TODAY.addDays(-1));
            TestUtils.updateAllHoldPerDaysDate(HPD_MONTHLY_RTNAME,TODAY.addDays(-1));

            //---- clone the daily hpds and create them 1 month ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_DAILY_RTNAME,TODAY.addDays(-1).addMonths(-1));
            //---- clone the daily hpds and create them 1 year ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_DAILY_RTNAME,TODAY.addDays(-1).addYears(-1));
            //---- clone the Monthly Hpds to 1 year ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-1).addYears(-1));
            //---- clone the Monthly Hpds to 1 year 1 month ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-1).addMonths(-1).addYears(-1));

            //----- clone the dailys and months and create theme  2 days for HPD Dark stuff.
            TestUtils.cloneAndCreateHoldPerDays(HPD_DAILY_RTNAME,TODAY.addDays(-2));
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-2));
            //---- clone the daily hpds and create them 1 month ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_DAILY_RTNAME,TODAY.addDays(-2).addMonths(-1));
            //---- clone the daily hpds and create them 1 year ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_DAILY_RTNAME,TODAY.addDays(-2).addYears(-1));
            //---- clone the Monthly Hpds to 1 year ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-2).addYears(-1));
            //---- clone the Monthly Hpds to 1 year 1 month ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-2).addMonths(-1).addYears(-1));

            //----- Fake the Aggregation  to aggregate last month daily hpds until today for good measure.
            //  Similar to the AggregateMachineHpd class.
            Date startDate = TODAY.addDays(-2).addMonths(-1).toStartOfMonth();
            Date endDate   = TODAY;
            TestUtils.aggregateDailyHoldPerDays(startDate,endDate);
            //--- are are not creating 2K so we need to do this!
            Batch_Settings__c batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-1);
            upsert batchSettings;

            City__c city = new City__c();
            city.Name = 'Rockford';
            insert city;

            Test.stopTest();
        }
    }



    /**
     * Test the Accel_CommunityLocationComparison.retrieveCommunitySettings (positive)
     * (1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
     */
    @IsTest static void test_RetrieveCommunityUsereSettings_Positive() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(communityUser.Id, communityUser.ContactId);
        insert cus;

        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_CommunityLocationComparison.retrieveCommunityUserSettings();
            //--(1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting != null);
            System.assert(communityUserSetting.User__c == communityUser.Id);
            Test.stopTest();
        }
    }
    /**
     * Test the Accel_CommunityLocationComparison.retrieveCommunitySettings (negative)
     * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with the running community user
     */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_Negative() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        DELETE [Select Id FROM Community_User_Setting__c];
        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_CommunityLocationComparison.retrieveCommunityUserSettings();
            //--(1) Test that we could *NOT* find the Community_User_Setting__c sObject associated with the running community user.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting == null);
            Test.stopTest();
        }
    }
    /**
     * Test the Accel_CommunityLocationComparison.retrieveCommunitySettings (negative)
     * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with a non community admin user.
     */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_AsAdmin_Negative() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            ResponseDto dto = Accel_CommunityLocationComparison.retrieveCommunityUserSettings();
            Community_User_Setting__c communityUserSetting;
            communityUserSetting = (Community_User_Setting__c) dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting == null);
            System.assert(!dto.isSuccess);
            System.assert(dto.technicalMsg.contains('You are not a valid community user'));
            System.debug(dto);
            Test.stopTest();
        }
    }

    @isTest
    static void test_getCity() {
        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        System.runAs(communityUser) {
            Test.startTest();
            Accel_CommunityLocationComparison.getCity('Rockford');
            Test.stopTest();
        }
    }

    @isTest
    static void test_retrieveAccounts() {
        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_CommunityLocationComparison.retrieveAccounts();
            Test.stopTest();
        }
    }

    @isTest
    static void test_getRadiusHpds() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        Account account = [SELECT Id FROM Account LIMIT 1];

        System.runAs(communityUser) {

            Test.startTest();
            String  locType = 'All';
            Double dist = 100;
            Date hpdDate = Date.today().addMonths(-3);
            ResponseDto dto = Accel_CommunityLocationComparison.getRadiusHpds( account.Id, locType,dist,hpdDate);
            locType = 'Bar';
            dto = Accel_CommunityLocationComparison.getRadiusHpds( account.Id, locType,dist,hpdDate);
            Test.stopTest();
        }
    }

    @isTest
    static void test_getRadiusYoYHpds() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        Account account = [SELECT Id FROM Account LIMIT 1];

        System.runAs(communityUser) {

            Test.startTest();
            String  locType = 'All';
            Double dist = 100;
            Date hpdDate = Date.today().addMonths(-3);
            ResponseDto dto = Accel_CommunityLocationComparison.getRadiusYoYHpds( account.Id, locType,dist,hpdDate);
            locType = 'Bar';
            dto = Accel_CommunityLocationComparison.getRadiusYoYHpds( account.Id, locType,dist,hpdDate);
            Test.stopTest();
        }
    }

    @isTest
    static void test_getCityHpds() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

        System.runAs(communityUser) {

            Test.startTest();
            String cityName = 'Rockford';
            Date hpdDate = Date.today().addMonths(-3);
            ResponseDto dto = Accel_CommunityLocationComparison.getCityHpds(cityName,hpdDate);
            Test.stopTest();
        }
    }


    @isTest
    static void test_getCityYoYHpds() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

        System.runAs(communityUser) {

            Test.startTest();
            String cityName = 'Rockford';
            Date hpdDate = Date.today();
            ResponseDto dto = Accel_CommunityLocationComparison.getCityYoYHpds(cityName,hpdDate);
            Test.stopTest();
        }
    }

    @isTest
    static void test_getAllHpds() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

        System.runAs(communityUser) {

            Test.startTest();
            String locType = 'Bar';
            Date hpdDate = Date.today();
            ResponseDto dto = Accel_CommunityLocationComparison.getAllHpds(locType,hpdDate);
            locType = 'All';
            dto = Accel_CommunityLocationComparison.getAllHpds(locType,hpdDate);
            Test.stopTest();
        }
    }

    @isTest
    static void test_getAllYoYHpds() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

        System.runAs(communityUser) {

            Test.startTest();
            String locType = 'Bar';
            Date hpdDate = Date.today();
            ResponseDto dto = Accel_CommunityLocationComparison.getAllYoyHpds(locType,hpdDate);
            locType = 'All';
            dto = Accel_CommunityLocationComparison.getAllYoyHpds(locType,hpdDate);
            Test.stopTest();
        }
    }
}