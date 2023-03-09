/**
 * Note... SetupAuditTrail is readonly object so we must be evil here and seeAllData.
 */
@IsTest(SeeAllData=true)
private class AuditTrailControllerTest {


    @IsTest
    static void test_retrieveAuditTrails() {

        AuditTrailParams params = new AuditTrailParams();

        params.userIds.add(UserInfo.getUserId());
        params.iLimit = 100;
        params.profileIds.add(UserInfo.getProfileId());
        params.includeActions.add('changedApexClass');
        params.excludeActions.add('changedPassword');
        params.startDate = System.now().addDays(-5);
        params.endDate = System.now();
        params.devOnlyActions = true;

        Test.startTest();

        ResponseDto dto = AuditTrailController.retrieveAuditTrails(params);
        List<AuditTrailController.AuditTrailWrapper> wraps =
                (List<AuditTrailController.AuditTrailWrapper>)dto.values.get(AuditTrailController.MAP_KEY_AUDIT_TRAIL_WRAPS);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAdminUsers() {

        Test.startTest();
        ResponseDto dto = AuditTrailController.retrieveAdminUsers();
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveWestMonroeUsers() {

        Test.startTest();
        ResponseDto dto = AuditTrailController.retrieveWestMonroeUsers();
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllProfiles() {

        Test.startTest();
        ResponseDto dto = AuditTrailController.retrieveAllProfiles();
        Test.stopTest();
    }
}