@IsTest
private class TEST_BatchTransferHpdMonthlies{

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    public static Date CURRENT_DATE_OVERRIDE    = Date.today();

    public static final String HPD_DAILY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Daily_HPD').getName();
    public static final String HPD_MONTHLY_RTNAME =  SObjectType.Hold_Per_Day__c
            .getRecordTypeInfosByDeveloperName().get('Monthly_HPD').getName();

    @TestSetup
    static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [ SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id ];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        User setupUser = adminUser;

        Date TODAY = CURRENT_DATE_OVERRIDE;

        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
            TestUtils.createTestHoldPerDays();

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

        }
    }

    @IsTest
    static void test_fireBatch_Transfer_Hpd_Monthlies_Positive_Commit() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        List<Account> accounts = [ SELECT Id, Type FROM Account];
        for(Account account : accounts) {
            //---------------------------- account.Accel_VGT_Live_Date__c = null;
            account.Type = 'Discontinued Account';
        }
        update accounts;

        List<Account> discontinuedAccounts = [SELECT Id FROM Account];
        List<Account> competitorAccounts = new List<Account>();
        Integer iNumDiscontinued = discontinuedAccounts.size();
        Municipality__c muni = [ SELECT Id FROM Municipality__c LIMIT 1];

        for(Integer i=0; i<iNumDiscontinued; i++) {
            Account competitorAccount  = TestUtils.buildAccount('TEST Competitor '+i,muni.Id,'Competitor Account');
            competitorAccounts.add(competitorAccount);
        }
        insert competitorAccounts;


        System.runAs(adminUser) {

            Map<Id,Account> mCompetitorAccountsByIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Type = 'Competitor Account']);
            Map<Id,Account> mDiscontinuedAccountsByIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Type = 'Discontinued Account']);
            System.assertEquals(mDiscontinuedAccountsByIds.size(),mCompetitorAccountsByIds.size());

            List<Account> compAccounts = mCompetitorAccountsByIds.values();
            Map<Id,Id> mSourceAcctId_TargetAcctId = new Map<Id,Id>();
            Boolean bCommitTrans = true;
            Boolean bChainBatch = false;

            for(Id discAcctId : mDiscontinuedAccountsByIds.keySet()) {
                Id compAcctId = compAccounts[0].id;
                mSourceAcctId_TargetAcctId.put(discAcctId,compAcctId);
            }

            Test.startTest();

            BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(mSourceAcctId_TargetAcctId,null,bCommitTrans,bChainBatch);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            //Test that comps account have at least some Hold per days.
            List<Hold_Per_Day__c> holdPerDays = [SELECT Id, Account__c from Hold_Per_Day__c WHERE Account__c IN :mSourceAcctId_TargetAcctId.values()];
            System.assert(!holdPerDays.isEmpty());
        }
    }
    @IsTest
    static void test_fireBatch_Transfer_Hpd_Monthlies_Positive_Commit_Chain() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        List<Account> accounts = [ SELECT Id, Type FROM Account];
        for(Account account : accounts) {
            //---------------------------- account.Accel_VGT_Live_Date__c = null;
            account.Type = 'Discontinued Account';
        }
        update accounts;

        List<Account> discontinuedAccounts = [SELECT Id FROM Account];
        List<Account> competitorAccounts = new List<Account>();
        Integer iNumDiscontinued = discontinuedAccounts.size();
        Municipality__c muni = [ SELECT Id FROM Municipality__c LIMIT 1];

        for(Integer i=0; i<iNumDiscontinued; i++) {
            Account competitorAccount  = TestUtils.buildAccount('TEST Competitor '+i,muni.Id,'Competitor Account');
            competitorAccounts.add(competitorAccount);
        }
        insert competitorAccounts;


        System.runAs(adminUser) {

            Map<Id,Account> mCompetitorAccountsByIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Type = 'Competitor Account']);
            Map<Id,Account> mDiscontinuedAccountsByIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Type = 'Discontinued Account']);
            System.assertEquals(mDiscontinuedAccountsByIds.size(),mCompetitorAccountsByIds.size());

            List<Account> compAccounts = mCompetitorAccountsByIds.values();
            Map<Id,Id> mSourceAcctId_TargetAcctId = new Map<Id,Id>();
            Boolean bCommitTrans = true;
            Boolean bChainBatch = true;

            for(Id discAcctId : mDiscontinuedAccountsByIds.keySet()) {
                Id compAcctId = compAccounts[0].id;
                mSourceAcctId_TargetAcctId.put(discAcctId,compAcctId);
            }

            Test.startTest();

            BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(mSourceAcctId_TargetAcctId,null,bCommitTrans,bChainBatch);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            // We can't really test chaining but need to cover a few more lines of code.
        }
    }
    @IsTest
    static void test_fireBatch_Transfer_Hpd_Monthlies_Positive_NoCommit() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        List<Account> accounts = [ SELECT Id, Type FROM Account];
        for(Account account : accounts) {
            //---------------------------- account.Accel_VGT_Live_Date__c = null;
            account.Type = 'Discontinued Account';
        }
        update accounts;

        List<Account> discontinuedAccounts = [SELECT Id FROM Account];
        List<Account> competitorAccounts = new List<Account>();
        Integer iNumDiscontinued = discontinuedAccounts.size();
        Municipality__c muni = [ SELECT Id FROM Municipality__c LIMIT 1];

        for(Integer i=0; i<iNumDiscontinued; i++) {
            Account competitorAccount  = TestUtils.buildAccount('TEST Competitor '+i,muni.Id,'Competitor Account');
            competitorAccounts.add(competitorAccount);
        }
        insert competitorAccounts;


        System.runAs(adminUser) {

            Map<Id,Account> mCompetitorAccountsByIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Type = 'Competitor Account']);
            Map<Id,Account> mDiscontinuedAccountsByIds = new Map<Id,Account>([SELECT Id FROM Account WHERE Type = 'Discontinued Account']);
            System.assertEquals(mDiscontinuedAccountsByIds.size(),mCompetitorAccountsByIds.size());

            List<Account> compAccounts = mCompetitorAccountsByIds.values();
            Map<Id,Id> mSourceAcctId_TargetAcctId = new Map<Id,Id>();
            Boolean bCommitTrans = false;
            Boolean bChainBatch = false;

            for(Id discAcctId : mDiscontinuedAccountsByIds.keySet()) {
                Id compAcctId = compAccounts[0].id;
                mSourceAcctId_TargetAcctId.put(discAcctId,compAcctId);
            }

            Test.startTest();

            BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(mSourceAcctId_TargetAcctId,null,bCommitTrans,bChainBatch);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            //Test that comps account have no hold per days WE DID NOT COMMIT
            List<Hold_Per_Day__c> holdPerDays = [SELECT Id, Account__c from Hold_Per_Day__c WHERE Account__c IN :mSourceAcctId_TargetAcctId.values()];
            System.assert(holdPerDays.isEmpty());
        }
    }
    @IsTest
    static void test_fireBatch_Transfer_Hpd_Monthlies_Negative_NullParams() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {

            Test.startTest();

            BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(null,null,true,false);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            //nothing really will never hit execute method. an email will be sent with param info but no detailed info
            System.assert(b.xferResults.isEmpty());
        }
    }

    @IsTest
    static void test_fireBatch_Transfer_Hpd_Monthlies_Negative_NoResults() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {

            Municipality__c muni = [SELECT Id FROM  Municipality__c LIMIT 1];
            Test.startTest();
            //not gonna find shit for these ids.
            Map<Id,Id> mSourceAccountId_targetAccountId = new Map<Id,Id>{ muni.Id => muni.Id};
            BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(mSourceAccountId_targetAccountId,null,true,false);
            Id batchJobId = Database.executeBatch(b);
            System.assert(batchJobId != null);

            Test.stopTest();

            //nothing really will never hit execute method. an email will be sent with param info but no detailed info
            System.assert(b.xferResults.isEmpty());
        }
    }
}