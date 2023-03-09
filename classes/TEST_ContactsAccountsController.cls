@IsTest
private class TEST_ContactsAccountsController {

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
    static void test_retrieveContactAccounts_Positive() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name
                    FROM   Account
                    WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ]);
            Test.startTest();

            portalUser = [SELECT Id, ContactId FROM User WHERE Id = :portalUser.Id];
            Id contactId = portalUser.ContactId;
            ResponseDto dto  = ContactsAccountsController.retrieveContactAccounts(contactId);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveContactAccounts_Negative() {

        Test.startTest();
        ResponseDto dto = ContactsAccountsController.retrieveContactAccounts(null);
        Test.stopTest();
    }

    @IsTest
    static void test_retrievePortalProfiles() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {

            Test.startTest();
            List<Profile> profiles = ContactsAccountsController.retrievePortalProfiles();
            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveTriggerSettings() {

        Test.startTest();
        Trigger_Settings__c ts = ContactsAccountsController.retrieveTriggerSettings(UserInfo.getUserId());
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveOrgBatchSettings() {

        Test.startTest();
        Batch_Settings__c bs = ContactsAccountsController.retrieveOrgBatchSettings();
        Test.stopTest();
    }


    @IsTest
    static void test_updateTriggerSettings() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {

            Test.startTest();

            insert new Trigger_Settings__c(SetupOwnerId=portalUser.Id);
            Trigger_Settings__c ts = ContactsAccountsController.retrieveTriggerSettings(UserInfo.getUserId());
            ts = [SELECT Id,Portal_User_SetPassword_Active__c FROM Trigger_Settings__c WHERE SetupOwnerId = :ts.SetupOwnerId];
            ts.Portal_User_SetPassword_Active__c = true;
            ResponseDto dto = ContactsAccountsController.updateTriggerSettings(ts);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_updateBatchSettings() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {

            Test.startTest();

            insert new Batch_Settings__c(SetupOwnerId=portalUser.Id);
            Batch_Settings__c bs = [SELECT Id,Most_Recent_Hpd_Date__c FROM Batch_Settings__c WHERE SetupOwnerId = :portalUser.Id];
            bs.Most_Recent_Hpd_Date__c = Date.today();
            ResponseDto dto = ContactsAccountsController.updateBatchSettings(bs);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrievePortalUsers() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {

            Test.startTest();

            ResponseDto dto = ContactsAccountsController.retrievePortalUsers();

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrievePortalAccounts() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {

            Test.startTest();

            ResponseDto dto = ContactsAccountsController.retrievePortalAccounts();

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveContactAccountRelationship() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);
        portalUser = [SELECT Id, ContactId FROM User WHERE Id = :portalUser.Id];
        Id locRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Location').recordTypeId;
        String type = 'Accel Account';


        Municipality__c muni = [SELECT Id From Municipality__c LIMIT 1];
        Account a = TestUtils.buildAccount('BLAH TEST Account',muni.id);
        a.RecordTypeId = locRtId;
        a.HQ_Account__c = true;
        Account aChild = TestUtils.buildAccount('BLAH TEST Account child',muni.id);
        insert a;
        a.Type = type;
        update a;

        aChild.ParentId = a.Id;
        aChild.RecordTypeId = locRtId;
        insert aChild;
        aChild.type = type;
        update aChild;

        System.runAs(portalUser) {

            Test.startTest();

            ResponseDto dto = ContactsAccountsController.createAccountContactRelationship(portalUser.ContactId,a.Id);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_deleteContactAccountRelationship() {

        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);
        portalUser = [SELECT Id, ContactId FROM User WHERE Id = :portalUser.Id];
        Id locRtId = Account.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Location').recordTypeId;
        String type = 'Accel Account';

        Municipality__c muni = [SELECT Id From Municipality__c LIMIT 1];
        Account a = TestUtils.buildAccount('BLAH TEST Account',muni.id);
        a.RecordTypeId = locRtId;
        a.HQ_Account__c = true;
        Account aChild = TestUtils.buildAccount('BLAH TEST Account child',muni.id);
        insert a;
        a.Type = type;
        update a;

        aChild.ParentId = a.Id;
        aChild.RecordTypeId = locRtId;
        insert aChild;
        aChild.type = type;
        update aChild;

        System.runAs(portalUser) {

            Test.startTest();

            ResponseDto dto = ContactsAccountsController.createAccountContactRelationship(portalUser.ContactId,a.Id);
            List<AccountContactRelation> acrs = [SELECT Id FROM AccountContactRelation where ContactId = :portalUser.ContactId AND IsDirect = FALSE ];
            ResponseDto dtoDel = ContactsAccountsController.deleteAccountContactRelationship(acrs[0].Id);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_insertPortalUser() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Account a = [SELECT Id FROM Account LIMIT 1];
        Contact portalContact = TestUtils.buildContact(a.Id,'portalLast');
        portalContact.email ='test@test.com';
        portalContact.FirstName ='portalFirst';
        insert portalContact;

        System.runAs(adminUser) {

            Test.startTest();

            ResponseDto dto = ContactsAccountsController.insertPortalUser(portalContact,portalContact.Email);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_assignPermissionSet() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(adminUser) {

            Test.startTest();

            ResponseDto dto = ContactsAccountsController.assignPermissionSets(portalUser.Id);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_insertPortalContact() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        Account a = [SELECT Id FROM Account LIMIT 1];

        System.runAs(adminUser) {

            Test.startTest();
                // Id accountId,String firstName, String lastName,String emailAddress, String userName ) {
            ResponseDto dto = ContactsAccountsController.insertPortalContact(a.Id,'first','last','test@test.com','test@test.com');

            Test.stopTest();
        }
    }
    @IsTest
    static void test_setUserDefaultPwFuture() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);
        portalUser = [SELECT Id, ContactId, Email FROM User WHERE Id =:portalUser.Id];

        Account a = [SELECT Id FROM Account LIMIT 1];

        System.runAs(adminUser) {

            Test.startTest();
            // Id accountId,String firstName, String lastName,String emailAddress, String userName ) {
            ResponseDto dtoPredefined = ContactsAccountsController.setUserDefaultPwFuture(portalUser.id,'predefined',new List<String>{portalUser.Email});
            ResponseDto dtoRandom  = ContactsAccountsController.setUserDefaultPwFuture(portalUser.id,'random',new List<String>{portalUser.Email});
            ResponseDto dtoNamedCred  = ContactsAccountsController.setUserDefaultPwFuture(portalUser.id,'namedcred',new List<String>{portalUser.Email});
            ResponseDto dtostoredencrypted = ContactsAccountsController.setUserDefaultPwFuture(portalUser.id,'storedencrypted',new List<String>{portalUser.Email});
            ResponseDto dtoNotSupported = ContactsAccountsController.setUserDefaultPwFuture(portalUser.id,'bogus',new List<String>{portalUser.Email});
            Test.stopTest();
        }
    }
    //public static ResponseDto setUserDefaultPwFuture(  Id userId, String pwType, List<String> emailAddresses) {

}