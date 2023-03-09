/**
 *  Schedule
 */
global class ScheduleBatchHpdTotals implements Schedulable {

    public static final String JOBNAME = 'Accel_Schedule_Batch_Hpd_Totals';

    global void execute(SchedulableContext ctx) {
        DateTime dtTimeStarted = DateTime.now();

        BatchHpdAccountTotals b = new BatchHpdAccountTotals('Monthly',-12);
        Database.executeBatch(b, 150); //@TODO put batchsize in custom metadata type.

        String sSubject = 'SFDC Accel Scheduler - ScheduleBatchHpdTotals - executed at ' + System.URL.getSalesforceBaseUrl();

        CronTrigger ct = [
                SELECT Id, CronExpression, TimesTriggered, NextFireTime,endtime,
                        Ownerid,CronJobDetail.Name, cronjobDetail.jobType
                FROM CronTrigger
                WHERE Id = :ctx.getTriggerId()
        ];
        if (ct != null && ct.cronjobdetail.name != null) {
            sSubject += ' - ' + ct.cronjobdetail.name;
            String msg = '';
            msg += '<br/><b>Base URL:</b>' + System.URL.getSalesforceBaseUrl() + '<br/>';
            msg += '<b>Time Started:</b> ' + dtTimeStarted + '<br/>';
            msg += '<ul>';
            sendResultsMail(msg, sSubject);
        }
    }
    /**
     *
     * @param runTime  - the datetime this should be scheduled to run.
     */
    public static void scheduleIt(Datetime runTime) {
        unscheduleIt();
        runtime = (runtime != null) ? runtime : System.now().addMinutes(15);
        if (runtime >= System.now()) {
            DateTime next = runtime;
            String cron = next.second() + ' ' + next.minute() + ' ' + next.hour() + ' ' +
                    next.day() + ' ' + next.month() + ' ? ' + next.year();
            Id jobId = System.schedule(JOBNAME, cron, new ScheduleBatchHpdTotals());
        }
    }

    public static void unscheduleIt() {
        for (CronTrigger ct : [select Id from CronTrigger where CronJobDetail.Name like :(JOBNAME + '%')]) {
            System.abortJob(ct.Id);
        }
    }
    void sendResultsMail(String msg, String sSubject) {
        // Send an email to the Apex job's submitter notifying of job completion.
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys,sSubject,body);

    }
}