/**
 * Sample Schedule Script
 * ============================
 *
 *  // run every day at 5pm
 *  Sch_BatchSweepstakesLocUpdate schJob = new Sch_BatchSweepstakesLocUpdate();
 *  String cron = '0 0 17 * * ?';
 *  system.schedule('BatchsweepstakesLocUpdate', cron, schJob);
 *
 * Schedule doc.
 *
 * second minute hour day_of_month month day_of_week optional_year
 *
 * second:        0 (this doesn't actually do anything)
 * minute:        0–59
 * hour:          0-23
 * day_of_month:  1-31 - * ? / L W
 * month:         1-12 JAN-DEC , - * /
 * day_of_week:   1-7 SUN-SAT , - * ? / L #
 * optional_year: null or 1970–2099 , - * /
 *
 * Character   Description
 * ,           Delimits values. Example: JAN, MAR, APR
 * -           Specifies a range. Example: JAN-MAR
 * *           Specifies all values
 * ?           Specifies no specific value
 * /           Specifies increments. Example: Day_of_month = 1/5, the will run every fifth day of the month, starting on the first of the month.
 * L           Specifies the end of a range (last). See docs for more details
 * W           Specifies the nearest weekday of the given day. Example: 20W. If 20th is a Saturday, the class runs on the 19th
 * #           Specifies the nth day of the month, in the format weekday#day_of_month. Example: 2#2 means the class runs on the second Monday of every month.
 * ============================
 */
public class Sch_BatchSweepstakesLocUpdate  implements  Schedulable{

    public static Integer DEFAULT_BATCH_SIZE = 50;
    public static Boolean DEFAULT_COMMIT = true;
    public static Boolean DEFAULT_LOG_EXECUTE_METHOD = false;

    public Sch_BatchSweepstakesLocUpdate() {}

    /**
     * @param ctx  The context of the scheduled job.
     */
    public void execute(SchedulableContext ctx) {

        Batch_Job_Setting__mdt mdt = BatchJobSvc.queryForMetadata(BatchSweepstakesLocUpdate.jobName);

        Integer iBatchSize = mdt != null && mdt.Batch_Size__c != null ? Integer.valueOf(mdt.Batch_Size__c) : DEFAULT_BATCH_SIZE;
        Boolean bCommitUpdates = mdt != null && mdt.Commit_Updates__c != null ? mdt.Commit_Updates__c : DEFAULT_COMMIT;
        Boolean bLogExeMethod =   mdt != null && mdt.Log_Execute_Method__c != null ? mdt.Log_Execute_Method__c : DEFAULT_LOG_EXECUTE_METHOD;


        BatchSweepstakesLocUpdate b = new BatchSweepstakesLocUpdate(bCommitUpdates,iBatchSize,bLogExeMethod, ctx.getTriggerId());
        Id jobId = Database.executeBatch(b,iBatchSize);
        System.debug(LoggingLevel.INFO,'Executing batch job Sch_BatchSweepstakesLocUpdate Id='+jobId+' with a batch size of '+iBatchSize);
    }
}