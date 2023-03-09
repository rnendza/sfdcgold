@IsTest
private class TEST_AggregateMachineModelMetrics {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    public static Date CURRENT_DATE_OVERRIDE    = Date.today();
    public static final Set<String> MODEL_METRICS_TYPES = new Set<String> {'Statewide90DAverage'};

    public static final String HPD_DAILY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Daily_HPD').getName();
    public static final String HPD_MONTHLY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Monthly_HPD').getName();
    public static final String HPD_MODEL_METRICS_RTId = SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Model_Metric').getRecordTypeId();

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
   * Note. assets are created with the hpds
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
            TestUtils.createTestHoldPerDays();
            List<Account> accounts = [ SELECT Id, Accel_VGT_Live_Date__c, Location_Type__c, Type FROM Account];
            TestUtils.updateAccountsToLiveAccelAccount(accounts);

            for(Account account : accounts) {
                account.Location_Type__c = 'Bar';
            }
            update accounts;
            Test.startTest();
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
    @IsTest
    static void test_updateModelMetrics_Positive() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {
            List<Asset> assets = [SELECT Id,AccountId FROM Asset];
            List<Asset> assetsToTagModel = new List<Asset>();
            Set<Id> assetIds = new Set<Id>();

            for(Integer i=0 ; i <assets.size() / 1.5 ; i++) {
                Asset ass = assets[0];
                ass.model__c = 'Twinstar';
                assetIds.add(ass.Id);
                assetsToTagModel.add(ass);
            }
            List<Hold_Per_Day__c> hpdsToTag = [
                    SELECT Id, RecordTypeId, Account__c,Metric_Type__c, Machine_Model__c
                    FROM   Hold_Per_Day__c
                    WHERE  Asset__c IN :assetIds
            ];
            if(!assetsToTagModel.isEmpty()) {
                update assets;
            }
            if(!hpdsToTag.isEmpty()) {
                for(Hold_Per_Day__c hpd : hpdsToTag) {
                    hpd.RecordTypeId = HPD_MODEL_METRICS_RTId;
                    hpd.Account__c = assetsToTagModel[0].AccountId;
                    hpd.machine_model__c = 'Twinstar';
                    hpd.Metric_Type__c = (new list<string>(MODEL_METRICS_TYPES) )[0] ;
                }
                update hpdsToTag;
            }
            //@todo can't get the bove to cover.. must be missing soemthing?

            Test.startTest();
            for(String mmType : MODEL_METRICS_TYPES) {  //note i gotta assume this is dangerous gov limits wise...
                new AggregateMachineModelMetrics().updateModelMetricHpd(mmType);
                //  @todo asserts once i determine the purpose of this.
            }
           Test.stopTest();
        }
    }
    @IsTest
    static void test_updateModelMetrics_Queueable_Positive() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {

            Test.startTest();
            System.enqueueJob(new AggregateMachineModelMetrics() );
            Test.stopTest();

            //@todo asserts
        }
    }
}