@IsTest
private class clPublicControllerTest {

    @IsTest
    static void test_retrieveMdt() {
        Test.startTest();
        ResponseDto dto = clPublicController.retrieveMdt('Application');
        System.assertEquals(dto.isSuccess,true);
        Test.stopTest();
    }

    @IsTest
    static void test_getSessionId() {
        Test.startTest();
            System.assertEquals(UserInfo.getSessionId(),clPublicController.getSessionId());
        Test.stopTest();
    }
}