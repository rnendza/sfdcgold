@IsTest
private class TEST_ACV2_Home {
    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    @TestSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;
        User setupUser = adminUser;

        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        }
    }

   /**
    * Test the Accel_CommunityHome.retrieveCommunitySettings (positive)
    * (1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
    */
    @IsTest static void test_RetrieveCommunityUsereSettings_Positive() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        Community_User_Setting__c cus = TestUtils.buildCommunityUserDisplaySetting(communityUser.Id, communityUser.ContactId);
        insert cus;

        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_CommunityHome.retrieveCommunityUserSettings();
            //--(1) Test that we find the Community_User_Setting__c sObject associated with the running community user and return it.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting != null);
            System.assert(communityUserSetting.User__c == communityUser.Id);
            Test.stopTest();
        }
    }
   /**
    * Test the Accel_CommunityHome.retrieveCommunitySettings (negative)
    * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with the running community user
    */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_Negative() {

        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        DELETE [Select Id FROM Community_User_Setting__c];
        System.runAs(communityUser) {
            Test.startTest();
            ResponseDto dto = Accel_CommunityHome.retrieveCommunityUserSettings();
            //--(1) Test that we could *NOT* find the Community_User_Setting__c sObject associated with the running community user.
            Community_User_Setting__c communityUserSetting = (Community_User_Setting__c)dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting == null);
            Test.stopTest();
        }
    }
    /**
     * Test the Accel_CommunityHome.retrieveCommunitySettings (negative)
     * (1) Test that we could  *NOT* find the Community_User_Setting__c sObject associated with a non community admin user.
     */
    @IsTest static void test_RetrieveCommunityUserSettings_No_Setting_AsAdmin_Negative() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            ResponseDto dto = Accel_CommunityHome.retrieveCommunityUserSettings();
            Community_User_Setting__c communityUserSetting;
            communityUserSetting = (Community_User_Setting__c) dto.values.get(CommunityConstants.COMMUNITY_SETTINGS);
            System.assert(communityUserSetting == null);
            System.assert(!dto.isSuccess);
            System.assert(dto.technicalMsg.contains('You are not a valid community user'));
            System.debug(dto);
            Test.stopTest();
        }
    }
}
//@isTest (seeAllData=true)
//private class TEST_ACV2_Home {
//    public static String UNAME = 'hucks@accelentertainment.com';
////
////    @isTest  static void testGetClosestAccounts() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.getClosestAccounts(myId, 'Bar');
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testRetrieveAccounts() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.retrieveAccounts();
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testRetrieveHpdData() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.retrieveHpdData();
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testRetrieveMonthlyHpdData() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.retrieveMonthlyHpdData();
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testGetClosestHpds() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.getClosestHpds(idList);
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testGetClosestMonthlyHpds() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.getClosestMonthlyHpds(idList);
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testGetAccountDailyData() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.getAccountDailyData(idList[0]);
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testGetAccountMonthlyData() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.getAccountMonthlyData(idList[0]);
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testRetrieveAllAccountsYoyData() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.retrieveAllAccountsYoyData();
////            Test.stopTest();
////        }
////    }
////    @isTest  static void testRetrieveSingleAccountYoyData() {
////        User communityUser = TESTUtils.getUserForTest(UNAME);
////        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
////
////        System.runAs(communityUser) {
////            Test.startTest();
////            Id myId = Id.valueOf('0011I00000Ux7wRQAR');
////            List<Id> idList = new List<Id>();
////            idList.add(myId);
////            ResponseDto dto;
////
////            dto = Accel_CommunityHome.retrieveSingleAccountYoyData(idList[0]);
////            Test.stopTest();
////        }
////    }
//}