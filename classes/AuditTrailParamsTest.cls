@IsTest
private class AuditTrailParamsTest {

    @IsTest
    static void test_constructor() {

        Test.startTest();

        AuditTrailParams params = new AuditTrailParams();

        params.userIds.add(UserInfo.getUserId());
        params.profileIds.add(UserInfo.getProfileId());
        params.includeActions.add('changedApexClass');
        params.excludeActions.add('changedPassword');
        params.startDate = System.now().addDays(-5);
        params.endDate = System.now();
        params.devOnlyActions = true;
        params.userTypes.add('System Admin');

        System.assert(params.userIds.contains(UserInfo.getUserId()));
        System.assertEquals(AuditTrailParams.DEFAULT_LIMIT,params.iLimit);

        Test.stopTest();
    }
}