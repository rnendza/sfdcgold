/**
 * Note... LoginHistory is readonly object so we must be evil here and seeAllData.
 */
@IsTest(SeeAllData=true)
private class LoginHistoryControllerTest {


    @IsTest
    static void test_retrieveLoginHistories() {

        LoginHistoryParams params = new LoginHistoryParams();

        params.userIds.add(UserInfo.getUserId());
        params.iLimit = 10;
        params.profileIds.add(UserInfo.getProfileId());
        params.startDate = System.now().addDays(-5);
        params.endDate = System.now();

        Test.startTest();

        ResponseDto dto = LoginHistoryController.retrieveLoginHistories(params);
        List<LoginHistoryController.LoginHistoryWrapper> wraps =
                (List<LoginHistoryController.LoginHistoryWrapper>)dto.values.get(LoginHistoryController.MAP_KEY_LOGIN_HISTORY_WRAPS);
        System.assert(!wraps.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllUsers() {

        Test.startTest();
        ResponseDto dto = LoginHistoryController.retrieveAllUsers();
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveUsers() {

        UserParams params = new UserParams();
        params.userIds.add(UserInfo.getUserId());
        params.userTypes.add('Standard');
        params.activeInactives.add('active');
        params.activeInactives.add('inactive');
        params.iLimit = 10;


        Test.startTest();
        ResponseDto dto = LoginHistoryController.retrieveUsers(params);
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAdminUsers() {

        Test.startTest();
        ResponseDto dto = LoginHistoryController.retrieveAdminUsers();
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveWestMonroeUsers() {

        Test.startTest();
        ResponseDto dto = LoginHistoryController.retrieveWestMonroeUsers();
        Test.stopTest();
    }
}