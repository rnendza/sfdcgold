@IsTest
private class TEST_BatchUiController{

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
    static void test_retrieveUserDetail() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            adminUser = BatchUiController.retrieveUserDetails(adminUser.Id);
            System.assert(adminUser.Email != null);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAsyncJob() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Async_Job__c job = new Async_Job__c();
        job.Name = 'gotrump';
        job.Parent_Job_Id__c = 'bogusparentjobid';
        job.Apex_Class_Name__c = TEST_BatchUiController.class.getName();
        job.Overall_Job_Status__c = ' Initiating  ' + job.Apex_Class_Name__c;
        insert job;

        System.runAs(adminUser) {
            Test.startTest();
            List<Async_Job__c> jobs  = BatchUiController.retrieveAsyncJobs( job.Name );
            System.assertEquals( jobs[0].Apex_Class_Name__c,TEST_BatchUiController.class.getName() );
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAsyncApexJobs() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            // we just need to get something in the queue we are not testing the job itself.
            BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(null, null,
                                                        true, false, 'batchjobname');
            Id jobId = Database.executeBatch(b,1);
            System.assert(jobId != null);

            Test.stopTest();

            // Pull it out of the standard SFDC Queue. ie. AsyncApexJob
            ResponseDto dto = BatchUiController.retrieveAsyncApexJobs(null,jobId,false,'batchjobname');
            System.assert(dto.isSuccess);

            List<AsyncApexJob> sfdcJobs =  (List<AsyncApexJob>)dto.values.get('jobs');
            System.assert(!sfdcJobs.isEmpty());
            for(AsyncApexJob job : sfdcJobs) {
                System.assertEquals(job.JobType,'BatchApex');
                System.assertEquals(job.Status, 'Completed');
            }
            Async_Job__c accelJob  = (Async_Job__c)dto.values.get('async_job_record');
            System.assertEquals(accelJob.Apex_Class_Name__c, 'BatchTransferHpdMonthlies');

            // we  sent bad params nothing will come back.
            dto = BatchUiController.retrieveAsyncApexJobs(null,null,false,'bogus');
            System.assert(!dto.isSuccess);

        }
    }

    @IsTest
    static void test_retrieveAllTodaysAsyncApexJobs() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            // we just need to get something in the queue we are not testing the job itself.
            BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(null, null,
                    true, false, 'batchjobname');
            Id jobId = Database.executeBatch(b,1);
            System.assert(jobId != null);

            Test.stopTest();

            // Pull it out of the standard SFDC Queue. ie. AsyncApexJob
            ResponseDto dto = BatchUiController.retrieveAllAsyncApexJobsToday(adminUser.Id);
            System.assert(dto.isSuccess);
            List<AsyncApexJob> sfdcJobs =  (List<AsyncApexJob>)dto.values.get('jobs');
            System.assert(!sfdcJobs.isEmpty());

        }
    }

    @IsTest
    static void test_fireBatchTransferHpdMonthlies_Positive_Commit_NoEmailAddy() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        List<Account> accounts = [ SELECT Id, Type FROM Account];
        for(Account account : accounts) {
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

            Id targetAccountId;
            Id sourceAccountId;
            for(Id discAcctId : mDiscontinuedAccountsByIds.keySet()) {
                Id compAcctId = compAccounts[0].id;
                mSourceAcctId_TargetAcctId.put(discAcctId,compAcctId);
                targetAccountId = compAcctId;
                sourceAccountId = discAcctId;
                break;
            }

            Integer batchSize = 5;
            Id recipientEmailUserId = null;

            Test.startTest();

            ResponseDto dto = BatchUiController.fireBatchTransferHpdMonthlies(  batchSize,sourceAccountId,targetAccountId,
                                                                                recipientEmailUserId,bCommitTrans,bChainBatch);
            System.assert(dto.values.get('batchId') != null);
            String jobName = (String)dto.values.get( 'async_job_name' );
            System.assert(jobName.containsIgnoreCase( BatchTransferHpdMonthlies.class.getName()) );
            System.assert(jobName.containsIgnoreCase( String.valueOf(Date.valueOf(Datetime.now()))) );

            Test.stopTest();
            //test completed account
            BatchUiController.CompletedAccountResult car = BatchUiController.retrieveCompletedAccountData(targetAccountId);
            //@TODO not sure we can test results of batch fired outside of ut?
        }
    }
    @IsTest
    static void test_fireBatchTransferHpdMonthlies_Positive_Commit_WithEmailAddy() {

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

            Id targetAccountId;
            Id sourceAccountId;
            for(Id discAcctId : mDiscontinuedAccountsByIds.keySet()) {
                Id compAcctId = compAccounts[0].id;
                mSourceAcctId_TargetAcctId.put(discAcctId,compAcctId);
                targetAccountId = compAcctId;
                sourceAccountId = discAcctId;
                break;
            }

            Integer batchSize = 5;
            Id recipientEmailUserId = adminUser.Id;

            Test.startTest();

            ResponseDto dto = BatchUiController.fireBatchTransferHpdMonthlies(  batchSize,sourceAccountId,targetAccountId,
                    recipientEmailUserId,bCommitTrans,bChainBatch);
            System.assert(dto.values.get('batchId') != null);
            String jobName = (String)dto.values.get( 'async_job_name' );
            System.assert(jobName.containsIgnoreCase( BatchTransferHpdMonthlies.class.getName()) );
            System.assert(jobName.containsIgnoreCase( String.valueOf(Date.valueOf(Datetime.now()))) );

            Test.stopTest();

            //@TODO not sure we can test results of batch fired outside of ut?
        }
    }
}