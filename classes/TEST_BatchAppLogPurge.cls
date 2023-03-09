@isTest
private class TEST_BatchAppLogPurge {
    
    public static String uName = 'acceltest@accel.com';
    public static Batch_Job_Setting__mdt setting =
        BatchjobSvc.queryForMetadata('App_Log_Batch_Purge');

    @isTest
    static void appLogTest() {
        User u = TestUtils.getUserForTest(uName);
        System.runAs(u) {

            DateTime testDate = Datetime.now().addDays(-32);

            Accel_Application_Error__c log = BatchjobSvc.buildlog('App_Log_Batch_Purge');
            insert log;
            log = AppLogSvc.retrieveLog(log.Id);
            Test.setCreatedDate(log.Id, testDate);

            Test.startTest();
                Sch_BatchAppLogPurge schJob = new Sch_BatchAppLogPurge();
                String cron = '0 0 23 * * ?';
                system.schedule( setting.DeveloperName, cron, schJob);
            Test.stopTest();

        }
    }


}