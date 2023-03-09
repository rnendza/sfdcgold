@IsTest
private class TEST_AcContactProfileSettingsController {

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
    @IsTest public static void test_retrieveCommunitySettings_Settings_Positive() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        //Trigger creates setting for customer portal user upon insert of user
        Community_User_Setting__c cus = [SELECT Id, User__c, Contact__c FROM Community_User_Setting__c WHERE User__c = :communityUser.Id];
        System.runAs(communityUser) {

            Test.startTest();

            ResponseDto dto = AcContactProfileSettingsController.retrieveCommunityUserSettings();
            System.assert(dto.isSuccess);

            Community_User_Setting__c uiCus = (Community_User_Setting__c)dto.values
                    .get(AcContactProfileSettingsController.COMMUNITY_USER_PROFILE_SETTINGS);

            System.assertEquals(uiCus.Id,cus.Id);
            System.assertEquals(uiCus.User__c,cus.User__c);
            System.assertEquals(uiCus.Contact__c,cus.Contact__c);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void test_updateCommunityUserSettings_As_Indirect_Positive() {
        User portalUser =  TestUtils.getPortalUserForTest(PROFILENAME_INDIRECTCP, ACCOUNTNAME, UNAMECP);
        //Trigger creates setting for customer portal user upon insert of user
        Community_User_Setting__c cus = [SELECT Id, User__c, Contact__c FROM Community_User_Setting__c WHERE User__c = :portalUser.Id];
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
            ResponseDto dto = AcContactProfileSettingsController.updateCommunityUserSettings(uiSetting);
            System.assert(dto.isSuccess);
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