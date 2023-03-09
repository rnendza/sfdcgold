/**
 *  WIP Test neg use cases and various search params.
 */
@IsTest
private class TEST_AcGrowthMetricsController {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String COMMUSERACCOUNT        = 'Community User Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    public static Date CURRENT_DATE_OVERRIDE    = Date.today();

    public static final String HPD_MONTHLY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Monthly_HPD').getName();

    public static  List<String> communityAccountLocTypes = new List<String> {'Bar'};

    /**
     * Inserts an admin user, sets the role on the admin user and then creates a community users.
     * Creates municipalities, accounts / monthly / daily hold per da;ys... etc (TestUtils.createTestHoldPerDays)
     * Updates accounts to be live accel accounts.
     *
     * Sets hpd dates to 1 day back
     * Creates Monthly HPDS for a this month
     * Creates Monthly HPDS for a year ago.
     *
     * Reparent all hold per day records to account id owned by community user when done.
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
        System.debug(LoggingLevel.DEBUG,'accel ----  running setup data in test with TODAY ='+TODAY+'SETUP USER ='+setupUser);

        System.runAs(setupUser) {
            User portalUser =  TestUtils.getPortalUserForTest(PROFILENAMECP, COMMUSERACCOUNT, UNAMECP);
            Integer iNumHpdsPerAccount = 10;
            TestUtils.createTestHoldPerDays(iNumHpdsPerAccount);
            List<Account> accounts = [ SELECT Id, Accel_VGT_Live_Date__c, Type FROM Account];
            TestUtils.updateAccountsToLiveAccelAccount(accounts);

            //--- this data is always 1 day back so update regardless of what test utils original set as.
            TestUtils.updateAllHoldPerDaysDate(HPD_MONTHLY_RTNAME,TODAY.addDays(-1));
            //---- clone the Monthly Hpds to 1 year ago.
            TestUtils.cloneAndCreateHoldPerDays(HPD_MONTHLY_RTNAME,TODAY.addDays(-1).addYears(-1));

            //---- reparent all Hold_Per_Day__c sOBjects with account associated with community user.
            //@TODO figure out proper way to test external sharing rules!
            Contact portalContact               = [SELECT Id,AccountId FROM Contact WHERE Id = :portalUser.ContactId];
            List<Hold_Per_Day__c> holdPerDays   = [SELECT Id, Account__c FROM Hold_Per_Day__c];
            Account account                     = [SELECT Id, Location_Type__c FROM Account where Id = :portalContact.AccountId];

            //----- set the account to one of these tests location types.
            account.Location_Type__c = communityAccountLocTypes[0];
            update account;
            for(Hold_Per_Day__c holdPerDay : holdPerDays) {
                holdPerDay.Account__c = portalContact.AccountId;
            }
            update holdPerDays;

            //----- Reset date on monthlies to the first of the month to override test data.
            Map<Id,Hold_Per_Day__c> mHoldPerDaysByIds = new Map<Id,Hold_Per_Day__c>([
                    SELECT Id,Date__c
                    FROM   Hold_Per_Day__c
                    WHERE  RecordType.Name = :HPD_MONTHLY_RTNAME
            ]);
            Set<Date> holdPerDayDates = new Set<Date>();
            for(Hold_Per_Day__c holdPerDay : mHoldPerDaysByIds.values()) {
                holdPerDay.Date__c = holdPerDay.Date__c.toStartOfMonth();
                holdPerDayDates.add(holdPerDay.Date__c);
            }
            update mHoldPerDaysByIds.values();
        }
    }
    /**
     * Tests AcGrowthMetricsController.retrieveMontlyHpdDates. (positive)
     *
     * (1) Tests that we get hpd wraps back with the monthly dates successfully.
     */
    @IsTest
    public static void test_retrieveMonthlyHpdDates_Positive(){

        User communityUsr =  TestUtils.getPortalUserForTest(PROFILENAMECP, COMMUSERACCOUNT, UNAMECP);

        System.runAs(communityUsr) {

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
            ResponseDto dto = AcGrowthMetricsController.retrieveMonthlyHpdDates();
            System.assert(dto.isSuccess);
            List<HpdWrapper> hpdWrappers = (List<HpdWrapper>)dto.values.get(AcGrowthMetricsController.MAP_KEY_HPD_MONTHS);
            System.assert(!hpdWrappers.isEmpty());

            for(HpdWrapper hpdWrapper : hpdWrappers){
                System.assert(holdPerDayDates.contains(hpdWrapper.hpdDate));
            }
            Test.stopTest();
        }
    }
    /**
     * Tests AcGrowthMetricsController.retrieveMonthlyHpdDates. (negative)
     *
     * (1) Tests that we DO NOT get hpd wraps back with the monthly dates successfully as there is no data.
     */
    @IsTest
    public static void test_retrieveMonthlyHpdDates_NoData_Negative(){

        TestUtils.deleteAllHoldPerDays();
        User communityUsr =  TestUtils.getPortalUserForTest(PROFILENAMECP, COMMUSERACCOUNT, UNAMECP);


        System.runAs(communityUsr) {

            Test.startTest();
            //--(1) Tests that we DO NOT get hpd wraps back with the monthly dates successfully as there is no data.
            ResponseDto dto = AcGrowthMetricsController.retrieveMonthlyHpdDates();
            System.assert(!dto.isSuccess);
            Test.stopTest();
        }
    }

