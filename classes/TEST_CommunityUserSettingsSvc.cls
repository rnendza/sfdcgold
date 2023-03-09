@IsTest
private class TEST_CommunityUserSettingsSvc {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';
    public static String PROFILENAME_INDIRECTCP = 'Indirect User Community Standard';
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
    /**
     * @TODO mod chain of calls to use with sharing.
     */
    @IsTest
    static void test_Retrieve_Community_User_Settings_Positive() {
        User portalUser =  TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(portalUser.Id, portalUser.contactId);
        insert cus;
        System.assert(cus.name.contains(portalUser.Name));
        User tmpCommUser = [select id, profile.name from user where id = :portalUser.Id];
        System.debug('running with portal user profile='+tmpCommUser.profile.name);

        System.runAs(portalUser) {
            Test.startTest();
            List<Community_User_Setting__c> cuss = [SELECT Id FROM  Community_User_Setting__c];
            Community_User_Setting__c setting = CommunityUserSettingsSvc.retrieveCommunityUserSettings();

            System.assert(setting.id != null);
            System.assert(setting.User__c == portalUser.Id);
            System.assert(setting.Contact__c == portalUser.ContactId);
            //@todo ----- why would this not work in prod? System.assert(setting.Name  == portalUser.Name + ' Setting');
            Test.stopTest();
        }
    }
    /**
     * We must hack this a little bit.. say an admin logs in via setup / all communities and clicks the community link.
     */
    @IsTest
    static void test_Retrieve_Community_User_Settings_SysAdmin() {
        User adminUser =  TestUtils.getUserForTest(UNAMEADMIN);
        //User.contactId will be null since we are only, maybe assigning User.Contact__c which is not the right one!
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(adminUser.Id, null);
        insert cus;
        System.runAs(adminUser) {
            Test.startTest();
            Exception customException;
            try {
                Community_User_Setting__c setting = CommunityUserSettingsSvc.retrieveCommunityUserSettings();
            } catch (Exception e) {
                customException = e;
            }
            System.assertEquals(customException.getTypeName(),'Warnings.InvalidCommunityUserException');
            Test.stopTest();
        }
    }
    @IsTest
    static void test_Update_All_Community_User_Settings_As_Admin_Positive() {
        User adminUser =  TestUtils.getUserForTest(UNAMEADMIN);
        User portalUser =  TestUtils.getPortalUserForTest(PROFILENAME_INDIRECTCP, ACCOUNTNAME, UNAMECP);
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(portalUser.Id, portalUser.contactId);
        insert cus;
        Community_User_Setting__c setting = [SELECT Id FROM Community_User_Setting__c WHERE Id = :cus.Id];

        System.runAs(adminUser) {

            Test.startTest();
            Id settingId = setting.Id;
            //Map<String,FieldSet> mFieldSets = SObjectType.Community_User_Setting__c.fieldSets.getMap();
            Map<String, FieldSet> mFieldSets = null; //  Assume no field sets in tgt org.
            Set<String> allFsFields =  CommunityUserSettingsSvc.getAllFieldSetsFields(mFieldSets);

            Community_User_Setting__c uiSetting = new Community_User_Setting__c();
            uiSetting.Contact__c = portalUser.ContactId;
            uiSetting.User__c = portalUser.Id;
            uiSetting.Id = settingId;

            for (String field : allFsFields) {
                if (field.contains('Display')) {
                    uiSetting.put(field, true);
                }
            }
            CommunityUserSettingsSvc.updateCommunityUserSettings(uiSetting);
            //@TODO Assert after dynamic direct select

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void test_Update_Community_User_Settings_As_Indirect_Positive() {
        User portalUser =  TestUtils.getPortalUserForTest(PROFILENAME_INDIRECTCP, ACCOUNTNAME, UNAMECP);
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(portalUser.Id, portalUser.contactId);
        insert cus;
        User tmpCommUser = [select id, profile.name from user where id = :portalUser.Id];
        System.debug('running with portal user profile='+tmpCommUser.profile.name);

        System.runAs(portalUser) {
            Test.startTest();
            Community_User_Setting__c setting = CommunityUserSettingsSvc.retrieveCommunityUserSettings();
            Id settingId = setting.Id;
            Map<String,FieldSet> mFieldSets = SObjectType.Community_User_Setting__c.fieldSets.getMap();
            Set<String> allFsFields =  CommunityUserSettingsSvc.getAllFieldSetsFields(mFieldSets);
            Community_User_Setting__c uiSetting = new Community_User_Setting__c();
            uiSetting.Contact__c = portalUser.ContactId;
            uiSetting.User__c = portalUser.Id;
            uiSetting.Id = settingId;

            for (String field : allFsFields) {
                if (field.contains('Display')) {
                    uiSetting.put(field, false);
                }
            }
            CommunityUserSettingsSvc.updateCommunityUserSettings(uiSetting);
            uiSetting = CommunityUserSettingsSvc.retrieveCommunityUserSettings();
            Map<String,Object> mFieldName_Value = uiSetting.getPopulatedFieldsAsMap();
            // Test all set to false
            for(String key : mFieldName_Value.keySet()) {
                if(mFieldName_Value.get(key) instanceof Boolean) {
                    System.assert(!(Boolean)mFieldName_Value.get(key));
                }
            }
            Test.stopTest();
        }
    }
}