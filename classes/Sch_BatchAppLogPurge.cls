public class Sch_BatchAppLogPurge implements Schedulable {

    private String JOB_NAME = 'App_Log_Batch_Purge';
    private Integer BATCH_SIZE = 2000;

    public Sch_BatchAppLogPurge() {}

    public void execute(SchedulableContext ctx) {
        BatchAppLogPurge b = new BatchAppLogPurge();
        Id jobId = Database.executeBatch(b,BATCH_SIZE);
        
        System.debug(LoggingLevel.INFO,'Executing batch job '+JOB_NAME + ' Id='+jobId+' with a batch size of '+BATCH_SIZE);
    }
}