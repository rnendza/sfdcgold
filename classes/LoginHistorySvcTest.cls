/**
 * Note... LoginHistory is readonly object so we must be evil here and seeAllData.
 */
@IsTest(SeeAllData=true)
private class LoginHistorySvcTest {

    @IsTest
    static void test_retrieveLoginHistories() {
        LoginHistoryParams params = new LoginHistoryParams();

        params.userIds.add(UserInfo.getUserId());
        params.profileIds.add(UserInfo.getProfileId());
        params.iLimit = 10;
        params.startDate = System.now().addDays(-5);
        params.endDate = System.now();

        Test.startTest();

        List<LoginHistory> loginHistories = LoginHistorySvc.retrieveLoginHistories(params);
        System.debug('--->'+loginHistories);
        //@Todo asserts

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveLoginHistoryUsers() {

        Set<Id> userIds = new Set<Id> {UserInfo.getUserId()};

        Test.startTest();

        Map<Id,User> mUsers = LoginHistorySvc.retrieveLoginHistoryUsers(userIds);
        for(Id userId : mUsers.keySet()) {
            System.assert(userIds.contains(userId));
        }
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

        List<User> users = LoginHistorySvc.retrieveUsers(params);
        System.debug('--->1'+users);

        params.activeInactives.clear();
        params.activeInactives.add('active');
        users = LoginHistorySvc.retrieveUsers(params);
        System.debug('--->2'+users);


        params.activeInactives.clear();
        params.activeInactives.add('inactive');
        users = LoginHistorySvc.retrieveUsers(params);
        System.debug('--->3'+users);

        //@Todo asserts



        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllUsers() {

        Test.startTest();

        Map<Id,String> mUsers = LoginHistorySvc.retrieveAllUsers();
        System.debug('--->'+mUsers);
        //@Todo asserts

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveAdminUsers() {

        Test.startTest();

        Map<Id,String> mUsers = LoginHistorySvc.retrieveAdminUsers();
        System.debug('--->'+mUsers);
        //@Todo asserts

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveWestMonroeUsers() {

        Test.startTest();

        Map<Id,String> mUsers = LoginHistorySvc.retrieveWestMonroeUsers();
        System.debug('--->'+mUsers);
        //@Todo asserts

        Test.stopTest();
    }
}