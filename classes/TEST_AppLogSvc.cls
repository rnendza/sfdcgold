@IsTest
private class TEST_AppLogSvc {

    public static String USERNAME_ADMIN = 'acceladmintest@accel.com';

    @isTest
    static void test_buildLog() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            String jobName = 'testjobname';
            Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);
            System.assert(log.Job_Name__c == jobName);
        }
    }


    @isTest
    static void test_updateLog() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            String jobName = 'testjobname';
            Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);
            insert log;

            log.Execution_Details__c = 'test update';
            AppLogSvc.updateLog(log);

            String value = '';
            for(Integer i=0; i < AppLogSvc.FIELD_SIZE_EXEC_DETAILS + 10; i++) {
                value+=i;
            }

            log.Execution_Details__c = value;
            log = AppLogSvc.updateLog(log);
            System.debug('---> log='+log);
            System.assertEquals(log.Execution_Details__c.length(),AppLogSvc.FIELD_SIZE_EXEC_DETAILS);
        }
    }

    @isTest
    static void test_retrieveLog_positive() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            String jobName = 'testjobname';
            Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);
            insert log;
            System.assertEquals(log.Id, AppLogSvc.retrieveLog(log.Id).Id);
            Test.stopTest();
        }
    }

    @isTest
    static void test_retrieveLog_negative() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            System.assertEquals(null, AppLogSvc.retrieveLog(null));
            Test.stopTest();
        }
    }

}