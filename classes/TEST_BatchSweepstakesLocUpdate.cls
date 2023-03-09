@IsTest
private class TEST_BatchSweepstakesLocUpdate {

    public static String USERNAME_ADMIN = 'acceladmintest@accel.com';
    private static String MKTG_PRODUCT_TYPE = 'Sweepstakes';
    private static String MKTG_PRODUUCT_RECORD_TYPE = 'Marketing';

    @testSetup
    static void setup() {

        Integer iNmbrOfMunis=1, iNmbrOfAccountsPerMuni=3;

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {

            List<Municipality__c> munis = TestUtils.createMunicipalities('TEST Muni', iNmbrOfMunis);
            List<Account> accounts = buildAccountsForMunis(munis,iNmbrOfAccountsPerMuni);
            insert accounts;

            Batch_Job_Setting__mdt mdt = BatchjobSvc.queryForMetadata(BatchSweepstakesLocUpdate.jobName);
            List<String> rtDevNames = mdt.Record_Types_to_Query__c.split(',');
            Set<Id> rtIds = new Set<Id>();
            List<String> prodNames  = mdt.Product_Names_To_Query__c.split(',');

            List<Product2> products = new List<Product2>();

            for(String rtDevName : rtDevNames) {
                Id productRtId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName()
                        .get(MKTG_PRODUUCT_RECORD_TYPE).getRecordTypeId();

                Id mktgRtId = Schema.SObjectType.Marketing_Request__c.getRecordTypeInfosByDeveloperName()
                        .get(rtDevName).getRecordTypeId();

                rtIds.add(mktgRtId);

                for(String productName : prodNames) {
                    Product2 product = new Product2(
                            Name = productName, ProductCode = productName, IsActive = true,
                            Marketing_Product_Type__c = MKTG_PRODUCT_TYPE, Price__c = 50,
                            Location_Cost_Share_Amount__c = 50,
                            RecordTypeId = productRtId
                    );
                    products.add(product);
                }
            }
            insert products;

            List<Marketing_Request__c> mrs = new List<Marketing_Request__c>();
            List<Marketing_Request_Products__c> mrProducts = new List<Marketing_Request_Products__c>();

            for(Id rtId : rtIds) {

                for (Account account : accounts) {
                    Marketing_Request__c mr = new Marketing_Request__c();
                    mr.My_Project_Name__c = 'MR AE Player UT Test 1';
                    mr.Account__c = account.id;
                    mr.RecordTypeId = rtId;
                    mr.Name_of_Person_Requesting__c = adminUser.Id;
                    mr.WiFi_Network_Name__c = 'wifi net name';
                    mr.WiFi_Password__c = 'wifi pw';
                    mr.Cost_Share_Sent_To_Accounting__c = Date.today();
                    mrs.add(mr);
                }
                // add more then one marketing request for one of the accounts
                Marketing_Request__c mr2 = new Marketing_Request__c();
                mr2.My_Project_Name__c = 'MR AE Player UT Test 1';
                mr2.Account__c = accounts[0].id;
                mr2.RecordTypeId = rtId;
                mr2.Name_of_Person_Requesting__c = adminUser.Id;
                mr2.WiFi_Network_Name__c = 'wifi net name';
                mr2.WiFi_Password__c = 'wifi pw';
                mr2.Cost_Share_Sent_To_Accounting__c = Date.today();
                mrs.add(mr2);
            }
            insert mrs;


            for(Marketing_Request__c mr : mrs) {
                Marketing_Request_Products__c mrProduct = new Marketing_Request_Products__c();
                mrProduct.Marketing_Request__c = mr.Id;
                mrProduct.Marketing_Request_Type__c = MKTG_PRODUCT_TYPE;
                mrProduct.Quantity__c = 1;
                mrProduct.Custom_Price__c = 50;
                mrProduct.Account_Marketing__c = mr.Account__c;
                mrProduct.Product__c = products[0].Id;
                mrProducts.add(mrProduct);
            }
            insert mrProducts;

            System.debug(mrs);
        }
    }

