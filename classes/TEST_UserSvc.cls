@isTest
private class TEST_UserSvc {

    public static String UNAMEADMIN = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP = 'accelcustomerportal@portal.com';
    public static String UNAMECP2 = 'accelcustomerportal2@portal.com';
    public static String ACCOUNTNAME = 'Blah Random UT Account';
    public static String PROFILENAMECP = 'Accel Customer Community';

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        //  Relationship manager user stuff for send of portal user create email
        User rmUser = TestUtils.getUserForTest('rm@accel.com');
        UserRole rmRole = new UserRole(DeveloperName = 'RMRole', Name = 'TestRMRole');
        insert rmRole;
        rmUser = [SELECT Id, UserRoleId FROM User WHERE Id = :rmUser.Id];
        rmUser.UserRoleId = rmRole.Id;
        update rmUser;


        User setupUser = adminUser;
        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP2);
        }
    }

    @IsTest
    static void test_retrieveProfileNamesForPermissionSet() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, Profile.Name FROM User WHERE Id = :adminUser.Id];

        String permissionSetApiName = 'blah_hpd_ps_api_name';
        String permissionSetLabel = 'blah hpd ps label';
        TestUtils.createPermissionSetAndAssignment(  permissionSetLabel, permissionSetApiName,adminUser.Id );

        System.runAs(adminUser) {
            Test.startTest();
            ResponseDto dto = UserSvc.retrieveProfileNamesForPermissionSet(permissionSetApiName);
            System.assert(dto.isSuccess);
            List<String> profileNames = (List<String>)dto.values.get(UserSvc.MAP_KEY_PS_PROFILE_NAMES);
            System.assert(profileNames.contains(adminUser.Profile.Name));
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveUserDetails() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Test.startTest();
        adminUser = UserSvc.retrieveUserDetails(adminUser.Id);
        System.assert(adminUser.Email != null);
        Test.stopTest();
    }
    @IsTest
    static void test_setUsersPasswords() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        portalUser = [SELECT Id, contactId, accountId,username,LastPasswordChangeDate from user where id = :portalUser.id];
        adminUser = [SELECT Id,Name,UserName, Email FROM User where Id = :adminUser.Id];

        //  prep the email template.
        EmailTemplate et = UserSvc.retrieveEmailTemplate(UserTriggerHandler.PASSWORD_EMAIL_TEMPLATE_DEV_NAME);
        String htmlBodyNormal = '<div>Normal</div>';
        String htmlBodyCustomMerge = '<div>[{password}] [{communityname}] [{communityloginurl}] [{communityusername}]</div>';
        String htmlbody = htmlBodyNormal + htmlBodyCustomMerge;
        et.body = htmlbody;
        update et;

        System.runAs(adminUser) {

            Map<User, String> mUserPw = new Map<User, String>{
                    portalUser => 'newPassword'
            };

            Test.startTest();
            //=== (1) you can't really assert much here System.setPassword does not execute in test context and this is a future method with void return
            UserSvc.setUsersPasswords(new Set<Id>{
                    portalUser.Id
            }, UserTriggerHandler.PW_GENERATION_TYPE_RANDOM, UserTriggerHandler.PW_LENGTH, et.Id);

            //--- the below version is meant to be called from a js client but reserved for future user.
            UserSvc.setUserPassword(portalUser.id, 'blahnewpw', new List<String>{
                    'blah@blah.com'
            });
            Test.stopTest();
        }
    }
    @IsTest
    static void test_sendPasswordEmails() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            adminUser = [SELECT Id,Name,UserName, Email FROM User where Id = :adminUser.Id];

            //  prep the email template.
            EmailTemplate et = UserSvc.retrieveEmailTemplate(UserTriggerHandler.PASSWORD_EMAIL_TEMPLATE_DEV_NAME);
            String htmlBodyNormal = '<div>Normal</div>';
            String htmlBodyCustomMerge = '<div>[{password}] [{communityname}] [{communityloginurl}] [{communityusername}]</div>';
            String htmlbody = htmlBodyNormal + htmlBodyCustomMerge;
            et.body = htmlbody;
            update et;
            Map<User, String> mUserPw = new Map<User, String>{
                    adminUser => 'newPassword'
            };

            Test.startTest();

            //=== (1) Test that merge fields were replaced.
            List<Messaging.SingleEmailMessage> singleEmailMessages = UserSvc.sendPasswordEmails(mUserPw, et.Id, UserSvc.DEFAULT_COMMUNITY_NAME);


            Test.stopTest();
        }
    }

    @IsTest
    static void test_genPassword() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            //=== (1) that we got a generated pw of the correct length
            String newPw = UserSvc.genUserPassword(UserTriggerHandler.PW_GENERATION_TYPE_RANDOM, UserTriggerHandler.PW_LENGTH);
            System.assertEquals(newPw.length(), UserTriggerHandler.PW_LENGTH);

            //=== (2) test an unsupported pw type
            newPw = UserSvc.genUserPassword('bogus pw type', UserTriggerHandler.PW_LENGTH);
            System.assertEquals(newPw, null);

            //=== (3) test a null pw length
            newPw = UserSvc.genUserPassword(UserTriggerHandler.PW_GENERATION_TYPE_RANDOM, null);
            System.assertEquals(newPw, null);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_buildPortalUsersCreateRmEmails() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        User portalUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        User portalUser2 = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, 'blahportal2@blah.com');
        User rmUser = [SELECT Id, UserRoleId, Email From USer where username = 'rm@accel.com'];

        portalUser = [SELECT Id, contactId, accountId,email from user where id = :portalUser.id];
        portalUser2 = [SELECT Id, contactId, accountId,email from user where id = :portalUser2.id];
        adminUser = [SELECT Id,Name,UserName, Email FROM User where Id = :adminUser.Id];

        Contact portalContact = [SELECT Id, Name, AccountId, LastName from Contact WHERE Id = :portalUser.ContactId];
        portalContact.LastName += ' Portal';
        update portalContact;

        Contact portalContact2 = [SELECT Id, Name,AccountId, LastName from Contact WHERE Id = :portalUser2.ContactId];
        portalContact2.LastName += ' Portal';
        update portalContact2;

        Set<Id> portalUsersCreated = new Set<Id>{
                portalUser.Id, portalUser2.Id
        };

        Account portalAccount = [SELECT Name, Relationship_Manager__c, Relationship_Manager__r.Email FROM Account where Id = :portalContact.AccountId];
        Account portalAccount2 = [SELECT Name, Relationship_Manager__c, Relationship_Manager__r.Email FROM Account where Id = :portalContact2.AccountId];

        System.runAs(adminUser) {

            Test.startTest();

            // (1) Account does NOT have an Relationship manager / send to portal support.

            List<Messaging.SingleEmailMessage> emailMessages = UserSvc.buildPortalUserCreateRmEmails(portalUsersCreated);
            System.assertEquals(emailMessages.size(), portalUsersCreated.size());

            for (Messaging.SingleEmailMessage em : emailMessages) {
                System.assert(em.getSubject().contains(UserSvc.RM_EMAIL_SUBJECT_SUFFIX));
                System.assert(em.getHtmlBody().contains(portalAccount.Name) || em.getHtmlBody().contains(portalAccount2.Name));
                System.assert(em.getToAddresses().contains(UserSvc.DEFAULT_OWA_EMAIL_ADDRESS));
            }

            // (2)  Contact does not have portal in name

            List<Contact> contacts = [SELECT Id, LastName FROM Contact];
            for (Contact contact : contacts) {
                contact.LastName.replace('Portal', '');
            }
            update contacts;

            emailMessages = UserSvc.buildPortalUserCreateRmEmails(portalUsersCreated);
            System.assertEquals(emailMessages.size(), portalUsersCreated.size());

            for (Messaging.SingleEmailMessage em : emailMessages) {
                System.assert(em.getSubject().contains(UserSvc.RM_EMAIL_SUBJECT_SUFFIX));
                System.assert(em.getSubject().containsIgnoreCase('Portal'));
                System.assert(em.getHtmlBody().contains(portalAccount.Name) || em.getHtmlBody().contains(portalAccount2.Name));
                System.assert(em.getToAddresses().contains(UserSvc.DEFAULT_OWA_EMAIL_ADDRESS));
            }

            // (3) Account DOES have an Relationship manager / send to to the RM

            portalAccount.Relationship_Manager__c = rmUser.id;
            update portalAccount;

            portalAccount2.Relationship_Manager__c = rmUser.id;
            update portalAccount2;

            portalAccount = [SELECT Name, Relationship_Manager__c, Relationship_Manager__r.Email FROM Account where Id = :portalContact.AccountId];
            portalAccount2 = [SELECT Name, Relationship_Manager__c, Relationship_Manager__r.Email FROM Account where Id = :portalContact2.AccountId];

            emailMessages = UserSvc.buildPortalUserCreateRmEmails(portalUsersCreated);
            System.assertEquals(emailMessages.size(), portalUsersCreated.size());

            for (Messaging.SingleEmailMessage em : emailMessages) {
                System.assert(em.getSubject().contains(UserSvc.RM_EMAIL_SUBJECT_SUFFIX));
                System.assert(em.getHtmlBody().contains(portalAccount.Name) || em.getHtmlBody().contains(portalAccount2.Name));
                System.assert(em.getToAddresses().contains(portalAccount.Relationship_Manager__r.Email)
                        || em.getToAddresses().contains(portalAccount2.Relationship_Manager__r.Email));
            }

            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveCommunity() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            //-- we can't really test this correct as sfdc does not have support for it yet.. just covering lines. grrr.
            ConnectApi.Community community = UserSvc.retrieveCommunity(UserSvc.DEFAULT_COMMUNITY_NAME);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveEmailTemplate() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            //=== (1) Ensure retrieval logic brings us back the correct record
            EmailTemplate etDb = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :UserTriggerHandler.PASSWORD_EMAIL_TEMPLATE_DEV_NAME];
            EmailTemplate etMethod = UserSvc.retrieveEmailTemplate(UserTriggerHandler.PASSWORD_EMAIL_TEMPLATE_DEV_NAME);
            System.assertEquals(etDb.Id, etMethod.Id);

            //=== (2) Bad dev name no record
            etMethod = UserSvc.retrieveEmailTemplate('bogus_dev_name');
            System.assertEquals(etMethod, null);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveOwa() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            //=== (1) Test that we got a proper owa back
            OrgWideEmailAddress owa = UserSvc.retrieveOwa(UserSvc.DEFAULT_OWA_EMAIL_ADDRESS);
            System.assert(owa != null);

            //=== (2) Test that we get nothing back on a bogus email addy for owa
            owa = UserSvc.retrieveOwa('bogus@bogus.com');
            System.assert(owa == null);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_getEmailTemplateSingleEmailMessage() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        System.runAs(portalUser) {
            EmailTemplate et = UserSvc.retrieveEmailTemplate(UserTriggerHandler.PASSWORD_EMAIL_TEMPLATE_DEV_NAME);

            Test.startTest();

            //=== (1) Test that we got a rendered template back
            Messaging.SingleEmailMessage renderedTemplate = UserSvc.getEmailTemplateSingleEmailMessage(et.id, portalUser.id);
            System.assert(renderedTemplate != null);
            System.assert(renderedTemplate.getSubject() != null);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_populateEmailTemplateCustomMergeFields() {

        User portalUser = TestUtils.getUserForTest(UNAMECP);
        System.runAs(portalUser) {
            EmailTemplate et = UserSvc.retrieveEmailTemplate(UserTriggerHandler.PASSWORD_EMAIL_TEMPLATE_DEV_NAME);
            String htmlBodyNormal = '<div>Normal</div>';
            String htmlBodyCustomMerge = '<div>[{password}] [{communityname}] [{communityloginurl}] [{communityusername}]</div>';
            String htmlbody = htmlBodyNormal + htmlBodyCustomMerge;
            et.body = htmlbody;
            update et;

            Map<String, String> mMergeFieldReplacement = new Map<String, String>();
            mMergeFieldReplacement.put('[{password}]', 'newpassword');
            mMergeFieldReplacement.put('[{communityname}]', 'newcommunityname');
            mMergeFieldReplacement.put('[{communityloginurl}]', 'newcommunityloginurl');
            mMergeFieldReplacement.put('[{communityusername}]', 'newcommunityusername');

            Test.startTest();

            //=== (1) Test that merge fields were replaced. not i can only be sure pw won't be pulled from the template so just testing this.
            Messaging.SingleEmailMessage emailMsg = UserSvc.populateEmailTemplateCustomMergeFields(et.id, portalUser.id, mMergeFieldReplacement);
            System.assert(emailMsg.getHtmlBody().contains('newpassword'));

            Test.stopTest();
        }
    }

    /**
     * (1) Test for valid profile retrieval by Name.
     * (2) Test for valid profile retrieval by profile Id.
     */
    @isTest static void testUserServiceProfileOperationsPositive() {
        User u = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(u) {
            Test.startTest();
            //=== (1) Test valid profile retrieval by Name.
            system.assertEquals(UserSvc.getProfileByName('System Administrator').name, 'System Administrator');
            //=== (2) Test valid profile retrieval by Id
            system.assertEquals(UserSvc.retrieveProfileById(UserInfo.getProfileId()).Name, 'System Administrator');

            Test.stopTest();
        }
    }
    @IsTest
    static void testRetrieveUserProfileById() {
        User u = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(u) {
            Profile dbProfile = [SELECT Id,Name FROM Profile LIMIT 1];
            Test.startTest();

            System.assertEquals(UserSvc.retrieveUserProfileById(dbProfile.Id).Id, dbProfile.Id);

            Test.stopTest();
        }
    }

    /**
     * (1) Test for invalid field name retrieval attempt.
     * (2) Test for valid profile retrieval by profile Id.
    */
    @isTest static void testUserServiceProfileOperationsNegative() {
        User u = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(u) {
            Test.startTest();
            //=== (1) Test INvalid profile retrieval.
            system.assertEquals(UserSvc.getProfileByName('BOGUS NAME'), null);
            //=== (2) Test Invalid profile retrieval by Id
            system.assertEquals(UserSvc.retrieveProfileById(null), null);
            Test.stopTest();
        }
    }
    @isTest static void test_retrieveUserLoginInfo_Positive() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        System.runAs(portalUser) {
            Test.startTest();
            //=== (1) Test The same username is retrieved.
            system.assertEquals(UserSvc.retrieveUserLoginInfo(portalUser.Id).Username, UNAMECP);
            Test.stopTest();
        }
    }
    @isTest static void test_retrieveUserLoginInfo_Negative() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        System.runAs(portalUser) {
            Test.startTest();
            //=== (1) Test The same user is null on a null id sent.
            system.assertEquals(UserSvc.retrieveUserLoginInfo(null), null);
            Test.stopTest();
        }
    }
    @isTest static void test_retrieveUserContactInfo_Positive() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        portalUser = [SELECT Id,ContactId FROM User WHERE Id = :portalUser.Id];
        System.runAs(portalUser) {
            Test.startTest();
            //=== (1) Test The same contactId is retrieved as that on the portal users
            system.assertEquals(UserSvc.retrieveUserContactId(portalUser.Id), portalUser.contactId);
            Test.stopTest();
        }
    }
    @isTest static void test_retrieveUserContactInfo_Negative() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id,ContactId FROM User WHERE Id = :adminUser.Id];
        System.runAs(adminUser) {
            Test.startTest();
            //=== (1) Test The same contactId is retrieved as admin user (ie null)
            system.assertEquals(UserSvc.retrieveUserContactId(adminUser.Id), adminUser.contactId);
            system.assertEquals(UserSvc.retrieveUserContactId(adminUser.Id), null);
            Test.stopTest();
        }
    }

    /**
     * Note. this tst is pretty useless other then for code coverage as SFDC hasn't really adapted
     * Site.changePassword() for over 10 years to help with testing and I don't see them doing it anytime soon.
     * Sooo... well when in Rome!
     */
    @isTest static void test_changePassword_Positive() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        System.runAs(portalUser) {
            Test.startTest();
            //=== (1) Test The same username is retrieved.
            String newPassword = 'blah!blah', confirmPassword = 'blah!blah', currentPassword = 'ballstothe1Wall';
            PageReference pr = UserSvc.changeCommunityUserPassword(newPassword, confirmPassword, currentPassword);
            System.assert(pr == null);
            Test.stopTest();
        }
    }
    /**
     * Another do nothing test other then to 'touch' the method. the call is bypassed in the UserSvc when runningg
     * tests due to SFDC lazyness.
     */
    @isTest static void test_validatePassword_Positive() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        portalUser = [SELECT Id,ContactId,username FROM User WHERE Id = :portalUser.Id];
        System.runAs(portalUser) {
            Test.startTest();
            String newPassword = 'blah!blah', confirmPassword = 'blah!blah', currentPassword = 'ballstothe1Wall';
            UserSvc.validateCommunityUserPassword(portalUser, newPassword, confirmPassword);
            Test.stopTest();
        }
    }

    @IsTest static void test_getCommunityPasswordPolicyStatement_Positive() {
        User portalUser = TestUtils.getUserForTest(UNAMECP);
        System.runAs(portalUser) {
            Test.startTest();
            String statement = UserSvc.getCommunityPasswordPolicyStatement();
            System.assert(statement != null);
            //--- it's really too risky to assert the text as how do we know if an admin will change it?
            Test.stopTest();
        }
    }
    @IsTest
    static void test_DoesUserHaveCustomPermission_negative() {
        User u = TestUtils.getUserForTest(UNAMECP);
        System.runAs(u) {
            u = [SELECT Id, ProfileId FROM User WHERE Id = :u.Id];
            Test.startTest();

            Boolean hasIt = UserSvc.doesUserHavePermission('blah_bogus');
            System.assert(hasIt == false);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_getUser() {
        User u = TestUtils.getUserForTest(UNAMECP);
        System.runAs(u) {
            u = [SELECT Id, ProfileId FROM User WHERE Id = :u.Id];
            Test.startTest();

            User tstUser = USerSvc.retrieveUser(u.Id);
            System.assertEquals(u.Id,tstUser.Id);

            Test.stopTest();
        }
    }
}