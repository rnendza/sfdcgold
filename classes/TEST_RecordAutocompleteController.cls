@IsTest
private class TEST_RecordAutocompleteController{

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';

    @TestSetup
    static void setup() {
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
    }

    @IsTest
    static void test_buildWhereCriteria() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            String searchTerm = 'rockon',primaryFilterField = 'name',secondaryFilterField = 'email';
            String whereCriteria = RecordAutocompleteController.buildWhereCriteria(searchTerm,primaryFilterField,secondaryFilterField);
            System.debug('---> rjn where='+whereCriteria);
            System.assert(whereCriteria.containsIgnoreCase('name LIKE \'%rockon%\' OR email LIKE \'%rockon%\''));

            secondaryFilterField = null;
            whereCriteria = RecordAutocompleteController.buildWhereCriteria(searchTerm,primaryFilterField,secondaryFilterField);
            System.assert(whereCriteria.containsIgnoreCase('name LIKE \'%rockon%\''));

            Test.stopTest();
        }
    }

    @IsTest
    static void test_buildSelectFields() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            String primaryDisplayField = 'Name', secondaryDisplayField ='Email',primaryFilterField='Name';

            List<String> selectFields = RecordAutocompleteController.buildSelectFields( primaryDisplayField,
                                                                                        secondaryDisplayField,
                                                                                        primaryFilterField );
            System.assert(selectFields.contains('Id'));
            System.assert(selectFields.contains(primaryDisplayField));
            System.assert(selectFields.contains(secondaryDisplayField));

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

            String  searchTerm='T',primaryDisplayField = 'Name', secondaryDisplayField ='Email',
                    primaryFilterField='Name',secondaryFilterField=null, additionalWhereClause = null;
            Integer iMinChars = 3,iMaxRows = 100;
            Boolean preload = false;



            // (1)  not enough chars entered.
            ResponseDto dto = RecordAutocompleteController.retrieveSObjectResults(sObjectApiName,primaryDisplayField,
                    secondaryDisplayField,searchTerm,primaryFilterField,secondaryFilterField,iMinChars,additionalWhereClause,null,null,preload,iMaxRows);
            System.assert(!dto.isSuccess);
            System.assert(dto.technicalMsg.contains('not enough char'));

            // (2) good search  on name
            searchTerm = adminUser.Name;
            dto = RecordAutocompleteController.retrieveSObjectResults(sObjectApiName,primaryDisplayField,secondaryDisplayField,
                    searchTerm,primaryFilterField,secondaryFilterField,iMinChars,additionalWhereClause,null,null,preload,iMaxRows);
            System.assert(dto.isSuccess);
            List<SObject> sObjects = (List<SObject>)dto.values.get(RecordAutocompleteController.MAP_KEY_SOBJECT_RESULTS);
            for(SObject sObj : sObjects) {
                System.assert(sObj.getSObjectType() == sObjectTypeUser);
                User user = (User)sObj;
                System.assert(user.Id == adminUser.Id);
            }

            //(3) good search with extended where criteria.
            searchTerm = adminUser.Name;
            adminUser = [SELECT Id, Name, Email FROM User Where Id = :adminUser.Id];
            additionalWhereClause = '  Email = \''+adminUser.Email+'\'';

            dto = RecordAutocompleteController.retrieveSObjectResults(sObjectApiName,primaryDisplayField,secondaryDisplayField,
                    searchTerm,primaryFilterField,secondaryFilterField,iMinChars,additionalWhereClause,null,null,preload,iMaxRows);
            System.assert(dto.isSuccess);
            sObjects = (List<SObject>)dto.values.get(RecordAutocompleteController.MAP_KEY_SOBJECT_RESULTS);
            for(SObject sObj : sObjects) {
                System.assert(sObj.getSObjectType() == sObjectTypeUser);
                User user = (User)sObj;
                System.assert(user.Id == adminUser.Id);
            }



            //  (3a) sosl
            RecordAutocompleteController.USE_SOSL = true;
            dto = RecordAutocompleteController.retrieveSObjectResults(sObjectApiName,primaryDisplayField,secondaryDisplayField,
                    searchTerm,primaryFilterField,secondaryFilterField,iMinChars,additionalWhereClause,null,null,preload,iMaxRows);
            //System.assert(dto.isSuccess);
            sObjects = (List<SObject>)dto.values.get(RecordAutocompleteController.MAP_KEY_SOBJECT_RESULTS);
//            for(SObject sObj : sObjects) {
//                System.assert(sObj.getSObjectType() == sObjectTypeUser);
//                User user = (User)sObj;
//                System.assert(user.Id == adminUser.Id);
//            }
            RecordAutocompleteController.USE_SOSL = false;
            // (4) good search  on defaultRecordSelectedId with additionalWhereCriteria
            searchTerm = null;
            preload = true;
            dto = RecordAutocompleteController.retrieveSObjectResults(sObjectApiName,primaryDisplayField,secondaryDisplayField,
                    searchTerm,primaryFilterField,secondaryFilterField,iMinChars,additionalWhereClause,null,adminUser.Id,preload,iMaxRows);
            //System.assert(dto.isSuccess);
            sObjects = (List<SObject>)dto.values.get(RecordAutocompleteController.MAP_KEY_SOBJECT_RESULTS);
            for(SObject sObj : sObjects) {
                System.assert(sObj.getSObjectType() == sObjectTypeUser);
                User user = (User)sObj;
                System.assert(user.Id == adminUser.Id);
            }

            // (5) good search  on defaultRecordSelectedId without additionalWhereCriteria
//            searchTerm = null;
//            preload = true;
//            additionalWhereClause = null;
//            dto = RecordAutocompleteController.retrieveSObjectResults(sObjectApiName,primaryDisplayField,secondaryDisplayField,
//                    searchTerm,primaryFilterField,secondaryFilterField,iMinChars,additionalWhereClause,null,adminUser.Id,preload,iMaxRows);
//            System.assert(dto.isSuccess);
//            sObjects = (List<SObject>)dto.values.get(RecordAutocompleteController.MAP_KEY_SOBJECT_RESULTS);
//            Boolean foundUserId = false;
//            for(SObject sObj : sObjects) {
//                System.assert(sObj.getSObjectType() == sObjectTypeUser);
//                User user = (User)sObj;
//                if(user.Id == adminUser.Id) {
//                    foundUserId = true;
//                    break;
//                }
//            }
//            System.assert(foundUserId);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveSelectedSObjectResult() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            SObjectType sObjectTypeUser = User.getSObjectType();
            String  sObjectApiName=sObjectTypeUser.getDescribe().getName();

            String  searchTerm='T',primaryDisplayField = 'Name', secondaryDisplayField ='Email',
                    primaryFilterField='Name',secondaryFilterField=null, additionalWhereClause = null;
            Integer iMinChars = 3,iMaxRows = 100;
            Boolean preload = false;

            ResponseDto dto = RecordAutocompleteController.retrieveSelectedSObjectResult(sObjectApiName,primaryDisplayField,
                    secondaryDisplayField,UserInfo.getUserId());

            //@todo asserts
            System.debug('rjn dto'+dto);

            Test.stopTest();
        }
    }
}