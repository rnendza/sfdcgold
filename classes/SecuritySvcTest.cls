@IsTest
private class SecuritySvcTest {

    private final static String ACCOUNT_API_NAME = Account.getSObjectType().getDescribe().name;
    private final static String CONTACT_API_NAME = Contact.getSObjectType().getDescribe().name;
    private final static String SYS_ADMIN_PROFILE = 'System Administrator';
    private final static String TEST_CL_PERM_SET = 'Cash_Logistics_Read_Edit_Access';

    @IsTest
    static void test_retrieveSObjectSecurityInfo_single_sObject() {

        Test.startTest();

        List<FieldPermissions> fieldPermissions =
                SecuritySvc.retrieveSObjectSecurityInfo(ACCOUNT_API_NAME,new Set<String>{TEST_CL_PERM_SET},new Set<String>{SYS_ADMIN_PROFILE});

        System.assert(!fieldPermissions.isEmpty(),'Field Permissions should not be empty');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveSObjectSecurityInfo_multiple_sObjects() {

        Test.startTest();

        List<String> sObjectApiNames = new List<String>{ACCOUNT_API_NAME,CONTACT_API_NAME};
        List<FieldPermissions> fieldPermissions =
                SecuritySvc.retrieveSObjectSecurityInfo(sObjectApiNames,new Set<String>{TEST_CL_PERM_SET},new Set<String>{SYS_ADMIN_PROFILE});

        System.assert(!fieldPermissions.isEmpty(),'Field Permissions should not be empty');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveProfileInfo() {

        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = :SYS_ADMIN_PROFILE];

        Test.startTest();

        Map<Id,Profile>  mProfile = SecuritySvc.retrieveProfileInfo(new Set<Id> {adminProfile.Id});
        System.assert(mProfile.get(adminProfile.Id) != null,'Could not find admin profile!');

        mProfile = SecuritySvc.retrieveProfileInfo(new Set<String> {SYS_ADMIN_PROFILE});
        System.assert(mProfile.get(adminProfile.Id) != null,'Could not find admin profile!');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllPermissionSets() {


        Test.startTest();

        Map<Id,PermissionSet>  mPermissionSetsByIds = SecuritySvc.retrieveAllPermissionSets();
        System.assert(!mPermissionSetsByIds.isEmpty(),'Could not find permission sets!');

        mPermissionSetsByIds = SecuritySvc.retrieveAllPermissionSets(false,false);
        System.assert(!mPermissionSetsByIds.isEmpty(),'Could not find permission sets that are not custom and not owned by profile!');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllProfiles() {


        Test.startTest();

        Map<Id,Profile>  mProfilesByIds = SecuritySvc.retrieveAllProfiles();
        System.assert(!mProfilesByIds.isEmpty(),'Could not find profiles!');

        Test.stopTest();
    }

    @IsTest
    static void test_retrievePermissionSetAssignments() {

        List<PermissionSet> pss = [
                SELECT Id,Name
                FROM   PermissionSet
                LIMIT  5
        ];
        Set<String> pssNames = new Set<String>();
        for(PermissionSet ps : pss) {
            pssNames.add(ps.Name);
        }

        Test.startTest();

        Map<Id,PermissionSetAssignment>  m = SecuritySvc.retrievePermissionSetAssignments(pssNames);
        System.assert(!m.isEmpty(),'Could not find permission set assignments');

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveProfileUsers() {

        List<PermissionSet> pss = [
                SELECT Id,Name
                FROM   PermissionSet
                LIMIT  5
        ];
        Set<String> pssNames = new Set<String>();
        for(PermissionSet ps : pss) {
            pssNames.add(ps.Name);
        }

        List<Profile> profiles = [
                SELECT Id,Name
                FROM   Profile
                LIMIT  5
        ];
        Set<String> profileNames = new Set<String>();
        for(Profile ps : profiles) {
            profileNames.add(ps.Name);
        }

        Test.startTest();

        Map<Id,User> m = SecuritySvc.retrieveProfileUsers(profileNames);
        System.assert(!m.isEmpty(),'Could not find profile users');

        Test.stopTest();
    }

    @IsTest
    static void test_retrievePermissionsForObjects() {

        Set<Id> objectParentIds = new Set<Id>();

        List<PermissionSet> pss = [
                SELECT Id,Name
                FROM   PermissionSet
                WHERE  Name Like '%Cash%'
                LIMIT  5
        ];
        Set<String> pssNames = new Set<String>();
        for(PermissionSet ps : pss) {
            pssNames.add(ps.Name);
        }

        Map<Id,PermissionSetAssignment> m = SecuritySvc.retrievePermissionSetAssignments(pssNames);
        for(PermissionSetAssignment psa : m.values()) {
            objectParentIds.add(psa.PermissionSetId);
        }

        List<Profile> profiles = [
                SELECT Id,Name
                FROM   Profile
                WHERE  Name LIKE '%CL%'
                LIMIT  20
        ];
        Set<String> profileNames = new Set<String>();
        for(Profile ps : profiles) {
            profileNames.add(ps.Name);
        }

        Map<Id,User> m2 = SecuritySvc.retrieveProfileUsers(profileNames);
        for(User user : m2.values()) {
            objectParentIds.add(user.ProfileId);
        }

        Set<String> sObjects = new Set<String>{'Account','Contact','Route__c'};
        Test.startTest();

        Map<Id,ObjectPermissions> mObjects = SecuritySvc.retrievePermissionForObject(objectParentIds,sObjects);
        System.assert(!mObjects.isEmpty(),'Could not find object perms');

        Test.stopTest();
    }
    @IsTest
    static void test_retrievePermSetUsers() {

        Set<Id> objectParentIds = new Set<Id>();

        List<PermissionSet> pss = [
                SELECT Id,Name
                FROM   PermissionSet
                WHERE  Name Like '%Cash%'
                LIMIT  5
        ];
        Set<String> pssNames = new Set<String>();
        for(PermissionSet ps : pss) {
            pssNames.add(ps.Name);
        }

        Map<Id,PermissionSetAssignment> m = SecuritySvc.retrievePermissionSetAssignments(pssNames);
        for(PermissionSetAssignment psa : m.values()) {
            objectParentIds.add(psa.PermissionSetId);
        }

        List<Profile> profiles = [
                SELECT Id,Name
                FROM   Profile
                WHERE  Name LIKE '%CL%'
                LIMIT  20
        ];
        Set<String> profileNames = new Set<String>();
        for(Profile ps : profiles) {
            profileNames.add(ps.Name);
        }

        Map<Id,User> m2 = SecuritySvc.retrieveProfileUsers(profileNames);
        for(User user : m2.values()) {
            objectParentIds.add(user.ProfileId);
        }

        Test.startTest();

        Map<String,Map<Id,User>> mPermSetUsers = SecuritySvc.retrievePermSetUsers(pssNames);

        Test.stopTest();
    }
//    @IsTest
//    static void test_retrieveTracked() {
//
//        List<PermissionSet> pss = [
//                SELECT Id,Name
//                FROM   PermissionSet
//                LIMIT  5
//        ];
//        Set<String> pssNames = new Set<String>();
//        for(PermissionSet ps : pss) {
//            pssNames.add(ps.Name);
//        }
//
//        Test.startTest();
//
//        Map<Id,PermissionSetAssignment>  m = SecuritySvc.retrievePermissionSetAssignments(pssNames);
//        System.assert(!m.isEmpty(),'Could not find permission set assignments');
//
//        Test.stopTest();
//    }

}