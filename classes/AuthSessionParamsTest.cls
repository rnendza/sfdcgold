@IsTest
private class AuthSessionParamsTest {

    @IsTest
    static void test_constructor() {


        Test.startTest();

        AuthSessionParams params = new AuthSessionParams();
        params.userIds.add(UserInfo.getUserId());
        params.sessionTypes.add('UI');
        params.loginTypes.add('Application');

        System.assert(params.userIds.contains(UserInfo.getUserId()));
        System.assertEquals(AuthSessionParams.DEFAULT_LIMIT,params.iLimit);

        Test.stopTest();
    }
}