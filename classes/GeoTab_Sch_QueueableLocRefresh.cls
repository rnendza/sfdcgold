/**
 * Note.. this reschedules a new instance of itself into the future (pIntervalMinutes)
 * and then aborts the currently scheduled instance.
 *
 * The reason is to avoid taking up multiple apex job slots (there is a limit) This is done
 * because this job will run on a very frequent basis.
 *
 * A sample call to fire off almost immediately (1 minute from now)
 *
 * String JOB_NAME          = GeoTab_Sch_QueueableLocRefresh.JOB_NAME;
 * Integer intervalMinutes  = 1;
 * DateTime dtNow           = DateTime.now();
 *
 * GeoTab_Sch_QueueableLocRefresh schJob = new GeoTab_Sch_QueueableLocRefresh(intervalMinutes);
 *
 * String cronString = '' + dtNow.second()+' '+dtNow.addMinutes(1).minute()+' '+ dtNow.hour()+' '+dtNow.day()+' '+
 *       dtNow.month()+' ? '+dtNow.year();
 *
 * System.schedule(JOB_NAME + '-' + dtNow.format(), cronString, new GeoTab_Sch_QueueableLocRefresh(intervalMinutes));
 *
 */
global class GeoTab_Sch_QueueableLocRefresh implements Schedulable {

    public static final String JOB_NAME = 'GeoTab_Gps_Location_Update_(Every_Minute)';
    Integer intervalMinutes = 1;

    /**
     * @param pIntervalMinutes  The interval this job should run.
     */
    public GeoTab_Sch_QueueableLocRefresh(Integer pIntervalMinutes) {
        this.intervalMinutes = pIntervalMinutes;
    }

    /**
     * @param ctx  The context.
     */
    global void execute(SchedulableContext ctx) {

        DateTime dtNow = DateTime.now();
        DateTime dtNextRun = dtNow.addMinutes(intervalMinutes);

        String cronString = '' + dtNextRun.second() + ' ' + dtNextRun.minute() + ' ' + dtNextRun.hour() + ' ' + dtNextRun.day() + ' ' +
                dtNextRun.month() + ' ? ' + dtNextRun.year();

        System.schedule(JOB_NAME + '-' + dtNow.format() + '' + dtNow.second(), cronString, new GeoTab_Sch_QueueableLocRefresh(intervalMinutes));
        Id jobId = ctx.getTriggerId();
        System.abortJob(jobId);
        GeoTabQueueableLocRefresh q = new GeoTabQueueableLocRefresh();
        System.enqueueJob(q);
    }

    global Set<Id> abortAll() {
        Set<Id> jobsIdsAborted = new Set<Id>();
        List<AsyncApexJob> jobs = [
                SELECT  ApexClass.Name,CreatedDate,Id,JobType,Status,CronTriggerId
                FROM    AsyncApexJob
                WHERE   Status = 'Queued'
                AND     ApexClass.Name = 'GeoTab_Sch_QueueableLocRefresh'
        ];
        if(!jobs.isEmpty()) {
            for(AsyncApexJob job : jobs) {
                Id jobId = job.CronTriggerId;
                System.abortJob(jobId);
                jobsIdsAborted.add(jobId);
            }
        }
        return jobsIdsAborted;
    }
}