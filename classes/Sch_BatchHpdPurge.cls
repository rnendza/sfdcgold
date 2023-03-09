/**
 * Runs a queueable job on schedule bases xxx
 */
public class Sch_BatchHpdPurge implements Schedulable{

    private String JOB_NAME = 'Accel_Schedule_Batch_Hpd_Purge';
    private Integer BATCH_SIZE = 2000;

    public Sch_BatchHpdPurge() {}

    /**
     *
     * @param ctx  The context of the scheduled job.
     */
    public void execute(SchedulableContext ctx) {
        BatchHpdPurge b = new BatchHpdPurge();
        Id jobId = Database.executeBatch(b,BATCH_SIZE);
        System.debug(LoggingLevel.INFO,'Executing batch job '+JOB_NAME + ' Id='+jobId+' with a batch size of '+BATCH_SIZE);
    }
}