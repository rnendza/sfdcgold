@IsTest
private class TEST_LookupUserController {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';
    public static String PROFILENAME_INDIRECTCP = 'Indirect User Community Standard';

    @TestSetup
    static void setup() {

        UserRole adminRole = new UserRole(DeveloperName = 'TestAdminRole', Name = 'TestAdminRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;
        User runningUser = adminUser;

        System.runAs(runningUser) {

            Test.startTest();
            Integer iNumUsers = 10;
            List<User> portalUsers = TestUtils.createPortalUsersForTest(PROFILENAME_INDIRECTCP,'test account',UNAMECP,iNumUsers);
            System.assertEquals(portalUsers.size(),iNumUsers);

            List<Community_User_Setting__c> communityUserSettings = [
                    SELECT  Id, Contact__c, User__c
                    FROM    Community_User_Setting__c
            ];
            //----- settings intentionally not created for admin user in setup.
            Test.stopTest();
        }
    }

    @IsTest
    static void search_should_return_User() {
        Id[] fixedResults = new List<Id>(1);
        User user = [SELECT Id,Name FROM User LIMIT 1];
        fixedResults.add(user.Id);
        Test.setFixedSearchResults(fixedResults);

        List<String> selectedIds = new List<String>();

        List<LookupSearchResult> results = LookupUserController.search(user.Name, selectedIds);

        System.assertEquals(1, results.size());
        System.assertEquals(user.Id, results.get(0).getId());

        //random for now.
        LookupSearchResult lookupSearchResult = new LookupSearchResult(user.Id,'User','standard:user','title','subtitle');
        lookupSearchResult.getId();
        lookupSearchResult.getSObjectType();
        lookupSearchResult.getIcon();
        lookupSearchResult.getTitle();
        lookupSearchResult.getSubtitle();
    }

//    static testMethod void search_should_not_return_selected_item() {
//        Id[] fixedResults = new List<Id>(1);
//        Account account1 = createTestAccount('Account1');
//        fixedResults.add(account1.Id);
//        Account account2 = createTestAccount('Account2');
//        fixedResults.add(account2.Id);
//        Test.setFixedSearchResults(fixedResults);
//        List<String> selectedIds = new List<String>();
//        selectedIds.add(account2.Id);
//
//        List<LookupSearchResult> results = SampleLookupController.search(
//                'Acc',
//                selectedIds
//        );
//
//        System.assertEquals(1, results.size());
//        System.assertEquals(account1.Id, results.get(0).getId());
//    }

}