@IsTest
private class TEST_AccountSvc {

    public static String USERNAME_ADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String USERNAME_PORTAL            = 'accelcustomerportal@portal.com';
    public static Integer NUMBER_OF_ACCOUNTS        = 5;
    public static String HQ_ACCOUNT_NAME            = 'HQ  Portal UT Account';
    public static String PROFILE_NAME_PORTAL        = 'Grouped User Community Standard';
    public static Set<String> ACCOUNT_TYPES         = CustomMetaDataSvc.retrieveCommunityAccountTypes();

    @TestSetup
    static void setup() {

        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        adminUser = [ SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id ];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;
        User setupUser = adminUser;

        System.runAs(setupUser) {

            User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);
            Contact portalContact = [SELECT Id, AccountId FROM Contact WHERE Id = :portalUser.ContactId];
            Account hqAccount = [SELECT Id, HQ_Account__c FROM Account WHERE Id = :portalContact.AccountId];
            hqAccount.HQ_Account__c = true;
            update hqAccount;

            List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni',1);

            Test.startTest(); // isolate gov limits

            List<Account> accounts = new List<Account>();
            for(Municipality__c municipality : municipalities) {
                for(Integer i=0; i<NUMBER_OF_ACCOUNTS; i++) {
                    Account acct = TestUtils.buildAccount('accel test acct:' + i + 'a', municipality.id,
                            'Accel Account');
                    acct.ParentId = hqAccount.Id;
                    accounts.add(acct);
                    i++;
                }
            }
            insert accounts;
            //--- gotta do the below.. process builder overrides insert and changes stuff to prospects.
            accounts = [ SELECT Id, Accel_VGT_Live_Date__c, Type FROM Account];
            TestUtils.updateAccountsToLiveAccelAccount(accounts);

            List<Hold_Per_Day__c> holdPerDays = TestUtils.buildAccountHoldPerDays(accounts, 2,'Monthly HPD');
            insert holdPerDays;
            System.assert(!holdPerDays.isEmpty());

            Test.stopTest();
        }
    }


    @IsTest
    static void test_retrieveAccountsIncludingHq() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name
                    FROM   Account
                    WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ]);

            Test.startTest();

            Map<Id,Account> mAccountsByIds = AccountSvc.retrieveAccountsIncludingHq(ACCOUNT_TYPES,100);

            Boolean foundHq = false;
            for(Account account : mAccountsByIds.values()){
                System.assert(mTestAccountsByIds.containsKey(account.Id));
                if(account.HQ_Account__c) {
                    foundHq = true;
                }
            }
            System.assert(foundHq);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAccounts() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name
                    FROM   Account
                    WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ]);
            Test.startTest();

            Map<Id,Account> mAccountsByIds = AccountSvc.retrieveAccounts(ACCOUNT_TYPES,100);
            List<Account> accounts = [SELECT Id, HQ_Account__c FROM Account WHERE Id IN : mAccountsByIds.keySet()];

            for(Account account : accounts){
                System.assert(mTestAccountsByIds.containsKey(account.Id));
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAllLiveAccounts() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name
                    FROM   Account
                    WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ]);
            Test.startTest();

            List<Account> accounts = AccountSvc.retrieveAccounts(100);
            System.assertEquals(accounts.size(), mTestAccountsByIds.size());

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveRmAccounts() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Municipality__c muni = [SELECT Id FROM Municipality__c LIMIT 1];

        System.runAs(adminUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name, Relationship_Manager__c
                    FROM   Account
                    WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ]);
            for(Account account : mTestAccountsByIds.values()) {
                account.Relationship_Manager__c = adminUser.Id;
            }
            update mTestAccountsByIds.values();

            Test.startTest();

            List<Account> accounts = AccountSvc.retrieveAccounts( adminUser.Id, muni.Id);
            System.assert(!accounts.isEmpty());

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveFullAccount() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name, Relationship_Manager__c
                    FROM   Account
            ]);
            Test.startTest();

            Account account = AccountSvc.retrieveFullAccount(mTestAccountsByIds.values()[0].Id);
            System.assert(account != null);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAccountHpd() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Id accountId = [SELECT Id From Account LIMIT 1].Id;
            Test.startTest();

            System.assert( !AccountSvc.retrieveAccountHpd(accountId).isEmpty()) ;

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAccountHpdTotal() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Id accountId = [SELECT Id From Account LIMIT 1].Id;
        Id rtId = Schema.SObjectType.Hold_Per_Day_Total__c.getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();

        delete [SELECT Id FROM Hold_Per_Day_Total__c];

        Hold_Per_Day_Total__c hpdTotal = new Hold_Per_Day_Total__c( Account__c = accountId, RecordTypeId = rtId );
        Account account = [SELECT Id, Hold_Per_Day_Total__c FROM Account WHERE Id = :accountId];
        insert hpdTotal;
        account.Hold_Per_Day_Total__c = hpdTotal.Id;
        update account;
        
        System.runAs(adminUser) {
            Test.startTest();

            System.assert( AccountSvc.retrieveAccountHpdTotal(accountId).Id == hpdTotal.Id ) ;

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAccountAssets() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Id accountId = [SELECT Id From Account LIMIT 1].Id;
        Id swRtId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Software').getRecordTypeId();

        Asset asset = new Asset(Name='test sw asset 1', RecordTypeId = swRtId, AccountId = accountId);
        insert asset;

        System.runAs(adminUser) {
            Test.startTest();

            Map<Id,Asset> accountAssets = AccountSvc.retrieveAccountAssets(accountId, 'Software');
            System.assert(!accountAssets.isEmpty());

            accountAssets = AccountSvc.retrieveAccountAssets(new Set<Id>{accountId}, 'Software');
            System.assert(!accountAssets.isEmpty());

            Test.stopTest();
        }
    }
}