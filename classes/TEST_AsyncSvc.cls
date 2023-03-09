@IsTest
private class TEST_AsyncSvc {
    public static String UNAME = 'acceltest@accel.com';

    @IsTest
    static void test_insertAsyncJob() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            //  (1)
            Async_Job__c job = AsyncSvc.insertAsyncJob('fakesfdcid','blahjobname','DONE');
            System.assert(job.Id != null);
            System.assert(job.Overall_Job_Status__c == 'DONE');

            AsyncSvc.insertAsyncJob('fakesfdcid','blahjobname','DONE','classname','DONE');


            AsyncSvc.insertAsyncJob('fakesfdcid','blahjobname','DONE','classname','DONE','details','DONE',true);

            //  (2) GO BOOM
            job = AsyncSvc.insertAsyncJob('fakesfdcidmuchtoolongforanid','blahjobname','DONE');
            System.assert(job.Id == null);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveAsyncJob() {
        User u = TestUtils.getUserForTest(UNAME);

        Async_Job__c testJob = AsyncSvc.insertAsyncJob('fakesfdcid','blahjobname','DONE');

        System.runAs(u) {
            Test.startTest();

            Async_Job__c job = AsyncSvc.retrieveAsyncJob(testJob.Name);
            System.assert(job.Id == testJob.Id);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveInitiatingJob() {
        User u = TestUtils.getUserForTest(UNAME);

        Async_Job__c testJob = AsyncSvc.insertAsyncJob('fakesfdcid','blahjobname','DONE');

        System.runAs(u) {
            Test.startTest();

            Async_Job__c job = AsyncSvc.retrieveInitiatingAsyncJob(testJob.Name);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_updateJobStatus_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        List<Schema.PicklistEntry> plEntries = Async_Job__c.Parent_Job_Status__c.getDescribe().getPicklistValues();
        Async_Job__c testJob = AsyncSvc.insertAsyncJob('fakesfdcid','blahjobname',plEntries[0].value);

        System.runAs(u) {
            Test.startTest();

            Async_Job__c job = AsyncSvc.updateJobStatus(testJob.Name,plEntries[1].value);
            System.assert(job.Parent_Job_Status__c == plEntries[1].value);

            job = AsyncSvc.updateJobStatus(testJob.Name,'Completed');




            Test.stopTest();
        }
    }
    @IsTest
    static void test_updateJobStatus_Negative() {
        User u = TestUtils.getUserForTest(UNAME);

        Async_Job__c testJob = AsyncSvc.insertAsyncJob('fakesfdcid','blahjobname','DONE');

        System.runAs(u) {
            Test.startTest();

            Async_Job__c job = AsyncSvc.updateJobStatus(testJob.Name,'Restriced pl val fail');
            System.assert(job == null);

            Test.stopTest();
        }
    }

}