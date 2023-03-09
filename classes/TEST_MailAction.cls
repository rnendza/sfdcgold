@isTest
private class TEST_MailAction{
    public static String UNAME = 'acceltest@accel.com';
    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        List<Municipality__c> munis = TestUtils.createMunicipalities('Test Accel Muni',2);
        List<Account> newAccounts = new List<Account>();
        for(Municipality__c muni : munis) {
            Account acct = TestUtils.buildAccount('test',muni.id);
            acct.relationship_manager__c = u.id;
            newAccounts.add(acct);
        }
        insert newAccounts;

    }
    /**
     *
     */
    @isTest static void testBlah() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();

            Map<Id,Municipality__c> munis =  new Map<Id,Municipality__c>([select id from municipality__c]);
            List<Id> muniIds = new List<Id>();
            muniIds.addAll(munis.keySet());
            MailAction.sendMuniEmails(muniIds);
            MailAction.EmailActionResult ear = new MailAction.EmailActionResult();
            Boolean success = ear.isSuccess;
            String em = ear.errorMessage;





            Test.stopTest();
        }
    }
}