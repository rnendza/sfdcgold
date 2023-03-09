global class Sch_QueueableCountyUpdater implements Schedulable{

    String JOB_NAME = 'Accel_Schedule_Queueable_County_Updater_Revert';
    Integer intervalMinutes = 2;
    Integer maxAccountsToProcess;

    /**
     * @param pIntervalMinutes  The interval this job should run.
     */
    public Sch_QueueableCountyUpdater(Integer pIntervalMinutes, Integer pMaxAccountsToProcess, String jobName) {
        this.intervalMinutes = pIntervalMinutes;
        this.maxAccountsToProcess = pMaxAccountsToProcess;
        this.JOB_NAME = jobName;
    }

    /**
     * @param ctx  The context.
     */
    global void execute(SchedulableContext ctx) {

        DateTime dtNow      = DateTime.now();
        DateTime dtNextRun  = dtNow.addMinutes(intervalMinutes);
        Id triggerId        = ctx.getTriggerId();


        String cronString = '' + dtNextRun.second()+' '+dtNextRun.minute()+' '+ dtNextRun.hour()+' '+dtNextRun.day()+' '+
                dtNextRun.month()+' ? '+dtNextRun.year();

        Sch_QueueableCountyUpdater job = new Sch_QueueableCountyUpdater(intervalMinutes,maxAccountsToProcess,JOB_NAME);

        System.schedule(JOB_NAME + '-' + dtNow.format(), cronString, job);

        Id jobId = ctx.getTriggerId();
        System.abortJob(jobId);

        QueueableCountyUpdater q = new QueueableCountyUpdater( maxAccountsToProcess,false);
        System.enqueueJob(q);
    }
}