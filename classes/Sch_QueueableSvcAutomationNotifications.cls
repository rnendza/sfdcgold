/**
 * Note.. this reschedules a new instance of itself into the future (pIntervalMinutes)
 * and then aborts the currently scheduled instance.
 *
 * The reason is to avoid taking up multiple apex job slots (there is a limit) This is done
 * because this job will run on a very frequent basis.
 *
 * A sample call to fire off almost immediately (1 minute from now)
 *
 * String JOB_NAME          = 'Accel_Schedule_Svc_Automated_Notifications';
 * Integer intervalMinutes  = 1;
 * DateTime dtNow           = DateTime.now();
 *
 * Sch_QueueableSvcAutomationNotifications schJob = new Sch_QueueableSvcAutomationNotifications(intervalMinutes);
 *
 * String cronString = '' + dtNow.second()+' '+dtNow.addMinutes(1).minute()+' '+ dtNow.hour()+' '+dtNow.day()+' '+
 *       dtNow.month()+' ? '+dtNow.year();
 *
 * System.schedule(JOB_NAME + '-' + dtNow.format(), cronString, new Sch_QueueableSvcAutomationNotifications(intervalMinutes));
 *
 */
global class Sch_QueueableSvcAutomationNotifications implements Schedulable {

    public static final String JOB_NAME = 'Accel_Schedule_Svc_Automated_Notifications';
    Integer intervalMinutes = 5;

    /**
     * @param pIntervalMinutes  The interval this job should run.
     */
    public Sch_QueueableSvcAutomationNotifications(Integer pIntervalMinutes) {
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

        System.schedule(JOB_NAME + '-' + dtNow.format() + '' + dtNow.second(), cronString, new Sch_QueueableSvcAutomationNotifications(intervalMinutes));
        Id jobId = ctx.getTriggerId();
        System.abortJob(jobId);
        QueueableSvcAutomatedNotifications q = new QueueableSvcAutomatedNotifications();
        System.enqueueJob(q);

    }
}