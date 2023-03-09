@IsTest
private class LoginHistoryParamsTest {

    @IsTest
    static void test_constructor() {

        Test.startTest();

        LoginHistoryParams params = new LoginHistoryParams();

        params.userIds.add(UserInfo.getUserId());
        params.profileIds.add(UserInfo.getProfileId());
        params.startDate = System.now().addDays(-5);
        params.endDate = System.now();

        System.assert(params.userIds.contains(UserInfo.getUserId()));
        System.assertEquals(AuditTrailParams.DEFAULT_LIMIT,params.iLimit);

        Test.stopTest();
    }
}