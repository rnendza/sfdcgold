@IsTest
private class clScheduleMaintControllerTest {
    @TestSetup
    static void setupData() {

    }
    @IsTest
    static void test_retrieveScheduledJobInfo() {

        List<String> jobStatuses = new List<String>{
                'queued'
        };
        List<String> apexClassNames = new List<String>{
                'blah'
        };

        Test.startTest();
        ResponseDto dto = clScheduleMaintController.retrieveScheduledJobInfo(apexClassNames, jobStatuses);
        System.debug('--->dtorick=' + dto);
        Test.stopTest();
    }

    @IsTest
    static void test_fireAllJobs() {

        Test.startTest();
        ResponseDto dto = clScheduleMaintController.fireAllJobs();
        Test.stopTest();
    }

    @IsTest
    static void test_abortAllJobs() {
        clScheduleMaintController.fireAllJobs();
        Test.startTest();
        ResponseDto dto = clScheduleMaintController.abortAllJobs();
        Test.stopTest();
    }
}