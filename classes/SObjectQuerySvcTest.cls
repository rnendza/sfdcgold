@IsTest
private class SObjectQuerySvcTest{

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';

    @TestSetup
    static void setup() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
    }

    @IsTest
    static void test_retrieveRecentlyViewedSObjectResults() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            SObjectType sObjectTypeUser = User.getSObjectType();
            String  sObjectApiName=sObjectTypeUser.getDescribe().getName();

            List<String> selectFields = new List<String>{'FirstName','LastName'};
            String orderBy = 'LastName ASC';
            List<SObject> sObjs = SObjectQuerySvc.retrieveRecentlyViewedSObjectResults(sObjectApiName,selectFields,orderBy,100);
            System.assert(!sObjs.isEmpty());
            System.debug('rick sobjs'+sObjs);

            Test.stopTest();
        }
    }


    @IsTest
    static void test_retrieveSObjectResults() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            SObjectType sObjectTypeUser = User.getSObjectType();
            String  sObjectApiName=sObjectTypeUser.getDescribe().getName();

            List<String> selectFields = new List<String>{'FirstName','LastName'};
            String whereCriteria = 'IsActive = TRUE';
            String orderBy = 'LastName ASC';
            List<SObject> sObjs = SObjectQuerySvc.retrieveSObjectResults(sObjectApiName,selectFields,whereCriteria,orderBy,100);
            System.assert(!sObjs.isEmpty());
            System.debug('rick sobjs'+sObjs);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveSoslSObjectResults() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            User user = [
                    SELECT Id,FirstName,LastName
                    FROM   User
                    WHERE  IsActive = TRUE
                    Order By LastName ASC NULLS LAST
                    LIMIT 1
            ];
            SObjectType sObjectTypeUser = User.getSObjectType();
            String  sObjectApiName=sObjectTypeUser.getDescribe().getName();

            List<String> selectFields = new List<String>{'FirstName','LastName'};
            String whereCriteria = 'IsActive = TRUE';
            String orderBy = 'LastName ASC';
            String searchTerm = User.FirstName + ' ' +user.LastName;

            Test.startTest();

            List<SObject> sObjs = SObjectQuerySvc.retrieveSoslSObjectResults(sObjectApiName,selectFields,searchTerm,whereCriteria,orderBy,100);
            //System.assert(!sObjs.isEmpty());

            Test.stopTest();
        }
    }

}