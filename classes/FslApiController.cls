/**
 * Ui-focused all things FSL Api.
 */
public class FslApiController {

    public static String                MAP_KEY_APEX_JOBS               = 'APEX_JOBS';

    /**
     * @param jobNames      Name(s) of CronTrigger.CronJobDetail.Name ie ['Integrity Checker','Optimization','|SLR Purge#FSL#']
     * @param jobStatuses   Status(es) of AsyncApexJob.Status ie ['queued']
     *
     * @return  A List of JobWrappers played in the values map of a ResponseDto Object.
     */
    @AuraEnabled
    public static ResponseDto retrieveScheduledJobInfo(List<String> jobNames,List<String> jobStatuses) {
        ResponseDto dto = new ResponseDto();

        List<AsyncApexJob> jobs = retrieveJobInfo(jobStatuses,jobNames);
        if(Test.isRunningTest()) {
            jobs = (List<AsyncApexJob>)JSON.deserialize(unitTestJobsJson,List<AsyncApexJob>.class);
        }
        List<JobWrapper> jobWrappers = buildJobWrappers(jobs);
        dto.isSuccess = !jobWrappers.isEmpty();
        dto.values.put(MAP_KEY_APEX_JOBS,jobWrappers);
        return dto;
    }

    /**
     * @param jobStatuses  Status(es) of AsyncApexJob.Status ie ['queued']
     * @param jobNames     Name(s) of CronTrigger.CronJobDetail.Name ie ['Integrity Checker','Optimization','|SLR Purge#FSL#']
     *
     * @return          A List of AsyncApexJob sObjects.
     */
    public static List<AsyncApexJob> retrieveJobInfo(List<String> jobStatuses, List<String> jobNames) {

        List<AsyncApexJob> jobs = [
                SELECT  Id, CronTriggerId, ApexClass.Name, CronTrigger.CronJobDetail.Name, CronTrigger.NextFireTime, Status,
                        CronTrigger.StartTime,CronTrigger.State,CronTrigger.CronExpression,CronTrigger.LastModifiedBy.Name,
                        CronTrigger.CreatedDate
                FROM    AsyncApexJob
                WHERE   Status          IN :jobStatuses
                AND     CronTrigger.CronJobDetail.Name  IN :jobNames
        ];
        return jobs;
    }

    /**
     * @param apexJobs  A List of AsyncApexJob sObjects.
     * @return          A List of JobWrapper objects.
     */
    private static List<JobWrapper> buildJobWrappers(List<AsyncApexJob> apexJobs) {
        List<JobWrapper> jobWrappers = new List<JobWrapper>();
        for(AsyncApexJob apexJob : apexJobs) {
            jobWrappers.add(new JobWrapper(apexJob));
        }
        return jobWrappers;
    }

    /**
     * Wraps AsyncApexJob
     */
    public class JobWrapper {

        @AuraEnabled public Id cronTriggerId;
        @AuraEnabled public String apexClassName;
        @AuraEnabled public String jobName;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime nextFireTime;
        @AuraEnabled public Datetime startTime;
        @AuraEnabled public String state;
        @AuraEnabled public String cronExpression;
        @AuraEnabled public String cronLastModBy;
        @AuraEnabled public Datetime cronCreatedDate;

