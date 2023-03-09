@IsTest
private class UserParamsTest {

    @IsTest
    static void test_constructor() {

        Test.startTest();

        UserParams params = new UserParams();

        params.userIds.add(UserInfo.getUserId());
        params.userTypes.add('Standard');
        System.assertEquals(AuditTrailParams.DEFAULT_LIMIT,params.iLimit);

        Test.stopTest();
    }
}