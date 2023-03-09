@IsTest
private class TEST_VideoController {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP        = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME    = 'mollys unit test';
    public static String PROFILENAMECP  = 'Accel Customer Community';
    public static String ROLENAME       = 'AdminRoleName';

    @TestSetup
    static void setup() {
        User adminUser = TestUtils.createAdminUserWithRole(UNAMEADMIN,ROLENAME);
        System.runAs(adminUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        }
    }

    @IsTest
    static void testRetrieveVideoSettings_positive() {
        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

        System.runAs(communityUser) {
            Test.startTest();

            ResponseDto dto = VideoController.retrieveVideoMetadata('Community');
            System.assert(dto.isSuccess);
            SObject sObj = (SObject)dto.values.get(VideoController.MAP_KEY_VIDEO_METADATA);
            System.assert(sObj != null);
            Video_Setting__mdt videoSetting = (Video_Setting__mdt)sObj;
            System.assert(videoSetting.Endpoint__c != null);

            Test.stopTest();
        }
    }
    @IsTest
    static void testRetrieveVideoSettings_negative() {
        User communityUser = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);

        System.runAs(communityUser) {
            Test.startTest();

            ResponseDto dto = VideoController.retrieveVideoMetadata('Bogus settings record');
            System.assert(!dto.isSuccess);
            System.assert(dto.message != null);

            Test.stopTest();
        }
    }
}