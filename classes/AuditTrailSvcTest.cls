/**
 * Note... SetupAuditTrail is readonly object so we must be evil here and seeAllData.
 */
@IsTest(SeeAllData=true)
private class AuditTrailSvcTest {

    @IsTest
    static void test_retrieveAuditTrails() {
        AuditTrailParams params = new AuditTrailParams();

        params.userIds.add(UserInfo.getUserId());
        params.profileIds.add(UserInfo.getProfileId());
        params.iLimit = 100;
        params.includeActions.add('changedApexClass');
        params.excludeActions.add('changedPassword');
        params.startDate = System.now().addDays(-5);
        params.endDate = System.now();
        params.devOnlyActions = true;


        Test.startTest();

        List<SetupAuditTrail> auditTrails = AuditTrailSvc.retrieveAuditTrails(params);
        System.debug('--->'+auditTrails);
        //@Todo asserts

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAdminUsers() {

        Test.startTest();

        Map<Id,String> mUsers = AuditTrailSvc.retrieveAdminUsers();
        System.debug('--->'+mUsers);
        //@Todo asserts

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveWestMonroeUsers() {

        Test.startTest();

        Map<Id,String> mUsers = AuditTrailSvc.retrieveWestMonroeUsers();
        System.debug('--->'+mUsers);
        //@Todo asserts

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllProfiles() {

        Test.startTest();

        Map<Id,String> mProfiles = AuditTrailSvc.retrieveAllProfiles();
        System.debug('--->'+mProfiles);
        //@Todo asserts

        Test.stopTest();
    }

}