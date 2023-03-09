@IsTest
private class TEST_SandboxPostCopySvc {

    @testSetup
    static void setup() {
        // Add at lease once user with invalid email since prod probably won't have it
        User u =  TestUtils.getUserForTest('blahbaduser@blah.com');
        u.Email = u.email + SandboxPostCopySvc.INVALID_EMAIL_STRING;
        update u;
    }

    @IsTest
    static void testEmailUpdate() {

        User autoProc = [SELECT Id FROM USER WHERE Alias = 'autoproc'];

        System.runas(autoProc) {
            Test.startTest();
            Test.testSandboxPostCopyScript(new SandboxPostCopySvc(), UserInfo.getOrganizationId(), UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
            Test.stopTest();
        }
    }
}