    @isTest
    static void test_fireBatch_Success_Commit() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Success');
        }
    }

    @isTest
    static void test_fireBatch_Success_FlagFalse() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();

            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;

            List<Marketing_Request__c> marketingRequests = [
                    SELECT Id,Cost_Share_Sent_To_Accounting__c
                    FROM Marketing_Request__c
            ];
            for (Marketing_Request__c marketingRequest : marketingRequests) {
                marketingRequest.Cost_Share_Sent_To_Accounting__c = null;
            }
            update marketingRequests;

            List<Account> accounts = [
                    SELECT Id,SweepstakesCurrOptIn__c
                    FROM Account
            ];
            for (Account account : accounts) {
                account.SweepstakesCurrOptIn__c = TRUE;
            }
            update accounts;


            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Success');
        }
    }

    @isTest
    static void test_fireBatch_Success_Rollback() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;
            Boolean bCommit = false, logExeMethod = true;
            String scheduledJobId = null;

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Rolled Back');

        }
    }

    @isTest
    static void test_fireBatch_ALL_DmlException() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();

            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;
            BatchSweepstakesLocUpdate.FORCE_ALL_DML_EXCEPTION = TRUE;

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Failed');

        }
    }

    @isTest
    static void test_fireBatch_PARTIAL_DmlException() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();

            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;
            BatchSweepstakesLocUpdate.FORCE_PARTIAL_DML_EXCEPTION = TRUE;

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Partial Success');

        }
    }

    @isTest
    static void test_fireBatch_Fail_SendEmail_ValidUsernames() {

        Batch_Job_Setting__mdt mdt = BatchjobSvc.queryForMetadata(BatchSweepstakesLocUpdate.jobName);

        String userName = USERNAME_ADMIN;
        if(mdt!= null && mdt.Usernames_to_email__c != null) {
            userName = mdt.Usernames_to_email__c.split(',')[0];
        }
        User adminUser = TestUtils.getUserForTest(userName);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;

            BatchSweepstakesLocUpdate.FORCE_ALL_DML_EXCEPTION = true;
            BatchSweepstakesLocUpdate.SEND_EMAIL_ON_FAIL = true;
            BatchSweepstakesLocUpdate.TEST_EMAIL_USERNAMES = UserInfo.getUserName();

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Failed');
        }
    }

    @isTest
    static void test_fireBatch_Always_SendEmail_ValidUsernames() {

        Batch_Job_Setting__mdt mdt = BatchjobSvc.queryForMetadata(BatchSweepstakesLocUpdate.jobName);

        String userName = USERNAME_ADMIN;
        if(mdt!= null && mdt.Usernames_to_email__c != null) {
            userName = mdt.Usernames_to_email__c.split(',')[0];
        }
        User adminUser = TestUtils.getUserForTest(userName);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;
            BatchSweepstakesLocUpdate.SEND_EMAIL_ON_COMPLETION = true;
            BatchSweepstakesLocUpdate.TEST_EMAIL_USERNAMES = UserInfo.getUserName();

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
        }
    }

    @isTest
    static void test_fireBatch_Fail_SendEmail_InvalidUsernames() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;

            BatchSweepstakesLocUpdate.FORCE_ALL_DML_EXCEPTION = true;
            BatchSweepstakesLocUpdate.SEND_EMAIL_ON_FAIL = true;
            BatchSweepstakesLocUpdate.TEST_EMAIL_USERNAMES = 'bogus@willnotbefound.com';

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Failed');
        }
    }
    @isTest
    static void test_fireBatch_Fail_SendEmail_No_Usernames() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Integer iBatchSize = 50;
            Boolean bCommit = true, logExeMethod = true;
            String scheduledJobId = null;

            BatchSweepstakesLocUpdate.FORCE_ALL_DML_EXCEPTION = true;
            BatchSweepstakesLocUpdate.SEND_EMAIL_ON_FAIL = true;
            BatchSweepstakesLocUpdate.TEST_EMAIL_USERNAMES = null;

            BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommit,iBatchSize,logExeMethod,scheduledJobId);

            Id jobId = Database.executeBatch(b,iBatchSize);
            Test.stopTest();

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(b.log.Id);
            System.debug('----> log='+log);
            System.assertEquals(log.Overall_Job_Status__c,'Failed');
        }
    }
   /**
    * @param munis
    * @param iNmbrOfAccountsPerMuni
    *
    * @return
    * @todo move to TestUtils
    */
    static List<Account> buildAccountsForMunis(List<Municipality__c> munis,Integer iNmbrOfAccountsPerMuni) {
        List<Account> accounts = new List<Account>();

        for (Municipality__c muni : munis) {
            for (Integer i = 0; i < iNmbrOfAccountsPerMuni; i++) {
                Account account = TestUtils.buildAccount('Test Account ' + i, muni.Id);
                accounts.add(account);
            }
        }
        return accounts;
    }
}