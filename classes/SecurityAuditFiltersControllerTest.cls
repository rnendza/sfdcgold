@IsTest
private class SecurityAuditFiltersControllerTest {

    @IsTest
    static void test_retrieveAllProfiles() {

        Test.startTest();
        ResponseDto dto = SecurityAuditFiltersController.retrieveAllProfiles();
        List<Profile> profiles = (List<Profile>)dto.values.get(SecurityAuditFiltersController.MAP_KEY_PROFILES);
        System.assert(!profiles.isEmpty(),'Count not find profiles');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllPermissionSets() {

        Test.startTest();

        ResponseDto dto = SecurityAuditFiltersController.retrieveAllPermissionSets();
        List<PermissionSet> permSets = (List<PermissionSet>)dto.values.get(SecurityAuditFiltersController.MAP_KEY_PERMSETS);
        System.assert(!permSets.isEmpty(),'Count not find any permissionsets');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllSObjects() {

        Test.startTest();

        ResponseDto dto = SecurityAuditFiltersController.retrieveAllSObjects();
        List<SecurityAuditFiltersController.SObjectData> sObjectDatas =
                (List<SecurityAuditFiltersController.SobjectData>)dto.values.get(SecurityAuditFiltersController.MAP_KEY_SOBJECTS);

        System.assert(!sObjectDatas.isEmpty(),'Count not find any sobjects');

        Test.stopTest();
    }
}