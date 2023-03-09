@IsTest
private class AppLogControllerTest {


    @IsTest
    static void test_retrieveScheduledJobInfo() {

        List<String> jobStatuses = new List<String>{'queued'};
        List<String> apexClassNames = new List<String>{'BatchPruneAccelLogs'};

        Test.startTest();

        ResponseDto dto = AppLogController.retrieveScheduledJobInfo(apexClassNames,jobStatuses);
        System.assert(dto.isSuccess);
        List<AppLogController.JobWrapper> jobWrappers = (List<AppLogController.JobWrapper>)dto.values.get(AppLogController.MAP_KEY_APEX_JOBS);
        for(AppLogController.JobWrapper jobWrapper : jobWrappers) {
            System.assert(apexClassNames.contains(jobWrapper.apexClassName));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_fireJob() {


        Test.startTest();
        String cron = '0 0 07 * * ?';
        String jobName = 'App_Log_Batch_Purge';
        ResponseDto dto = AppLogController.fireJob(cron,jobName);
        System.debug('--> dto='+dto);
        Id jobId = (Id)dto.values.get(AppLogController.MAP_KEY_JOB_FIRE_STATUS);
        System.debug('--> jobId = '+jobId);
        System.assert(dto.isSuccess);
        System.assert(jobId != null);
        Test.stopTest();
    }
    
    @IsTest
    static void test_AbortPaImportJob() {

        String cron = '0 0 07 * * ?';
        String jobName = 'App_Log_Batch_Purge';
        ResponseDto dto = AppLogController.fireJob(cron,jobName);

        Test.startTest();

        dto = AppLogController.abortJob(jobName);
        List<Id> jobIds = (List<Id>)dto.values.get(AppLogController.MAP_KEY_JOB_ABORT_IDS);
        System.assert(dto.isSuccess);
        System.assert(jobIds != null && !jobIds.isEmpty());


        Test.stopTest();
    }
}