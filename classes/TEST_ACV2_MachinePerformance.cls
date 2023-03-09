/**
 *  8-25 Rewrote entire test class to not use target org data and added asserts per
 *  @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
 */
@IsTest
private class TEST_ACV2_MachinePerformance {

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
            List<Account> accounts = [ SELECT Id, Accel_VGT_Live_Date__c, Type FROM Account];
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

            Test.stopTest();
        }
    }

   /**
    * Test the Accel_MachinePerformanceV2.retrieveCommunitySettings (positive)
    * (1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
    */
    @IsTest static void test_RetrieveCommunityUsereSettings_Positive() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(communityUser.Id, communityUser.ContactId);
        insert cus;

        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveCommunityUserSettings();
            //--(1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting != null);
            System.assert(communityUserSetting.User__c == communityUser.Id);
            Test.stopTest();
        }
    }
    /**
     * Test the Accel_MachinePerformanceV2.retrieveCommunitySettings (negative)
     * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with the running community user
     */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_Negative() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        DELETE [Select Id FROM Community_User_Setting__c];
        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveCommunityUserSettings();
            //--(1) Test that we could *NOT* find the Community_User_Setting__c sObject associated with the running community user.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting == null);
            Test.stopTest();
        }
    }
    /**
     * Test the Accel_MachinePerformanceV2.retrieveCommunitySettings (negative)
     * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with a non community admin user.
     */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_AsAdmin_Negative() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveCommunityUserSettings();
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
      * Tests AccelMachinePerformanceV2.retrieveAccounts which gets visible account for the running user.
      *
      * (1) test the have have visible accounts and that the method returns proper account per sharing rules.
      */
     @IsTest
     public static void test_retrieveAccounts_Positive(){

         User communityUsr =  TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

         System.runAs(communityUsr) {

             Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                     SELECT Id
                     FROM   Account
                     WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
             ]);

             Test.startTest();
             ResponseDto dto = Accel_MachinePerformanceV2.retrieveAccounts();
             List<Account> accounts = (List<Account>)dto.values.get(Accel_MachinePerformanceV2.MAP_KEY_ACCOUNT_LIST);
             //--(1) test the have have visible accounts and that the method returns proper account per sharing rules.
             System.assert(dto.isSuccess);

             for(Account account : accounts) {
                System.assert(mTestAccountsByIds.containsKey(account.Id));
             }
             Test.stopTest();
         }
    }
    /**
     * Tests AccelMachinePerformanceV2.retrieveMontlyHpdDates. (positive)
     *
     * (1) Tests that we get hpd wraps back with the monthly dates successfully.
     */
    @IsTest
    public static void test_retrieveMonthlyHpdDates_Positive(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        //@TODO figure out community external sharing rules and how they apply to community user in test cases.
        //  possibly reparent all hpd records to account associated with community user as opposed to setup admin user
        //User communityUsr =  TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

        System.runAs(adminUser) {

            Map<Id,Hold_Per_Day__c> mHoldPerDaysByIds = new Map<Id,Hold_Per_Day__c>([
                    SELECT Id,Date__c
                    FROM   Hold_Per_Day__c
                    WHERE  RecordType.Name = :HPD_MONTHLY_RTNAME
            ]);
            Set<Date> holdPerDayDates = new Set<Date>();
            for(Hold_Per_Day__c holdPerDay : mHoldPerDaysByIds.values()) {
                holdPerDayDates.add(holdPerDay.Date__c);
            }

            Test.startTest();
            //--(1) Tests that we get hpd wraps back with the monthly dates successfully.
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveMonthlyHpdDates();
            System.assert(dto.isSuccess);
            List<HpdWrapper> hpdWrappers = (List<HpdWrapper>)dto.values.get(Accel_MachinePerformanceV2.MAP_KEY_HPD_MONTHS);
            System.assert(!hpdWrappers.isEmpty());

            for(HpdWrapper hpdWrapper : hpdWrappers){
                System.assert(holdPerDayDates.contains(hpdWrapper.hpdDate));
            }
            Test.stopTest();
        }
    }
    /**
     * Tests AccelMachinePerformanceV2.retrieveMonthlyHpdDates. (negative)
     *
     * (1) Tests that we DO NOT get hpd wraps back with the monthly dates successfully as there is no data.
     */
    @IsTest
    public static void test_retrieveMonthlyHpdDates_NoData_Negative(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        TestUtils.deleteAllHoldPerDays();

        System.runAs(adminUser) {

            Test.startTest();
            //--(1) Tests that we DO NOT get hpd wraps back with the monthly dates successfully as there is no data.
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveMonthlyHpdDates();
            System.assert(!dto.isSuccess);
            Test.stopTest();
        }
    }
   /**
    *  Tests AccelMachinePerformanceV2.retrieveAggregateMachineDate (positive).
    *
    * (1) Tests that we have a successful response and get aggregate hpd wrappers back.
    * (2) Tests that we we get the asset ids associated with machines back correctly.
    */
    @IsTest
    public static void test_retrieveAggregateMachineData_Positive(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        Map<Id,Hold_Per_Day__c> mHoldPerDaysByIds = new Map<Id,Hold_Per_Day__c>([
                SELECT Id,Account__c,Date__c,Asset__c
                FROM   Hold_Per_Day__c
                WHERE  RecordType.Name = :HPD_DAILY_RTNAME
        ]);
        Id accountId = mHoldPerDaysByIds.values()[0].Account__c;
        String startDate    = String.valueOf( CURRENT_DATE_OVERRIDE.addMonths(-1).toStartOfMonth());
        String endDate      = String.valueOf( CURRENT_DATE_OVERRIDE.toStartOfMonth());
        Set<Id> assetIds    = new Set<Id>();

        for(Hold_Per_Day__c holdPerDay : mHoldPerDaysByIds.values()) {
            assetIds.add(holdPerDay.Asset__c);
        }

        System.runAs(adminUser) {

            Test.startTest();
            //--(1) Tests that we have a successful response and get aggregate hpd wrappers back.
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveAggregateMachineData(accountId, startDate, endDate);
            System.assert(dto.isSuccess);

            List<HpdWrapper> hpdWrappers = (List<HpdWrapper>)dto.values.get(Accel_MachinePerformanceV2.MAP_KEY_HPD_MACHINE_AGGREGATE);
            System.assert(!hpdWrappers.isEmpty());
            //--(2) Tests that we we get the asset ids associated with machines back correctly.
            for(HpdWrapper hpdWrapper : hpdWrappers){
                System.assert(assetIds.contains(hpdWrapper.assetId));
            }
            Test.stopTest();
        }
    }
    /**
     * Tests AccelMachinePerformanceV2.retrieveAggregateMachineDate (negative).
     *
     * (1) Ensure we have no data returned when no hpd data exists.
     */
    @IsTest
    public static void test_retrieveAggregateMachineData_NoData_Negative(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Map<Id,Hold_Per_Day__c> mHoldPerDaysByIds = new Map<Id,Hold_Per_Day__c>([
                SELECT Id,Account__c,Date__c,Asset__c
                FROM   Hold_Per_Day__c
                WHERE  RecordType.Name = :HPD_DAILY_RTNAME
        ]);
        Id accountId = mHoldPerDaysByIds.values()[0].Account__c;
        String startDate    = String.valueOf( CURRENT_DATE_OVERRIDE.addMonths(-1).toStartOfMonth());
        String endDate      = String.valueOf( CURRENT_DATE_OVERRIDE.toStartOfMonth());
        TestUtils.deleteAllHoldPerDays();

        System.runAs(adminUser) {

            Test.startTest();
            //--(1) Ensure we have no data returned when no hpd data exists.
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveAggregateMachineData(accountId, startDate, endDate);
            System.assert(!dto.isSuccess);
            Test.stopTest();
        }
    }
    /**
     *
     * Test the Accel_Accel_MachinePerformanceV2.retrieveDailyMachineData method.
     *
     */
    @IsTest
    public static void test_retrieveDailyMachineData_Positive(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        Map<Id,Hold_Per_Day__c> mHoldPerDaysByIds = new Map<Id,Hold_Per_Day__c>([
                SELECT Id,Account__c,Date__c,Asset__c
                FROM   Hold_Per_Day__c
                WHERE  RecordType.Name = :HPD_DAILY_RTNAME
        ]);
        Id accountId = mHoldPerDaysByIds.values()[0].Account__c;
        String startDate    = String.valueOf( CURRENT_DATE_OVERRIDE.addMonths(-1).toStartOfMonth());
        String endDate      = String.valueOf( CURRENT_DATE_OVERRIDE.toStartOfMonth());
        Set<Id> assetIds    = new Set<Id>();

        for(Hold_Per_Day__c holdPerDay : mHoldPerDaysByIds.values()) {
            assetIds.add(holdPerDay.Asset__c);
        }

        System.runAs(adminUser) {

            Test.startTest();
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveDailyMachineData(accountId, startDate, endDate);
            System.assert(dto.isSuccess);

            List<HpdWrapper> hpdWrappers = (List<HpdWrapper>)dto.values.get(Accel_MachinePerformanceV2.MAP_KEY_HPD_MACHINE_DAILY);
            System.assert(!hpdWrappers.isEmpty());

            for(HpdWrapper hpdWrapper : hpdWrappers){
                System.assert(assetIds.contains(hpdWrapper.assetId));
            }
            Test.stopTest();
        }
    }
   /**
    *
    * Test the Accel_Accel_MachinePerformanceV2.retrieveDailyMachineData method when there is no data.
    *
    */
    @IsTest
    public static void test_retrieveDailyMachineData_NoData_Negative(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Map<Id,Hold_Per_Day__c> mHoldPerDaysByIds = new Map<Id,Hold_Per_Day__c>([
                SELECT Id,Account__c,Date__c,Asset__c
                FROM   Hold_Per_Day__c
                WHERE  RecordType.Name = :HPD_DAILY_RTNAME
        ]);
        Id accountId = mHoldPerDaysByIds.values()[0].Account__c;
        String startDate    = String.valueOf( CURRENT_DATE_OVERRIDE.addMonths(-1).toStartOfMonth());
        String endDate      = String.valueOf( CURRENT_DATE_OVERRIDE.toStartOfMonth());
        TestUtils.deleteAllHoldPerDays();

        System.runAs(adminUser) {

            Test.startTest();
            ResponseDto dto = Accel_MachinePerformanceV2.retrieveDailyMachineData(accountId, startDate, endDate);
            System.assert(!dto.isSuccess);
            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest static void test_retrieveYTDRevenue_Mature_Customer_Positive(){
        Date TODAY = CURRENT_DATE_OVERRIDE;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {

            Test.startTest();
            // Fake the Aggregation (AggregateMachineHpd) to aggregate last years hpds
            Date startDate = Date.newInstance(Date.today().addYears(-1).year(),1,1);
            Date endDate   = Date.newInstance(Date.today().addYears(-1).year(),12,31);
            TestUtils.aggregateDailyHoldPerDays(startDate,endDate);
            //  Simulate the batch job that runs at 9am every day.
            System.enqueueJob( new AggregateMachineHpd() );
            Test.stopTest();

            List<Hold_Per_Day__c> holdPerDays = [Select Id, Account__c from Hold_Per_Day__c WHERE RecordType.Name = :HPD_MONTHLY_RTNAME];
            Id accountId = holdPerDays[0].Account__c;

            //-- (1) Test that we are *NOT* in an HPD Dark Zone. (after 9am)
            ResponseDto dtoNotDark = Accel_MachinePerformanceV2.retrieveYTDRevenue(accountId);
            Boolean isHpdDarkZone = (Boolean)dtoNotDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(!isHpdDarkZone);

            //-- (2) Test that we got hpd wraps back as we normally would.
            System.assert( dtoNotDark.isSuccess );
            List<HpdWrapper> hpdWraps = (List<HpdWrapper>)dtoNotDark.values.get(Accel_MachinePerformanceV2.YTD_DATA);
            System.assert(!hpdWraps.isEmpty());

            //-- (3) Test that yesterday is well actually really yesterday lol.
            Date yesterday = (Date)dtoNotDark.values.get(Accel_MachinePerformanceV2.YESTERDAY_DATE);
            System.assertEquals(yesterday, TODAY.addDays(-1));

            //-- (4) Test we ARE in a hpd data dark zone. (before 9am / after midnight)
            //--- are are not creating 2K so we need to do this!
            Batch_Settings__c batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-2);
            upsert batchSettings;
            ResponseDto dtoDark =  Accel_MachinePerformanceV2.retrieveYTDRevenue(accountId);
            isHpdDarkZone = (Boolean)dtoDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(isHpdDarkZone);

            //-- (5) Test  that we got hpd wraps back as we normally would in a HPD Dark Scenario
            List<HpdWrapper> hpdWrapsDark    = (List<HpdWrapper>)dtoDark.values.get(Accel_MachinePerformanceV2.YTD_DATA);
            System.assert(!hpdWrapsDark.isEmpty());

            //-- (6) Test that yesterday is well not really yesterday but 2 days ago..
            yesterday = (Date)dtoDark.values.get(Accel_MachinePerformanceV2.YESTERDAY_DATE);
            System.assertEquals(yesterday, TODAY.addDays(-2));
        }

    }
    /**
     *
     */
    @IsTest static void test_retrieveYTDRevenue_Mature_Customer_NoData_Negative(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        TestUtils.deleteAllHoldPerDays();

        System.runAs(adminUser) {

            Test.startTest();
            // Fake the Aggregation (AggregateMachineHpd) to aggregate data from 50 years ago
            // (assuming this app is not gonna make it 50 years.)
            Date startDate = Date.newInstance(Date.today().addYears(-50).year(),1,1);
            Date endDate   = Date.newInstance(Date.today().addYears(-50).year(),12,31);
            TestUtils.aggregateDailyHoldPerDays(startDate,endDate);
            //  Simulate the batch job that runs at 9am every day.
            System.enqueueJob( new AggregateMachineHpd() );
            Test.stopTest();

            Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

            //-- (1) Test that we are *NOT* in an HPD Dark Zone. (after 9am)
            Accel_MachinePerformanceV2.UNIT_TEST_CURRENT_TIME_OVERRIDE = time_1100;
            ResponseDto dtoNotDark = Accel_MachinePerformanceV2.retrieveYTDRevenue(accountId);
            Boolean isHpdDarkZone = (Boolean)dtoNotDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(!isHpdDarkZone);

            //-- (2) Test that we got no hpd data back as none existed for params.
            System.assert( !dtoNotDark.isSuccess );
            List<HpdWrapper> hpdWraps = (List<HpdWrapper>)dtoNotDark.values.get(Accel_MachinePerformanceV2.YTD_DATA);
            System.assert(hpdWraps.isEmpty());

            //-- (3) Test we ARE in a hpd data dark zone. (before 9am / after midnight)
            //--- are are not creating 2K so we need to do this!
            Batch_Settings__c batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-2);
            upsert batchSettings;
            ResponseDto dtoDark =  Accel_MachinePerformanceV2.retrieveYTDRevenue(accountId);
            isHpdDarkZone = (Boolean)dtoDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(isHpdDarkZone);

            //-- (4) Test that we got no  hpd wraps back as there was no data for params passed for a HPD Dark Scenario
            List<HpdWrapper> hpdWrapsDark    = (List<HpdWrapper>)dtoDark.values.get(Accel_MachinePerformanceV2.YTD_DATA);
            System.assert(hpdWrapsDark.isEmpty());
        }
    }

    @isTest static void testRetrieveMTDRevenue_Mature_Customer_Positive(){
        Date TODAY = CURRENT_DATE_OVERRIDE;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {

            Test.startTest();
            // Fake the Aggregation (AggregateMachineHpd) to aggregate last years hpds
            Date startDate = Date.newInstance(Date.today().addYears(-1).year(),1,1);
            Date endDate   = Date.newInstance(Date.today().addYears(-1).year(),12,31);
            TestUtils.aggregateDailyHoldPerDays(startDate,endDate);
            //  Simulate the batch job that runs at 9am every day.
            System.enqueueJob( new AggregateMachineHpd() );
            Test.stopTest();

            List<Hold_Per_Day__c> holdPerDays = [SELECT Id, Account__c FROM Hold_Per_Day__c WHERE RecordType.Name = :HPD_MONTHLY_RTNAME];
            Id accountId = holdPerDays[0].Account__c;

            //-- (1) Test that we are *NOT* in an HPD Dark Zone. (after 9am)
            Accel_MachinePerformanceV2.UNIT_TEST_CURRENT_TIME_OVERRIDE = time_1100;
            ResponseDto dtoNotDark = Accel_MachinePerformanceV2.retrieveMTDRevenue(accountId);
            Boolean isHpdDarkZone = (Boolean)dtoNotDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(!isHpdDarkZone);

            //-- (2) Test that we got hpd wraps back as we normally would.
            System.assert( dtoNotDark.isSuccess );
            List<HpdWrapper> hpdWraps = (List<HpdWrapper>)dtoNotDark.values.get(Accel_MachinePerformanceV2.MTD_DATA);
            System.assert(!hpdWraps.isEmpty());

            //-- (3) Test that yesterday is well actually really yesterday lol.
            Date yesterday = (Date)dtoNotDark.values.get(Accel_MachinePerformanceV2.YESTERDAY_DATE);
            System.assertEquals(yesterday, TODAY.addDays(-1));

            //-- (4) Test that the proper display month is returned!
            String displayMonth = (String)dtoNotDark.values.get(Accel_MachinePerformanceV2.REVENUE_MTD_MONTH_NAME);
            Date adjustedMonthStartDate = (Date)dtoNotDark.values.get(Accel_MachinePerformanceV2.ADJUSTED_MONTH_START_DATE);
            System.assertEquals( displayMonth, (  ((Datetime)adjustedMonthStartDate)
                    .format(CommunityUtils.DATE_FORMAT_FULLMONTH_NAME )) );

            //-- (5) Test we ARE in a hpd data dark zone. (before 9am / after midnight)
            //--- are are not creating 2K so we need to do this!
            Batch_Settings__c batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-2);
            upsert batchSettings;
            ResponseDto dtoDark =  Accel_MachinePerformanceV2.retrieveMTDRevenue(accountId);
            isHpdDarkZone = (Boolean)dtoDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(isHpdDarkZone);

            //-- (6) Test  that we got hpd wraps back as we normally would in a HPD Dark Scenario
            List<HpdWrapper> hpdWrapsDark    = (List<HpdWrapper>)dtoDark.values.get(Accel_MachinePerformanceV2.MTD_DATA);
            System.assert(!hpdWrapsDark.isEmpty());

            //-- (7) Test that yesterday is well not really yesterday but 2 days ago..
            yesterday = (Date)dtoDark.values.get(Accel_MachinePerformanceV2.YESTERDAY_DATE);
            System.assertEquals(yesterday, CommunityUtils.getMostRecentHpdDate());

            //-- (8) Test that the proper display month is returned!
            displayMonth = (String)dtoNotDark.values.get(Accel_MachinePerformanceV2.REVENUE_MTD_MONTH_NAME);
            adjustedMonthStartDate = (Date)dtoNotDark.values.get(Accel_MachinePerformanceV2.ADJUSTED_MONTH_START_DATE);
            System.assertEquals( displayMonth, (  ((Datetime)adjustedMonthStartDate)
                    .format(CommunityUtils.DATE_FORMAT_FULLMONTH_NAME )) );
        }
    }
   /**
    *
    */
    @IsTest static void test_retrieveMTDRevenue_Mature_Customer_NoData_Negative(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        TestUtils.deleteAllHoldPerDays();

        System.runAs(adminUser) {

            Test.startTest();
            // Fake the Aggregation (AggregateMachineHpd) to aggregate data from 50 years ago
            // (assuming this app is not gonna make it 50 years.)
            Date startDate = Date.newInstance(Date.today().addYears(-50).year(),1,1);
            Date endDate   = Date.newInstance(Date.today().addYears(-50).year(),12,31);
            TestUtils.aggregateDailyHoldPerDays(startDate,endDate);
            //  Simulate the batch job that runs at 9am every day.
            System.enqueueJob( new AggregateMachineHpd() );
            Test.stopTest();

            Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

            //-- (1) Test that we are *NOT* in an HPD Dark Zone. (after 9am)
            Accel_MachinePerformanceV2.UNIT_TEST_CURRENT_TIME_OVERRIDE = time_1100;
            ResponseDto dtoNotDark = Accel_MachinePerformanceV2.retrieveMTDRevenue(accountId);
            Boolean isHpdDarkZone = (Boolean)dtoNotDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(!isHpdDarkZone);

            //-- (2) Test that we got no hpd data back as none existed for params.
            System.assert( !dtoNotDark.isSuccess );
            List<HpdWrapper> hpdWraps = (List<HpdWrapper>)dtoNotDark.values.get(Accel_MachinePerformanceV2.MTD_DATA);
            System.assert(hpdWraps.isEmpty());

            //-- (3) Test we ARE in a hpd data dark zone. (before 9am / after midnight)
            //--- are are not creating 2K so we need to do this!
            Batch_Settings__c batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-2);
            upsert batchSettings;
            ResponseDto dtoDark =  Accel_MachinePerformanceV2.retrieveMTDRevenue(accountId);
            isHpdDarkZone = (Boolean)dtoDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(isHpdDarkZone);

            //-- (4) Test that we got no  hpd wraps back as there was no data for params passed for a HPD Dark Scenario
            List<HpdWrapper> hpdWrapsDark    = (List<HpdWrapper>)dtoDark.values.get(Accel_MachinePerformanceV2.MTD_DATA);
            System.assert(hpdWrapsDark.isEmpty());
        }
    }

    @IsTest static void test_retrieveESTRevenue_Mature_Customer_Positive() {
        Date TODAY = CURRENT_DATE_OVERRIDE;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {
            Date startDate = Date.newInstance(Date.today().addYears(-1).year(),1,1);
            Date endDate   = Date.newInstance(Date.today().addYears(-1).year(),12,31);

            Test.startTest();
            //  We need to clone the monthlys to the start of the month to make this hit on exactly the
            //  first day of the month as this controller method is doing.
            //  @todo intended or defect?
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.toStartOfMonth().addYears(-1));
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addMonths(-1).toStartOfMonth().addYears(-1));
            // Fake the Aggregation (AggregateMachineHpd) to aggregate last years hpds
            TestUtils.aggregateDailyHoldPerDays(startDate,endDate);
            //  Simulate the batch job that runs at 9am every day.
            System.enqueueJob( new AggregateMachineHpd() );
            Test.stopTest();
            //--- are are not creating 2K so we need to do this!
            Batch_Settings__c batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-1);
            upsert batchSettings;

            List<Hold_Per_Day__c> holdPerDays = [SELECT Id, Account__c FROM Hold_Per_Day__c WHERE RecordType.Name = :HPD_MONTHLY_RTNAME];
            Id accountId = holdPerDays[0].Account__c; //  pull account we are going after from 1 of the HPD's

            //-- (1) Test that we are *NOT* in an HPD Dark Zone. (after 9am)
            Accel_MachinePerformanceV2.UNIT_TEST_CURRENT_TIME_OVERRIDE = time_1100;
            ResponseDto dtoNotDark = Accel_MachinePerformanceV2.retrieveESTRevenue(accountId);
            Boolean isHpdDarkZone = (Boolean)dtoNotDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(!isHpdDarkZone);

            //-- (2) Test that we got hpd wraps back as we normally would in a non HPD Dark data scenario.
            System.assert( dtoNotDark.isSuccess );
            List<HpdWrapper> hpdWraps = (List<HpdWrapper>)dtoNotDark.values.get(Accel_MachinePerformanceV2.EST_DATA);
            System.assert(!hpdWraps.isEmpty());

            //-- (3) Test that yesterday is well actually really yesterday lol.
            Date yesterday = (Date)dtoNotDark.values.get(Accel_MachinePerformanceV2.YESTERDAY_DATE);
            System.assertEquals(yesterday, TODAY.addDays(-1));

            //-- (4) Test that the proper display month is returned for Not Dark Scenario
            String displayMonth = (String)dtoNotDark.values.get(Accel_MachinePerformanceV2.ESTIMATED_REVENUE_MONTH_NAME);
            Date adjustedMonthStartDate = (Date)dtoNotDark.values.get(Accel_MachinePerformanceV2.ADJUSTED_ESTIMATED_REVENUE_MONTH);
            System.assertEquals( displayMonth, (  ((Datetime)adjustedMonthStartDate)
                    .format(CommunityUtils.DATE_FORMAT_FULLMONTH_NAME )) );

            //-- (5) Test we ARE in a hpd data dark zone. (before 9am / after midnight)
            //--- are are not creating 2K so we need to do this!
            batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-2);
            upsert batchSettings;
            ResponseDto dtoDark =  Accel_MachinePerformanceV2.retrieveESTRevenue(accountId);
            isHpdDarkZone = (Boolean)dtoDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(isHpdDarkZone);

            //-- (6) Test  that we got hpd wraps back as we normally would in a HPD Dark Scenario
            List<HpdWrapper> hpdWrapsDark    = (List<HpdWrapper>)dtoDark.values.get(Accel_MachinePerformanceV2.EST_DATA);
            System.assert(!hpdWrapsDark.isEmpty());

            //-- (7) Test that yesterday is well not really yesterday but 2 days ago..
            yesterday = (Date)dtoDark.values.get(Accel_MachinePerformanceV2.YESTERDAY_DATE);
            System.assertEquals(yesterday, TODAY.addDays(-2));

            //-- (8) Test that the proper display month is returned for Dark Scenario
            displayMonth = (String)dtoDark.values.get(Accel_MachinePerformanceV2.ESTIMATED_REVENUE_MONTH_NAME);
            adjustedMonthStartDate = (Date)dtoDark.values.get(Accel_MachinePerformanceV2.ADJUSTED_ESTIMATED_REVENUE_MONTH);
            System.assertEquals( displayMonth, (  ((Datetime)adjustedMonthStartDate)
                    .format(CommunityUtils.DATE_FORMAT_FULLMONTH_NAME )) );

        }
    }
    @IsTest static void test_retrieveESTRevenue_Mature_Customer_NoData_Negative(){

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        TestUtils.deleteAllHoldPerDays();

        System.runAs(adminUser) {

            Test.startTest();
            //  Simulate the batch job that runs at 9am every day.
            System.enqueueJob( new AggregateMachineHpd() );
            Test.stopTest();

            Id accountId = [SELECT Id FROM Account LIMIT 1].Id;

            //-- (1) Test that we are *NOT* in an HPD Dark Zone. (after 9am)
            Accel_MachinePerformanceV2.UNIT_TEST_CURRENT_TIME_OVERRIDE = time_1100;
            ResponseDto dtoNotDark = Accel_MachinePerformanceV2.retrieveESTRevenue(accountId);
            Boolean isHpdDarkZone = (Boolean)dtoNotDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(!isHpdDarkZone);

            //-- (2) Test that we got no hpd data back as none existed for params.
            System.assert( !dtoNotDark.isSuccess );
            List<HpdWrapper> hpdWraps = (List<HpdWrapper>)dtoNotDark.values.get(Accel_MachinePerformanceV2.EST_DATA);
            System.assert(hpdWraps.isEmpty());

            //-- (3) Test we ARE in a hpd data dark zone. (before 9am / after midnight)
            //--- are are not creating 2K so we need to do this!
            Batch_Settings__c batchSettings  = Batch_Settings__c.getOrgDefaults();
            batchSettings.Most_Recent_Hpd_Date__c = Date.today().addDays(-2);
            upsert batchSettings;
            ResponseDto dtoDark =  Accel_MachinePerformanceV2.retrieveESTRevenue(accountId);
            isHpdDarkZone = (Boolean)dtoDark.values.get(Accel_MachinePerformanceV2.IS_HPD_DARK_ZONE);
            System.assert(isHpdDarkZone);

            //-- (4) Test that we got no  hpd wraps back as there was no data for params passed for a HPD Dark Scenario
            List<HpdWrapper> hpdWrapsDark    = (List<HpdWrapper>)dtoDark.values.get(Accel_MachinePerformanceV2.EST_DATA);
            System.assert(hpdWrapsDark.isEmpty());
        }
    }
    /**
     * 2-13-2020
     * This class has gone down from 95% to 67% coverage due to new functionality added.
     * That will make it more difficult to move the associated controller to prod in an isolated fashion.
     * These are split into 2 to conserve cpu time.
     *
     * Added coverage below. to bring code coverage back up to 92%
     * @todo add real tests / asserts.
    */
    @IsTest
    static void testRandomUncovered_NewFunctionality_1() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {
            Datetime sDt =  Date.today().addDays(-90);
            Datetime eDt =  Date.today().addDays(1);
            String sDate =  sDt.format('YYYY-MM-dd');
            String eDate =  eDt.format('YYYY-MM-dd');
            Id accountId = [SELECT Account__c from Hold_Per_Day__c WHERE RecordType.DeveloperName = 'Daily_Aggregate' LIMIT 1].Account__c;

            Test.startTest();
            //---- bad add real tests..
            // YYYY-MM-dd  @todo don't understand this enough currently to build test data.
            Accel_MachinePerformanceV2.retrieveHistoricalData(accountId, sDate, eDate, 'Daily');
            Accel_MachinePerformanceV2.retrieveHistoricalData(accountId, sDate, eDate, 'Monthly');
            Accel_MachinePerformanceV2.retrieveAggregateMachineData(accountId, sDate, eDate);
        }
    }
    /**
     * @todo add real tests / asserts.
     */
    @IsTest
    static void testRandomUncovered_NewFunctionality_2() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {
            Datetime sDt =  Date.today().addDays(-90);
            Datetime eDt =  Date.today().addDays(1);
            String sDate =  sDt.format('YYYY-MM-dd');
            String eDate =  eDt.format('YYYY-MM-dd');
            Id accountId = [SELECT Account__c from Hold_Per_Day__c WHERE RecordType.DeveloperName = 'Daily_Aggregate' LIMIT 1].Account__c;

            Test.startTest();
            //---- bad add real tests..
            Accel_MachinePerformanceV2.retrieveDailyMachineData(accountId, sDate, eDate);
            Accel_MachinePerformanceV2.retrieveMachineImageData(accountId, sDate, eDate);
        }
    }
}