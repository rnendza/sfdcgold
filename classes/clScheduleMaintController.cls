public class clScheduleMaintController {

    public static final String MAP_KEY_APEX_JOBS                        = 'APEX_JOBS';
    public static final String MAP_KEY_JOB_FIRE_STATUS                  = 'JOB_FIRE_STATUS';
    public static final String MAP_KEY_JOB_ABORT_IDS                    = 'MAP_KEY_JOB_ABORT_IDS';

    @AuraEnabled
    public static ResponseDto retrieveScheduledJobInfo(List<String> apexClassNames,List<String> jobStatuses) {
        ResponseDto dto = new ResponseDto();
        List<AsyncApexJob> jobs = AsyncApexJobsSvc.retrieveJobInfo(jobStatuses,apexClassNames);
        if(Test.isRunningTest()) {
            jobs = (List<AsyncApexJob>)JSON.deserialize(unitTestJobsJson,List<AsyncApexJob>.class);
        }
        System.debug('jobs json='+JSON.serialize(jobs));
        List<JobWrapper> jobWrappers = buildJobWrappers(jobs);
        dto.isSuccess = !jobWrappers.isEmpty();
        dto.values.put(MAP_KEY_APEX_JOBS,jobWrappers);
        return dto;
    }

    private static List<JobWrapper> buildJobWrappers(List<AsyncApexJob> apexJobs) {
        List<JobWrapper> jobWrappers = new List<JobWrapper>();
        for(AsyncApexJob apexJob : apexJobs) {
            jobWrappers.add(new JobWrapper(apexJob));
        }
        return jobWrappers;
    }

    @AuraEnabled
    public static ResponseDto fireAllJobs() {
        List<Id> startedJobIds = processJobs(false);
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_JOB_FIRE_STATUS,startedJobIds);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto abortAllJobs() {
        List<Id> abortedJobIds = processJobs(true);
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_JOB_ABORT_IDS,abortedJobIds);
        return dto;
    }

    private static List<Id> processJobs(Boolean abort) {

        List<Id> processJobsIds = new List<Id>();
        Job job = new Job();
        job.className = 'cl_Sch_BatchCycleNumberUpdate';
        job.jobName = 'CL - 12:15am - Daily - Cycle # Increment - Add 1';
        job.cron = '0 15 00 * * ?';

        List<Cash_Logistics_Schedule_Setting__mdt> mdts = clAutomationSvc.retrieveScheduleMetadatas(true);

        List<Job> dynaJobs = new List<Job>();

        for(Cash_Logistics_Schedule_Setting__mdt mdt : mdts) {
            Job rsJob = new Job();
            Job rpsJob = new Job();

            rsJob.region = mdt.Label;
            rsJob.cron = mdt.RS_Schedule_Time__c;
            rsJob.jobName = mdt.RS_Job_Name__c;
            rsJob.className = 'cl_Sch_BatchRouteScheduleCreation';

            rpsJob.region = mdt.Label;
            rpsJob.cron = mdt.RPS_Schedule_Time__c;
            rpsJob.jobName = mdt.RPS_Job_Name__c;
            rpsJob.className = 'cl_Sch_BatchRouteProcessingSheetCreation';

            dynaJobs.add(rpsJob);
            dynaJobs.add(rsJob);
        }

        List<Job> jobs = new List<Job>{job};
        jobs.addAll(dynaJobs);
        job.jobName  = Test.isRunningTest() ? job.jobName + ' TEST' : job.jobName;
        Set<String> jobNames = new Set<String>{job.jobName};
        for(Job rpsJob : dynaJobs) {
            rpsJob.jobName = Test.isRunningTest() ? rpsJob.jobName + ' TEST' : rpsJob.jobName;
            jobNames.add(rpsJob.jobName);
        }

        List<CronTrigger> cts = [SELECT Id,CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name IN :jobNames AND State = 'Waiting'];

        if(abort) {
            for(CronTrigger ct : cts) {
                System.abortJob(ct.Id);
                processJobsIds.add(ct.Id);
                System.debug('---> aborting job '+ct.CronJobDetail.Name );
            }
            if(cts.isEmpty()) {
                System.debug('---> no jobs to abort!');
            }
        } else {
            for(Job tmpJob : jobs) {
                tmpJob.jobName = Test.isRunningTest() ? tmpJob.jobName + ' TEST' : tmpJob.jobName;
                Type batchType = Type.forName(tmpJob.className);
                Schedulable schJob = (Schedulable)batchType.newInstance();
                if(job.className == 'cl_Sch_BatchRouteProcessingSheetCreation') {
                    schJob = new cl_Sch_BatchRouteProcessingSheetCreation(tmpJob.region);
                } else if (job.className == 'cl_Sch_BatchRouteScheduleCreation') {
                    schJob = new cl_Sch_BatchRouteScheduleCreation(tmpJob.region);
                }
                Id jobId = System.schedule(tmpJob.jobName,tmpJob.cron,schJob);
                System.debug('---> scheduling job '+tmpJob.jobName);
                processJobsIds.add(jobId);
            }
        }
        return processJobsIds;
    }

    public class JobWrapper {

        @AuraEnabled public Id cronTriggerId;
        @AuraEnabled public String apexClassName;
        @AuraEnabled public String jobName;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime nextFireTime;
        @AuraEnabled public Datetime startTime;
        @AuraEnabled public String state;

        public JobWrapper(AsyncApexJob apexJob) {
            this.cronTriggerId = apexJob.CronTriggerId;
            this.apexClassName = apexJob.ApexClass.Name;
            this.jobName = apexJob.CronTrigger.CronJobDetail.Name;
            this.status = apexJob.Status;
            this.nextFireTime = apexJob.CronTrigger.NextFireTime;
            this.startTime = apexJob.CronTrigger.StartTime;
            this.state = apexJob.CronTrigger.State;
        }
    }

    class Job {
        String jobName;
        String cron;
        String className;
        String region;
        public Job() {

        }
    }
    private static String unitTestJobsJson = '[{"attributes":{"type":"AsyncApexJob","url":"/services/data/v55.0/sobjects/AsyncApexJob/7075300000mC1rbAAC"},"Id":"7075300000mC1rbAAC","CronTriggerId":"08e53000008UWGeAAO","ApexClassId":"01p8W00000ITfRoQAL","Status":"Queued","ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v55.0/sobjects/ApexClass/01p8W00000ITfRoQAL"},"Id":"01p8W00000ITfRoQAL","Name":"GeoTab_Sch_QueueableLocRefresh"},"CronTrigger":{"attributes":{"type":"CronTrigger","url":"/services/data/v55.0/sobjects/CronTrigger/08e53000008UWGeAAO"},"Id":"08e53000008UWGeAAO","CronJobDetailId":"08a53000008UY15AAG","NextFireTime":"2022-09-09T12:59:24.000+0000","StartTime":"2022-09-09T12:58:24.000+0000","CronJobDetail":{"attributes":{"type":"CronJobDetail","url":"/services/data/v55.0/sobjects/CronJobDetail/08a53000008UY15AAG"},"Id":"08a53000008UY15AAG","Name":"GeoTab_Gps_Location_Update_(Every_Minute)-9/9/2022 7:58 AM24"}}}]';
}