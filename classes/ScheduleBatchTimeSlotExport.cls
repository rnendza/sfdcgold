global class ScheduleBatchTimeSlotExport implements Schedulable {

    public static final String JOBNAME = 'Accel_Schedule_Batch_TimeSlot_Export';

    global void execute(SchedulableContext ctx) {
        BatchTimeSlotExport b = new BatchTimeSlotExport();
        Database.executeBatch(b);
    }
    /**
     * @param runTime  - the datetime this should be scheduled to run.
     */
    public static void scheduleIt(Datetime runTime) {
        unscheduleIt();
        runtime = (runtime != null) ? runtime : System.now().addMinutes(15);
        if (runtime >= System.now()) {
            DateTime next = runtime;
            String cron = next.second() + ' ' + next.minute() + ' ' + next.hour() + ' ' +
                    next.day() + ' ' + next.month() + ' ? ' + next.year();
            Id jobId = System.schedule(JOBNAME, cron, new ScheduleBatchTimeSlotExport());
        }
    }

    public static void unscheduleIt() {
        for (CronTrigger ct : [select Id from CronTrigger where CronJobDetail.Name like :(JOBNAME + '%')]) {
            System.abortJob(ct.Id);
        }
    }
}