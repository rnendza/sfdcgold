@IsTest
private class TEST_UserTrigger {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Direct User Community Standard';
    public static String PROFILENAME_INDIRECTCP = 'Grouped User Community Standard';

    private final static String SEND_PW_EMAIL_FIELD_NAME = 'Portal_User_SetPassword_Active__c';
    private final static String SEND_RM_EMAIL_FIELD_NAME = 'Portal_Send_User_Created_RM_Email__c';

    /**
     *
     */
    @TestSetup
    static void setup() {

        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        adminUser = [ SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id ];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        //  Relationship manager user stuff for send of portal user create email
        User rmUser    = TestUtils.getUserForTest('rm@accel.com');
        UserRole rmRole = new UserRole(DeveloperName = 'RMRole', Name = 'TestRMRole');
        insert rmRole;
        rmUser = [SELECT Id, UserRoleId FROM User WHERE Id = :rmUser.Id];
        rmUser.UserRoleId = rmRole.Id;
        update rmUser;

        //  NOTE Permission sets and test visibility are a bit flaky in SFDC. Ensure there isn't already one visible
        List<PermissionSet> existingPermissionSets = [SELECT Id FROM PermissionSet WHERE Name = :UserTriggerHandler.GEN_USER_PERM_SET_API_NAME];
        if(existingPermissionSets.isEmpty()) {
            PermissionSet PermSet = new PermissionSet(Name = UserTriggerHandler.GEN_USER_PERM_SET_API_NAME , label = UserTriggerHandler.GEN_USER_PERM_SET_API_NAME);
            insert PermSet;
        }

        User setupUser = adminUser;
        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
            List<SObject> sObjs = new List<SObject>();
            String settingName = 'Trigger_Settings__c ' + setupUser.id;
            sObjs.add(new Trigger_Settings__c(Name = settingName, SetupOwnerId = setupUser.Id, Portal_User_SetPassword_Active__c = true));
            insert sObjs;
        }
    }


    @IsTest
    static void test_createCommunityUserSettings_Positive() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestAdminRole', Name = 'TestAdminRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;
        User runningUser = adminUser;

        System.runAs(runningUser) {

            Test.startTest();
            User portalUser =  TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
            Community_User_Setting__c communityUserSetting = [
                    SELECT  Id, Contact__c, User__c,Name
                    FROM    Community_User_Setting__c
                    WHERE   Contact__c  =   :portalUser.ContactId
                    AND     User__c     =   :portalUser.Id
            ];

            runningUser = [SELECT Id, Name FROM  User Where Id = :runningUser.id];
            System.assert(communityUserSetting != null);
           System.debug('communityUserSettingName='+communityUserSetting);
            System.debug('running name='+portalUser.Name);
          //@TODO --- aysnc issues here?  System.assert(communityUserSetting.Name.contains(runningUser.Name));
            Test.stopTest();
        }
    }

    @IsTest
    static void test_createCommunityUserSettings_Not_A_Community_User_Negative() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestAdminRole', Name = 'TestAdminRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;
        User runningUser = adminUser;

        System.runAs(runningUser) {

            Test.startTest();
            User randomUser =  TestUtils.getUserForTest('blahrandom@random.com');
            List<Community_User_Setting__c> communityUserSettings = [
                    SELECT  Id, Contact__c, User__c
                    FROM    Community_User_Setting__c
                    WHERE   Contact__c  =   :randomUser.ContactId
                    AND     User__c     =   :randomUser.Id
            ];
            System.assert(communityUserSettings.isEmpty());
            Test.stopTest();
        }
    }
    @IsTest
    static void test_createCommunityUserSettings_Bulk_Positive() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestAdminRole', Name = 'TestAdminRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;
        User runningUser = adminUser;

        System.runAs(runningUser) {

            Test.startTest();
            Integer iNumUsers = 50;
            List<User> portalUsers = TestUtils.createPortalUsersForTest(PROFILENAME_INDIRECTCP,'test account',UNAMECP,iNumUsers);
            System.assertEquals(portalUsers.size(),iNumUsers);

            List<Community_User_Setting__c> communityUserSettings = [
                    SELECT  Id, Contact__c, User__c
                    FROM    Community_User_Setting__c
            ];
            //----- settings intentionally not created for admin user in setup.
            System.assertEquals(portalUsers.size() + 1,communityUserSettings.size());
            Test.stopTest();
        }
    }

    @isTest
    static void test_assignPermissionSetsChatter(){
        Profile Chatter = [SELECT Id FROM Profile WHERE Name = 'Chatter Free User'];
        List<User> users = new List<user>();
        PermissionSet targetPermissionSet =  [SELECT Id FROM PermissionSet WHERE Name = :UserTriggerHandler.GEN_USER_PERM_SET_API_NAME ];

        User user2 = new User();
        user2.emailencodingkey = 'UTF-8';
        user2.languagelocalekey = 'en_US';
        user2.localesidkey = 'en_US';
        user2.timezonesidkey = 'America/Chicago';
        user2.Alias = TestUtils.generateRandomString(5);
        user2.email = user.alias + '@accelentertainment.com';
        user2.lastname = TestUtils.generateRandomString(10);
        user2.username = TestUtils.generateRandomString(15) + '@accelentertainment.com';
        user2.ProfileId = Chatter.Id;
        users.add(user2);

        test.startTest();
        insert users;

        List<PermissionSetAssignment> psas = [
                SELECT Id, AssigneeId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :user2.Id
                AND PermissionSetId = :targetPermissionSet.Id
        ];
        System.assert(psas.isEmpty());

        Test.stopTest();
    }

    @isTest
    static void test_assignPermissionSetsCommunity(){
        List<User> users = new List<user>();
        User communityUser = TestUtils.getUserForTest(UNAMECP);
        PermissionSet targetPermissionSet =  [SELECT Id FROM PermissionSet WHERE Name = :UserTriggerHandler.GEN_USER_PERM_SET_API_NAME ];

        test.startTest();
        insert users;

        //@see https://accel-entertainment.monday.com/boards/286658657/pulses/696117182/posts/821349308
//        List<PermissionSetAssignment> psas = [
//                SELECT Id, AssigneeId
//                FROM PermissionSetAssignment
//                WHERE AssigneeId = :communityUser.Id
//                AND PermissionSetId = :targetPermissionSet.Id
//        ];
//        System.assert(psas.isEmpty());

        Test.stopTest();

        List<PermissionSetAssignment> psas = [
                SELECT Id, AssigneeId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :communityUser.Id
                AND PermissionSetId = :targetPermissionSet.Id
        ];
        System.assert(!psas.isEmpty());
    }

    @isTest
    static void test_assignPermissionSetsAdmin(){

        User adminUser = TestUtils.getUserForTest('anyoldadmin1@blah.com');
        PermissionSet targetPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :UserTriggerHandler.GEN_USER_PERM_SET_API_NAME ];

        test.startTest();



        List<PermissionSetAssignment> psas = [
                SELECT Id, AssigneeId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :adminUser.Id
                AND PermissionSetId = :targetPermissionSet.Id
        ];
        System.assert(psas.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_assignPermissionSets_Bulk_Positive() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Profile callCenterProfile = [SELECT Id FROM Profile WHERE Name = 'Accel Call Center'];
        PermissionSet targetPermissionSet = [SELECT Id FROM PermissionSet WHERE Name = :UserTriggerHandler.GEN_USER_PERM_SET_API_NAME];
        Contact testContact = new Contact(FirstName = 'Test1', LastName = 'Test 2');
        List<User> usersToCreate = new List<User>();

        Integer iNumUsers = 53;

        for (Integer i = 0; i < iNumUsers; i++) {
            User user = new User();
            user.emailencodingkey = 'UTF-8';
            user.languagelocalekey = 'en_US';
            user.localesidkey = 'en_US';
            user.timezonesidkey = 'America/Chicago';
            user.Alias = TestUtils.generateRandomString(5);
            user.email = user.alias + '@accelentertainment.com';
            user.lastname = TestUtils.generateRandomString(10);
            user.username = TestUtils.generateRandomString(15) + '@accelentertainment.com';
            user.ProfileId = callCenterProfile.Id;
            user.ContactId = testContact.Id;
            usersToCreate.add(user);
        }

        System.runAs(adminUser) {
            Test.startTest();
            insert testContact;
            insert usersToCreate;

            Set<Id> userIds = new Set<Id>();

            for (User newUser : usersToCreate) {
                userIds.add(newUser.Id);
            }

            //@see https://accel-entertainment.monday.com/boards/286658657/pulses/696117182/posts/821349308
//            List<PermissionSetAssignment> psas = [
//                    SELECT Id, AssigneeId
//                    FROM PermissionSetAssignment
//                    WHERE AssigneeId IN :userIds
//                    AND PermissionSetId = :targetPermissionSet.Id
//            ];
//            System.assertEquals(psas.size(), iNumUsers);

            Test.stopTest();

            //Wait until trans is completed to assert as we are now calling the future overload.
            List<PermissionSetAssignment> psas = [
                    SELECT Id, AssigneeId
                    FROM PermissionSetAssignment
                    WHERE AssigneeId IN :userIds
                    AND PermissionSetId = :targetPermissionSet.Id
            ];
            System.assertEquals(psas.size(), iNumUsers);
        }
    }
    /**
     *
     */
    @IsTest
    static void test_createPortalUsersCreateRmEmails() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);

        System.runAs(adminUser) {

            //  Get custom settings.
            Id profileId = [SELECT ProfileId FROM User WHERE Id = :adminUser.Id].ProfileId;
            Trigger_Settings__c triggerSettings = Trigger_Settings__c.getInstance(profileId);

            Test.startTest();

            //  Insert new portal user.
            User portalUser2 = TestUtils.getPortalUserForTest(PROFILENAMECP,ACCOUNTNAME,'blahportal2@blah.com');

//            triggerSettings.Portal_User_SetPassword_Active__c = true;
//            triggerSettings.Po
//            System.assertEquals(triggerSettings.Portal_User_SetPassword_Active__c,UserTriggerHandler.PW_EMAIL_SENT);
//            System.assertEquals(triggerSettings.Portal_Send_User_Created_RM_Email__c,UserTriggerHandler.RM_EMAIL_SENT);

            Test.stopTest();
        }
    }

}