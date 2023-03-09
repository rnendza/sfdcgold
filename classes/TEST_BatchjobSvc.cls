@IsTest
private class TEST_BatchjobSvc {

    public static String USERNAME_ADMIN = 'acceladmintest@accel.com';

    @isTest
    static void test_findQueryLocatorSize() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Integer iNumRecords = 5;

        List<Municipality__c> munis = TestUtils.createMunicipalities('TEST Muni', iNumRecords);
        Database.QueryLocator ql = Database.getQueryLocator([SELECT Id FROM Municipality__c]);

        System.runAs(adminUser) {
            Test.startTest();
            System.assertEquals(iNumRecords,BatchjobSvc.findQueryLocatorSize(ql));
            Test.stopTest();
        }
    }

    @isTest
    static void test_queryFoMetadata_positive() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            System.assertNotEquals(null, BatchjobSvc.queryForMetadata(BatchSample.jobName));
            Test.stopTest();
        }
    }

    @isTest
    static void test_queryFoMetadata_notfound() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            System.assertEquals(null, BatchjobSvc.queryForMetadata('bogus_mdt_dev_name'));
            Test.stopTest();
        }
    }

    @isTest
    static void test_sendemail_positive() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Accel_Application_Error__c log = BatchjobSvc.buildLog(BatchSweepstakesLocUpdate.jobName);
            insert log;
            log = AppLogSvc.retrieveLog(log.Id);

            List<Messaging.SendEmailResult> sendResults_defaults = BatchjobSvc.sendEmail(log);
            List<Messaging.SendEmailResult> sendResults_template =
                    BatchjobSvc.sendEmail(log,new Set<Id>{UserInfo.getUserId()},BatchjobSvc.DEFAULT_EMAIL_TEMPLATE);

            Test.stopTest();
        }
    }

    @isTest
    static void test_sendemail_dynaHtml_positive() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Accel_Application_Error__c log = BatchjobSvc.buildLog(BatchSweepstakesLocUpdate.jobName);
            insert log;
            log = AppLogSvc.retrieveLog(log.Id);

            EmailTemplate t = [ SELECT Id FROM EmailTemplate WHERE DeveloperName = :BatchjobSvc.DEFAULT_EMAIL_TEMPLATE];
            String dynaHtml = '<b>TEST DYNA HTML</b>';

            List<Messaging.SendEmailResult> sendResults_template =
                    BatchjobSvc.sendEmail(log,new Set<Id>{UserInfo.getUserId()},t.Id,dynaHtml);

            Test.stopTest();
        }
    }

    @isTest
    static void test_sendemailtemplates_dynaHtml_positive() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            List<Accel_Application_Error__c> logs = new List<Accel_Application_Error__c>();
            for(Integer i=0;i<20;i++) {
                logs.add( BatchjobSvc.buildLog(BatchSweepstakesLocUpdate.jobName));
            }
            insert logs;

            EmailTemplate t = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :BatchjobSvc.DEFAULT_EMAIL_TEMPLATE];
            Set<Id> whoIds = new Set<Id> {UserInfo.getUserId()};

            List<BatchjobSvc.BatchEmailData> datas = new List<BatchjobSvc.BatchEmailData>();

            for(Accel_Application_Error__c log : logs) {
                BatchJobSvc.BatchEmailData data = new BatchJobSvc.BatchEmailData();
                data.whoIds = whoIds;
                data.log = log;
                data.dynamicHtml = '<b>TEST DYNA HTML</b>';
                data.templateId = t.id;
                datas.add(data);
            }

            Test.startTest();
            List<Messaging.SendEmailResult> sendEmailTemplatesResults = BatchJobSvc.sendEmailTemplates(datas);
            Test.stopTest();
        }
    }
}