        public JobWrapper(AsyncApexJob apexJob) {
            this.cronTriggerId = apexJob.CronTriggerId;
            this.apexClassName = apexJob.ApexClass.Name;
            this.jobName = apexJob.CronTrigger.CronJobDetail.Name;
            this.status = apexJob.Status;
            this.nextFireTime = apexJob.CronTrigger.NextFireTime;
            this.cronExpression = apexJob.CronTrigger.CronExpression;
            this.cronLastModBy = apexJob.CronTrigger.LastModifiedBy.Name;
            this.cronCreatedDate = apexJob.CronTrigger.CreatedDate;
            this.startTime = apexJob.CronTrigger.StartTime;
            this.state = apexJob.CronTrigger.State;

        }
    }
    //      Sample for Apex Unit Test
    private static String unitTestJobsJson = '[{"attributes":{"type":"AsyncApexJob","url":"/services/data/v56.0/sobjects/AsyncApexJob/7071I000022yUjtQAE"},"Id":"7071I000022yUjtQAE","CronTriggerId":"08e1I00000Q4xTUQAZ","ApexClassId":"01p1I00000GmxopQAB","Status":"Queued","ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v56.0/sobjects/ApexClass/01p1I00000GmxopQAB"},"Id":"01p1I00000GmxopQAB","Name":"Sched009_STMIntegrityChecker","Body":"(hidden)"},"CronTrigger":{"attributes":{"type":"CronTrigger","url":"/services/data/v56.0/sobjects/CronTrigger/08e1I00000Q4xTUQAZ"},"Id":"08e1I00000Q4xTUQAZ","CronJobDetailId":"08a1I00000PPkhHQAT","NextFireTime":"2022-12-18T06:00:00.000+0000","StartTime":"2018-07-25T23:00:10.000+0000","State":"WAITING","CronJobDetail":{"attributes":{"type":"CronJobDetail","url":"/services/data/v56.0/sobjects/CronJobDetail/08a1I00000PPkhHQAT"},"Id":"08a1I00000PPkhHQAT","Name":"Integrity Checker"}}},{"attributes":{"type":"AsyncApexJob","url":"/services/data/v56.0/sobjects/AsyncApexJob/7071I000022yUfEQAU"},"Id":"7071I000022yUfEQAU","CronTriggerId":"08e1I00000Q4xVPQAZ","ApexClassId":"01p1I00000GmxohQAB","Status":"Queued","ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v56.0/sobjects/ApexClass/01p1I00000GmxohQAB"},"Id":"01p1I00000GmxohQAB","Name":"Sched004_OAAS","Body":"(hidden)"},"CronTrigger":{"attributes":{"type":"CronTrigger","url":"/services/data/v56.0/sobjects/CronTrigger/08e1I00000Q4xVPQAZ"},"Id":"08e1I00000Q4xVPQAZ","CronJobDetailId":"08a1I00000PPkjCQAT","NextFireTime":"2022-12-18T06:00:00.000+0000","StartTime":"2018-07-25T23:01:34.000+0000","State":"WAITING","CronJobDetail":{"attributes":{"type":"CronJobDetail","url":"/services/data/v56.0/sobjects/CronJobDetail/08a1I00000PPkjCQAT"},"Id":"08a1I00000PPkjCQAT","Name":"Optimization"}}},{"attributes":{"type":"AsyncApexJob","url":"/services/data/v56.0/sobjects/AsyncApexJob/7078W0000MIPAIBQQ5"},"Id":"7078W0000MIPAIBQQ5","CronTriggerId":"08e8W00004SHIwLQAX","ApexClassId":"01p1I00000GmxoiQAB","Status":"Queued","ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v56.0/sobjects/ApexClass/01p1I00000GmxoiQAB"},"Id":"01p1I00000GmxoiQAB","Name":"Sched006_SLRPurge","Body":"(hidden)"},"CronTrigger":{"attributes":{"type":"CronTrigger","url":"/services/data/v56.0/sobjects/CronTrigger/08e8W00004SHIwLQAX"},"Id":"08e8W00004SHIwLQAX","CronJobDetailId":"08a8W00004Rs8FRQAZ","NextFireTime":"2022-12-18T06:00:00.000+0000","StartTime":"2022-10-13T13:37:48.000+0000","State":"WAITING","CronJobDetail":{"attributes":{"type":"CronJobDetail","url":"/services/data/v56.0/sobjects/CronJobDetail/08a8W00004Rs8FRQAZ"},"Id":"08a8W00004Rs8FRQAZ","Name":"SLR Purge#FSL#"}}}]';
}