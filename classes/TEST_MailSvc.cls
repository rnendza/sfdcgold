@isTest
private class TEST_MailSvc {
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
    @isTest static void testSendCustomMailTemplateNoTemplateExists() {
        system.assert(!MailSvc.sendCustomMailTemplates(null,null,null,null));
    }
    @isTest static void testSendCustomMailTemplate() {

        User u = TestUtils.getUserForTest(UNAME);
        Municipality__c muni = [select id from Municipality__c limit 1];

        System.runAs(u) {
            Test.startTest();
            EmailTemplate emailTemplate = TestUtils.buildEmailTemplate('UTtemplateName','UTTemplateDevName', 'text', u.id,'templateSubject');
            insert emailTemplate;
            Contact c = new Contact(lastName='test',email='blah@gmail.com');
            insert c;//have to send to a contact as opposed to a user in UT code. another retarded SFDC issues that has been out there for years!
            Boolean success =  MailSvc.sendCustomMailTemplates(muni.id, new Set<Id>{c.id}, 'UtTemplateDevName', '');
            system.assert(success);
            //--- the below will fail but is actually what the code does (and works)
            success =  MailSvc.sendCustomMailTemplates(muni.id, new Set<Id>{u.id}, 'UtTemplateDevName', '');
            system.assert(!success);
            Test.stopTest();
        }
    }

}