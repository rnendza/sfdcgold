/**
 * Note... AuthSession is readonly object so we must be evil here and seeAllData.
 */
@IsTest(SeeAllData=true)
private class AuthSessionControllerTest {


    @IsTest
    static void test_retrieveAuthSessions() {

        AuthSessionParams params = new AuthSessionParams();
        params.userIds.add(UserInfo.getUserId());
        params.sessionTypes.add('UI');
        params.loginTypes.add('Application');

        Test.startTest();

        ResponseDto dto = AuthSessionController.retrieveAuthSessions(params);
        List<AuthSessionController.AuthSessionWrapper> wraps =
                (List<AuthSessionController.AuthSessionWrapper>)dto.values.get(AuthSessionController.MAP_KEY_AUTH_SESSION_WRAPS);

        Test.stopTest();
    }

    @IsTest
    static void test_removeAuthSessions() {

        AuthSessionParams params = new AuthSessionParams();
        params.userIds.add(UserInfo.getUserId());
        params.sessionTypes.add('UI');
        params.loginTypes.add('Application');
        ResponseDto dto = AuthSessionController.retrieveAuthSessions(params);
        List<AuthSessionController.AuthSessionWrapper> wraps =
                (List<AuthSessionController.AuthSessionWrapper>)dto.values.get(AuthSessionController.MAP_KEY_AUTH_SESSION_WRAPS);

        Test.startTest();

        dto = AuthSessionController.removeAuthSessions(new List<Id>{wraps[0].authSessionId});
        System.assert(dto.isSuccess);
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveActiveLoggedInUsers() {

        Test.startTest();

        ResponseDto dto = AuthSessionController.retrieveActiveLoggedInUsers();

        Test.stopTest();
    }

}