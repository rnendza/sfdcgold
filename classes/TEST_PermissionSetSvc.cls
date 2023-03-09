@IsTest
private class  TEST_PermissionSetSvc {

    public static final String UNAMEADMIN                       = 'acceltestadmin@accelentertainment.com';
    public static final String PERMISSION_SET_API_NAME          = 'blah_permset_api_name';
    public static final String PERMISSION_SET_LABEL             = 'blah ps label';

    @TestSetup static void setup() {
       User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
       TestUtils.createPermissionSetAndAssignment(  PERMISSION_SET_LABEL,PERMISSION_SET_API_NAME,adminUser.Id );
    }

    @IsTest static void test_RetrieveUsersPermissionSetAssignments_Positive() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Map<Id, PermissionSetAssignment> dbPsas = new Map<Id, PermissionSetAssignment>([
                SELECT Id,PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId = :adminUser.Id
        ]);
        System.runAs(adminUser) {
            Test.startTest();
            //-- test that we retrieve every PSA available for the user and that one of thm was the one created in setup.
            List<PermissionSetAssignment> psas = PermissionSetSvc.retrieveUsersPermissionSetAssignments(adminUser.id);
            Boolean foundTestPsa =false;
            for(PermissionSetAssignment psa : psas) {
                System.assert(dbPsas.containsKey(psa.Id));
                if(psa.PermissionSet.Name == PERMISSION_SET_API_NAME) {
                    foundTestPsa = true;
                }
            }
            System.assert(foundTestPsa);
            Test.stopTest();
        }
    }

    @IsTest static void test_RetrieveUsersPermissionSetAssignments_Negative() {
        User differentAdminUser = TestUtils.getUserForTest('new_admin_no_psas@gmail.com');

        System.runAs(differentAdminUser) {
            Test.startTest();
            List<PermissionSetAssignment> psas = PermissionSetSvc.retrieveUsersPermissionSetAssignments(differentAdminUser.id);
            //-- test that we do not found the psa that was created in setup for a different user.
            Boolean foundTestPsa = false;
            for(PermissionSetAssignment psa : psas) {
                if(psa.PermissionSet.Name == PERMISSION_SET_API_NAME) {
                    foundTestPsa = true;
                }
            }
            System.assert(!foundTestPsa);
            Test.stopTest();
        }
    }
    @IsTest static void test_IsUserInPermissionSet_Positive() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            System.assert(PermissionSetSvc.isUserInPermissionSet(PERMISSION_SET_API_NAME));
            Test.stopTest();
        }
    }
    @IsTest static void test_IsUserInPermissionSet_Negative() {
        User differentAdminUser = TestUtils.getUserForTest('new_admin_no_psas@gmail.com');

        System.runAs(differentAdminUser) {
            Test.startTest();
            System.assert(!PermissionSetSvc.isUserInPermissionSet(PERMISSION_SET_API_NAME));
            Test.stopTest();
        }
    }
}