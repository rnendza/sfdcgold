@IsTest
private class FslApiControllerTest {


    @IsTest
    static void test_retrieveScheduledJobInfo() {

        List<String> jobStatuses = new List<String>{'queued'};
        List<String> jobNames = new List<String>{'Integrity Checker','Optimization','SLR Purge#FSL#'};

        Test.startTest();

        ResponseDto dto = FslApiController.retrieveScheduledJobInfo(jobNames,jobStatuses);
        System.assert(dto.isSuccess);
        List<FslApiController.JobWrapper> jobWrappers = (List<FslApiController.JobWrapper>)dto.values.get(FslApiController.MAP_KEY_APEX_JOBS);
        for(FslApiController.JobWrapper jobWrapper : jobWrappers) {
            System.assert(jobNames.contains(jobWrapper.jobName));
        }

        Test.stopTest();
    }
}