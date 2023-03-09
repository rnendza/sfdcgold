@IsTest
private class clSecurityAuditControllerTest {


    @IsTest
    static void test_retrieveFieldPermissions() {

        ResponseDto dtoMdt = clSecurityAuditController.retrieveSecurityAuditMetadata(clSecurityAuditController.MDT_FIELD_AUDIT_DEV_NAME);
        Cash_Logistics_Security_Audit_Setting__mdt mdt =
                (Cash_Logistics_Security_Audit_Setting__mdt)dtoMdt.values.get(clSecurityAuditController.MAP_KEY_SECURITY_AUDIT_MDT);
        List<String> profileNames = mdt.Profile_Names__c.split(',');
        List<String> psApiNames = mdt.Permission_Set_Names__c.split(',');
        Map<Id,PermissionSet> mPermSets = SecuritySvc.retrievePermissionSetInfo(new Set<String>(psApiNames));

        Test.startTest();

        clSecurityAuditController.DEBUG_MAP = true;
        ResponseDto dto = clSecurityAuditController.retrieveFieldPermissions();

        Map<String, Map<String, Map<String, clSecurityAuditController.CustomFieldPerm>>> m =
                (Map<String, Map<String, Map<String, clSecurityAuditController.CustomFieldPerm>>>)dto.values.get(clSecurityAuditController.MAP_KEY_FIELD_PERM_DATA);

        System.assert(!m.isEmpty(),' Could not field any user audit security data');
        for(String profileName : profileNames) {
            System.assert(m.containsKey(profileName),' Could not find data for profile: '+profileName);
        }
        for(PermissionSet permissionSet : mPermSets.values()) {
            System.assert(m.containsKey(permissionSet.Label),' Could not find data for permission set: '+permissionSet);
        }

        clSecurityAuditController.debugFieldAuditMap(m);

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveUserPermissions() {

        Test.startTest();
        clSecurityAuditController.DEBUG_MAP = true;
        ResponseDto dto = clSecurityAuditController.retrieveUserPermissions();
        //clSecurityAuditController.debugFieldAuditMap(m);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveFieldPermissionsByParams() {

        ResponseDto dtoMdt = clSecurityAuditController.retrieveSecurityAuditMetadata(clSecurityAuditController.MDT_FIELD_AUDIT_DEV_NAME);
        Cash_Logistics_Security_Audit_Setting__mdt mdt =
                (Cash_Logistics_Security_Audit_Setting__mdt)dtoMdt.values.get(clSecurityAuditController.MAP_KEY_SECURITY_AUDIT_MDT);

        List<String> profileNames = mdt.Profile_Names__c.split(',');
        profileNames.add('System Administrator');
        List<String> permSetNames = mdt.Permission_Set_Names__c.split(',');
        List<String> sObjectApiNames = mdt.sObject_Api_Names__c.split(',');


        Test.startTest();

        System.runAs(new User(Id=UserInfo.getUserId())) {

            ResponseDto dto = clSecurityAuditController.retrieveFieldPermissionsByParams(profileNames, permSetNames, sObjectApiNames);
            Map<String, Map<String, Map<String, clSecurityAuditController.CustomFieldPerm>>> m =
                    (Map<String, Map<String, Map<String, clSecurityAuditController.CustomFieldPerm>>>) dto.values.get(clSecurityAuditController.MAP_KEY_FIELD_PERM_DATA);
            System.assert(!m.isEmpty(), ' Could not field field permission data');

            clSecurityAuditController.debugFieldAuditMap(m);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveUserPermissionsByParams() {

        ResponseDto dtoMdt = clSecurityAuditController.retrieveSecurityAuditMetadata(clSecurityAuditController.MDT_USER_PERM_AUDIT_DEV_NAME);
        Cash_Logistics_Security_Audit_Setting__mdt mdt =
                (Cash_Logistics_Security_Audit_Setting__mdt)dtoMdt.values.get(clSecurityAuditController.MAP_KEY_SECURITY_AUDIT_MDT);

        List<String> profileNames = mdt.Profile_Names__c.split(',');
        List<String> permSetNames = mdt.Permission_Set_Names__c.split(',');

        Test.startTest();

        ResponseDto dto = clSecurityAuditController.retrieveUserPermissionsByParams(profileNames,permSetNames);
        Map<String, Map<String,clSecurityAuditController.CustomUserPerm>> m =
                (Map<String, Map<String,clSecurityAuditController.CustomUserPerm>>)dto.values.get(clSecurityAuditController.MAP_KEY_USER_PERM_DATA);
        System.assert(!m.isEmpty(),' Could not find user permission data');

        clSecurityAuditController.debugUserSecMap(m);

        Test.stopTest();
    }
}