@isTest


private class Test_LookupSearchClass {

    public static final String      USERNAME_ADMIN                           = 'acceltestadmin@accelentertainment.com';
    public static final String      ACCOUNT_NAME                             = 'UT Lookup Account';
    public static final String      KNOWN_SOBJECT_API_NAME                   = 'Account';

    /**
     * RJN Added 9/12 method to setup test data.
     * Builds Munis / Accounts / Contacts / Opps
     */
    @TestSetup static void setup() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('Test Muni',2);
        List<Account> accounts = new List<Account>();
        Integer i = 0;
        for(Municipality__c muni : munis) {
            accounts.add(TestUtils.buildAccount(ACCOUNT_NAME + i,muni.Id));
            i++;
        }
        insert accounts;
        List<Opportunity> testOpps = new List<Opportunity>();
        for(Account account : accounts) {
            testOpps.add(TestUtils.buildOpportunity(account));
        }
        insert testOpps;
    }
    /**
     * @todo asserts.
     */
    @isTest  static void Test_LookupSearchClass() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN); //RJN Add 9/12
        Account account = [SELECT Id, Name FROM Account LIMIT 1]; //  RJN ADD 9/12
        string ObjectName = 'Account'; //  RJN Add 9/12 to get rid of existing NPE.
        string recName;

        //  RJN Removed 9/12 - Hardcoded Id....Id recId = '0011I00000uPuwMQAS';
        Id recId = account.Id;

        string value = 'Test';
        Account acc = new Account( Name='Test1');

        recName=acc.Name;

        sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;

        System.runAs(adminUser) { //  RJN Add 9112
            LookupSearchComponentController.SObJectResult Test = new LookupSearchComponentController.SObJectResult('test', recId);
            LookupSearchComponentController controller = new LookupSearchComponentController();
        }
    }
    /**
     * RJN 9/12 rewrote to avoid using hardcoded ids.. (old version at bottom of this class.
     */
    @IsTest
    static void test_getResults_Positive(){
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        String testAccountName = ACCOUNT_NAME +'%';
        List<Account> dbAccounts = [SELECT Id, Name FROM Account WHERE Name LIKE  :testAccountName ];
        Account acc = new Account(Name='Test Account not found in search');
        insert acc;

        System.runAs(adminUser) {
            Test.startTest();

            List<LookupSearchComponentController.SObJectResult> results = LookupSearchComponentController.getResults(KNOWN_SOBJECT_API_NAME,
                                                                                                            'Name',ACCOUNT_NAME);
            //  Test that are result size is the same as the amount of test accounts created with the prefix of ACCOUNT_NAME
            System.assertEquals(results.size(),dbAccounts.size());
            for(LookupSearchComponentController.SObJectResult res : results) {
                System.assert(res.recName != acc.Name); //  Ensure we don't get the wrong account in the search results.
            }

            Test.stopTest();
        }
    }
   /**
    * RJN 9/12 rewrote to avoid using hardcoded ids.. (old version at bottom of this class.
    */
    @IsTest
    static void test_getResults_Negative_NoData(){
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        String testAccountName = 'Bogus wont be found';

        System.runAs(adminUser) {
            Test.startTest();

            List<LookupSearchComponentController.SObJectResult> results =
                    LookupSearchComponentController.getResults(KNOWN_SOBJECT_API_NAME, 'Name',testAccountName);
            //  Test that we get an empty list back for a bad search term
            System.assert(results.isEmpty());
            Test.stopTest();
        }
    }
}

//    @isTest static void testfetchValues(){  RJN Rewritten 9/12
//
//        Id recId = '0011I00000uPuwMQAS';
//        List< Account> Name1 = [Select Name from Account];
//
//        List<Account> Thing = [Select Name From Account];
//
//        For(account t : Thing){
//
//            t.Name = 'Test'+1;
//        }
//
//        insert Thing;
//
//        Account Fox = new Account(Name ='Fox Bar');
//
//        insert Fox;
//
//        Id  Ids = '0011I00000uPuwMQAS';
//
//        /*map<Id, String>(sObject);*/
//        Sobject so;
//
//        LookupSearchComponentController.SObJectResult Test= new LookupSearchComponentController.SObJectResult(Fox.Name, Fox.Id);
//
//        List<Test> Tests;
//
//        //       LookupSearchComponentController.getResults(ObjectName, fieldName, value)
//
//        List<LookupSearchComponentController.SObJectResult> Results =  LookupSearchComponentController.getResults('Account', 'Name', Fox.Name);
//
//
//
//        String fieldvalue = (string)so.get('Name');
//        Results.add( new LookupSearchComponentController.SObJectResult(fieldvalue, so.Id));
//        For(LookupSearchComponentController.SObJectResult f: Results){
//            // String fieldvalue = (String)f.get('Name');
//            //
//            LookupSearchComponentController.SObJectResult Test1= new LookupSearchComponentController.SObJectResult(Fox.Name, Fox.Id);
//            f = Test;
//            //    Results.add( new LookupSearchComponentController.SObJectResult('test'+1, recId));
//
//
//
//        }
//        Results.add(new LookupSearchComponentController.SObJectResult(Fox.Name, Fox.Id));
//
//        /*  String fieldvalue = (String)Results[0].get('Name');
//  sObjectResultList.add(new SObjectResult(fieldvalue, so.Id));*/
//
//    }