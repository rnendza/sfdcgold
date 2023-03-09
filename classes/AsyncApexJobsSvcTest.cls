@IsTest
private class AsyncApexJobsSvcTest {

    /**
     * Note. hard to unit test this as SFDC will not return any results without intense mocking
     */
    @IsTest
    static void test_retrieveJobInfo() {
        List<String> jobStatuses = new List<String>{'queued'};
        List<String> apexClassNames = new List<String>{'GeoTab_Sch_QueueableLocRefresh'};

        Test.startTest();
        List<AsyncApexJob> jobs = AsyncApexJobsSvc.retrieveJobInfo(jobStatuses,apexClassNames);
        System.debug('----> jobs:'+jobs);

        Test.stopTest();
    }
}