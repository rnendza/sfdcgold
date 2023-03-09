/**
 * Ui-focused all things App Logs
 */
public class AppLogController {

    public static final String MAP_KEY_APEX_JOBS                        = 'APEX_JOBS';
    public static final String MAP_KEY_JOB_FIRE_STATUS                  = 'JOB_FIRE_STATUS';
    public static final String MAP_KEY_JOB_ABORT_IDS                    = 'MAP_KEY_JOB_ABORT_IDS';

    @AuraEnabled
    public static ResponseDto fireJob(String cron, String jobName) {
        Sch_BatchAppLogPurge schJob = new Sch_BatchAppLogPurge();
        //String cron = '0 0 07 * * ?';
        jobName = Test.isRunningTest() ? jobName + ' Test' : jobName;
        Id jobId = System.schedule(jobName, cron, schJob);
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_JOB_FIRE_STATUS,jobId);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto abortJob(String jobName) {
        ResponseDto dto = new ResponseDto();
        List<Id> jobIds = findAllJobs(jobName);
        if(!jobIds.isEmpty()) {
            for(Id jobId : jobIds) {
                System.abortJob(jobId);
            }
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_JOB_ABORT_IDS,jobIds);
        return dto;
    }

    public static List<Id> findAllJobs(String jobName) {
        List<Id> jobIds = new List<Id>();
        jobName = Test.isRunningTest() ? jobName + ' TEST' : jobName;
        List<CronTrigger> cts = [
                SELECT Id,CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
                AND State = 'Waiting'
        ];

        if(!cts.isEmpty()) {
            for(CronTrigger ct : cts) {
                jobIds.add(ct.Id);
            }
        }
        return jobIds;
    }


    /**
     * @param apexClassNames Name(s) of Apexclass.Name
     * @param jobStatuses   Status(es) of AsyncApexJob.Status ie ['queued']
     *
     * @return  A List of JobWrappers played in the values map of a ResponseDto Object.
     */
    @AuraEnabled
    public static ResponseDto retrieveScheduledJobInfo(List<String> apexClassNames,List<String> jobStatuses) {
        ResponseDto dto = new ResponseDto();

        List<AsyncApexJob> jobs = retrieveJobInfo(apexClassNames,jobStatuses);
        if(Test.isRunningTest()) {
            jobs = (List<AsyncApexJob>)JSON.deserialize(unitTestJobsJson,List<AsyncApexJob>.class);
        }
        List<JobWrapper> jobWrappers = buildJobWrappers(jobs);
        dto.isSuccess = !jobWrappers.isEmpty();
        dto.values.put(MAP_KEY_APEX_JOBS,jobWrappers);
        return dto;
    }

    /**
     * @param apexClassNames Name(s) of Apexclass.Name
     * @param jobStatuses    Status(es) of AsyncApexJob.Status ie ['queued']
     *
     * @return          A List of AsyncApexJob sObjects.
     */
    public static List<AsyncApexJob> retrieveJobInfo(List<String> apexClassNames, List<String> jobStatuses) {

        List<AsyncApexJob> jobs = [
                SELECT  Id, CronTriggerId, ApexClass.Name, CronTrigger.CronJobDetail.Name, CronTrigger.NextFireTime, Status,
                        CronTrigger.StartTime,CronTrigger.State,CronTrigger.CronExpression,CronTrigger.LastModifiedBy.Name,
                        CronTrigger.CreatedDate
                FROM    AsyncApexJob
                WHERE   ApexClass.Name   IN :apexClassNames
                AND     Status           IN  :jobStatuses
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
    //      Sample for Apex Unit Test (not 100pct accurate as cut and pasted but doesn't matter
    private static String unitTestJobsJson = '[\n' +
            '  {\n' +
            '    "attributes": {\n' +
            '      "type": "AsyncApexJob",\n' +
            '      "url": "/services/data/v56.0/sobjects/AsyncApexJob/7071I000022yUjtQAE"\n' +
            '    },\n' +
            '    "Id": "7071I000022yUjtQAE",\n' +
            '    "CronTriggerId": "08e1I00000Q4xTUQAZ",\n' +
            '    "ApexClassId": "01p1I00000GmxopQAB",\n' +
            '    "Status": "Queued",\n' +
            '    "ApexClass": {\n' +
            '      "attributes": {\n' +
            '        "type": "ApexClass",\n' +
            '        "url": "/services/data/v56.0/sobjects/ApexClass/01p1I00000GmxopQAB"\n' +
            '      },\n' +
            '      "Id": "01p1I00000GmxopQAB",\n' +
            '      "Name": "BatchPruneAccelLogs",\n' +
            '      "Body": "(hidden)"\n' +
            '    },\n' +
            '    "CronTrigger": {\n' +
            '      "attributes": {\n' +
            '        "type": "CronTrigger",\n' +
            '        "url": "/services/data/v56.0/sobjects/CronTrigger/08e1I00000Q4xTUQAZ"\n' +
            '      },\n' +
            '      "Id": "08e1I00000Q4xTUQAZ",\n' +
            '      "CronJobDetailId": "08a1I00000PPkhHQAT",\n' +
            '      "NextFireTime": "2022-12-18T06:00:00.000+0000",\n' +
            '      "StartTime": "2018-07-25T23:00:10.000+0000",\n' +
            '      "State": "WAITING",\n' +
            '      "CronJobDetail": {\n' +
            '        "attributes": {\n' +
            '          "type": "CronJobDetail",\n' +
            '          "url": "/services/data/v56.0/sobjects/CronJobDetail/08a1I00000PPkhHQAT"\n' +
            '        },\n' +
            '        "Id": "08a1I00000PPkhHQAT",\n' +
            '        "Name": "App_Log_Batch_Purge"\n' +
            '      }\n' +
            '    }\n' +
            '  }\n' +
            ']';


}