    /**
     * (1) Tests that we available loc types are those that with visible accounts associated to hpd recs
     */
    @IsTest
    public static void test_retrieveAvailableLocTypes_Positive(){
        User communityUsr =  TestUtils.getPortalUserForTest(PROFILENAMECP, COMMUSERACCOUNT, UNAMECP);
        System.runAs(communityUsr) {
            Test.startTest();
            //--(1) Tests that we available loc types are those that with visible accounts associated to hpd recs
            List<String> locTypes = AcGrowthMetricsController.retrieveAvailableLocTypes();
            System.assertEquals(locTypes, communityAccountLocTypes);
            Test.stopTest();
        }
    }
    /**
     * The will the test the AcGrowthMetrics.retrieveRevComparisonData method (positive)
     * @TODO DOC
     */
    @IsTest
    public static void test_retrieveRevComparisonData_SuppliedDates_Positive(){

        User communityUsr =  TestUtils.getPortalUserForTest(PROFILENAMECP, COMMUSERACCOUNT, UNAMECP);

        System.runAs(communityUsr) {

            String locType = 'All';
            Date startDate = date.today().addDays(-1).toStartOfMonth().addYears(-1);
            Date endDate = date.today().addDays(-1).addMonths(-0).toStartOfMonth();

            List<Hold_Per_Day__c> hpds = [
                    SELECT  Id, Account__c, Date__c, Account__r.Name,
                            Account__r.ShippingStreet,Account__r.ShippingCity,Funds_In__c,Funds_Out__c,Location_Share__c,
                            Net_Funds__c,Net_Revenue__c
                    FROM    Hold_Per_Day__c
                    WHERE   RecordType.Name =                       :HPD_MONTHLY_RTNAME
                    AND     Funds_In__c                             != NULL
                    AND     Funds_In__c                             != 0
                    AND     ( Date__c = :endDate OR Date__c = :startDate )
                    AND     Account__c                              IN :AcGrowthMetricsController.accountIds
                    AND     Account__r.Filtered_Location_Type__c    IN :communityAccountLocTypes
            ];
            Decimal iRealStartDateLocShareSum = 0, iRealEndDateLocShareSum = 0;
            for(Hold_Per_Day__c hpd : hpds) {
                if(hpd.Date__c == startDate) {
                    iRealStartDateLocShareSum+= hpd.Location_Share__c;
                } else if(hpd.Date__c == endDate){
                    iRealEndDateLocShareSum += hpd.Location_Share__c;
                }
            }

            Test.startTest();

            ResponseDto dto = AcGrowthMetricsController.retrieveRevComparisonData(locType,startDate,endDate);

            System.assert(dto.isSuccess);
            List<HpdWrapper> hpdWrappers = (List<HpdWrapper>)dto.values.get(AcGrowthMetricsController.MAP_KEY_HPD_COMPARE_DATA );
            System.assert(!hpdWrappers.isEmpty());
            System.assertEquals(hpds.size(),hpdWrappers.size());

            Decimal iAppStartDateLocShareSum = 0, iAppEndDateLocShareSum = 0;
            for(HpdWrapper hpdWrapper : hpdWrappers){
                if(hpdWrapper.hpdDate == startDate) {
                    iAppStartDateLocShareSum+= hpdWrapper.locShare;
                } else if(hpdWrapper.hpdDate == endDate){
                    iAppEndDateLocShareSum += hpdWrapper.locShare;
                }
            }
            System.assertEquals(iRealStartDateLocShareSum,iAppStartDateLocShareSum);
            System.assertEquals(iRealEndDateLocShareSum,iAppEndDateLocShareSum);

            Test.stopTest();
        }
    }
    /**
     * Direct test the Hold_Per_Day__c sObject => hpdWrapper.
     * (1) Tests the the Hold_Per_Day__c sObject is correctly copied to a HpdWrapper object.
     */
    @IsTest
    public static void test_copyHpdWrap_Positive(){
        User communityUsr =  TestUtils.getPortalUserForTest(PROFILENAMECP, COMMUSERACCOUNT, UNAMECP);

        System.runAs(communityUsr) {
            List<Hold_Per_Day__c> hpds = [
                    SELECT  Id, Account__c, Date__c, Account__r.Name,Account__r.Nickname__c,
                            Account__r.ShippingStreet,Account__r.ShippingCity,Funds_In__c,Funds_Out__c,Location_Share__c,
                            Net_Funds__c,Net_Revenue__c
                    FROM    Hold_Per_Day__c
                    WHERE   RecordType.DeveloperName = 'Monthly_HPD'
            ];
            Test.startTest();
            for(Hold_Per_Day__c hpd : hpds) {
                //-- (1) Tests the the Hold_Per_Day__c sObject is correctly copied to a HpdWrapper object.
                HpdWrapper hpdWrap = AcGrowthMetricsController.copyHpdToWrap(hpd);
                System.assertEquals(hpdWrap.hpdDate, hpd.Date__c);
                System.assertEquals(hpdWrap.accountId, hpd.Account__c);
                System.assertEquals(hpdWrap.locShare, hpd.Location_Share__c);
            }
            Test.stopTest();
        }
    }
}