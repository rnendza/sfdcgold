@IsTest
private class TEST_ContactSvc {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    /**
     * Simply setup as community user.
     */
    @TestSetup static void setup() {
        //attach a role to the admin so we can create a portal user..
        UserRole adminRole = new UserRole(DeveloperName = 'TestAdminRole', Name = 'TestAdminRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        User setupUser = adminUser;

        System.runAs(setupUser) {
            // Searches for in memory portal user. if not found.. creates one.
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        }
    }

    @IsTest
    public static void test_retrieveContactAccounts_Positive() {
        List<Municipality__c> municipalities = TestUtils.createMunicipalities('Test muni',2);
        List<Account> accounts = buildAccountsForMunis(municipalities,2);
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        for(Account account : accounts) {
            Contact contact = TestUtils.buildContact(account.Id, 'last for '+account.Name);
            contacts.add(contact);
        }
        insert contacts;

        Contact contact = contacts[0];

        Test.startTest();
        List<ContactSvc.ContactAccount> contactAccounts = ContactSvc.retrieveContactAccounts(contact.Id,true);
        Test.stopTest();

    }

    @IsTest
    public static void test_findHqChildren_Positive() {
        List<Municipality__c> municipalities = TestUtils.createMunicipalities('Test muni',2);
        List<Account> accounts = buildAccountsForMunis(municipalities,2);
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
            Contact contact = TestUtils.buildContact(account.Id, 'last for '+account.Name);
            contacts.add(contact);
        }
        insert contacts;

        Test.startTest();
        accounts = ContactSvc.findHqChildren(accountIds);
        Test.stopTest();
    }
    @IsTest
    public static void test_buildPortalUser_Positive() {
        List<Municipality__c> municipalities = TestUtils.createMunicipalities('Test muni',2);
        List<Account> accounts = buildAccountsForMunis(municipalities,2);
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
            Contact contact = TestUtils.buildContact(account.Id, 'last for '+account.Name);
            contacts.add(contact);
        }
        insert contacts;

        Test.startTest();
        User u = ContactSvc.buildPortalUser(accounts[0].id,'first','last','email@email.com','username@user.com');
        Test.stopTest();
    }

    @IsTest
    public static void test_buildPortalContact_Positive() {
        List<Municipality__c> municipalities = TestUtils.createMunicipalities('Test muni',2);
        List<Account> accounts = buildAccountsForMunis(municipalities,2);
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
            Contact contact = TestUtils.buildContact(account.Id, 'last for '+account.Name);
            contacts.add(contact);
        }
        insert contacts;

        Test.startTest();
        User u = [SELECT Id,FirstName,LastName,Email FROM User WHERE Id = :UserInfo.getUserId()];
        Contact contact = ContactSvc.buildPortalContact(accounts[0].id,u);
        Test.stopTest();
    }
    @IsTest
    public static void test_retrieveMonthliesForAllAccounts_Positive() {
        List<Municipality__c> municipalities = TestUtils.createMunicipalities('Test muni',2);
        List<Account> accounts = buildAccountsForMunis(municipalities,2);
        insert accounts;

        List<Contact> contacts = new List<Contact>();
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
            Contact contact = TestUtils.buildContact(account.Id, 'last for '+account.Name);
            contacts.add(contact);
        }
        insert contacts;

        Test.startTest();
        ContactSvc.retrieveAllMonthliesForAccounts(accountIds);
        Test.stopTest();
    }
    //retrieveAllMonthliesForAccounts
    /**
     * (1) Test that we find the contact associated with the running community user.
     * @TODO Deprecate!
     */
    @IsTest
    public static void test_retrieveContactCommunityProfileSettings_Positive() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        System.runAs(communityUser) {
            Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;

            Test.startTest();
            //--(1) Test that we find the contact associated with the running community user.
            Contact contactProfileSettings = ContactSvc.retrieveContactCommunityProfileSettings(contactId);
//            System.assert(contactProfileSettings != null);
            Test.stopTest();
        }
    }
   /**
    * (1) Test that we do not find the contact associated with the running user. Run with an admin
    *     user which will not have a User.contactId value populated.
    * @TODO Deprecate!
    */
    @IsTest
    public static void test_retrieveContactCommunityProfileSettings_Negative() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Id contactId = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId()].ContactId;

            Test.startTest();
            //--(1) Test that we find the contact associated with the running community user.
            Contact contactProfileSettings = ContactSvc.retrieveContactCommunityProfileSettings(contactId);
//            System.assert(contactProfileSettings == null);
            Test.stopTest();
        }
    }
    public static List<Account> buildAccountsForMunis(List<Municipality__c> munis,Integer iNmbrOfAccountsPerMuni) {
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