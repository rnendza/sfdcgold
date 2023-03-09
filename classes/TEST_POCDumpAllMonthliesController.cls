@IsTest
private class TEST_POCDumpAllMonthliesController {

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
    static void test_retrieveAllMonthliesForAccounts() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name
                    FROM   Account
                    WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ]);
            Test.startTest();

            portalUser = [SELECT Id, ContactId FROM User WHERE Id = :portalUser.Id];
            List<Hold_Per_Day__c> hpds = POCDumpAllMonthliesController.retrieveAllMonthliesForAccounts(portalUser.ContactId);

            Test.stopTest();
        }
    }
}