/**
 * Note... AuthSession is readonly object so we must be evil here and seeAllData.
 */
@IsTest(SeeAllData=true)
private class AuthSessionSvcTest {

    @IsTest
    static void test_retrieveAuthSessions() {

        AuthSessionParams params = new AuthSessionParams();
        params.userIds.add(UserInfo.getUserId());
        params.sessionTypes.add('UI');
        params.loginTypes.add('Application');

        Test.startTest();

        List<AuthSession> authSessions = AuthSessionSvc.retrieveAuthSessions(params);
        System.debug('--->'+authSessions);
        //@Todo asserts

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveActiveLoggedInUsers() {

        Test.startTest();

        Map<Id,String> mUsers = AuthSessionSvc.retrieveActiveLoggedInUsers();
        //@Todo asserts

        Test.stopTest();
    }
}