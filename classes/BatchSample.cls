/**
 * An ultra simplistic example of utilizing BatchjobSvc and AppLogSvc with a batch job.
 * One can use this as a starting point for similar jobs. In the real world you will need much more error
 * handling and business logic.
 *
 * All this does is query all accounts and update those created within the last month.
 * The batch size number depends on if your updating something heavy. account is very heavy thus so low.
 *
 * Add a record to Batch_Job_Setting__mdt prior to running this (devname = jobName below)
 *
 * ==========================================================
 *  Sample adhoc execution:
 *
 *  Integer iBatchSize = 50;
 *  Database.executeBatch(new BatchSample(iBatchSize),iBatchSize);
 * ==========================================================
 *
 * @see BatchSweepstakesLocUpdate to view a real world / complex example that records errors, sends emails etc.
 *
 * @see BatchjobSvc                 (Retrieval of mdt, and sending emails)
 * @see AppLogSvc                   (Logging to Accel_Application_Error__c)
 * @see Batch_Job_Setting__mdt      (With dev name of BatchSample)
 * @see Accel_Application_Error__c  (Label = Accel Application Logs ie. the target sObject for logging)
 * @see Batch_Job_Setting__mdt      (This is the metadata that backs the run of this job with params);
 */
public with sharing class BatchSample implements Database.Batchable <SObject>, Database.Stateful {

    public static String jobName = 'BatchSample'; // Important as your custom mdt is keyed by this.
    public Id jobId;
    private Integer batchSize;

    //  This is primarily used if we want to limit real time testing. (Gov limit is 50 mil)
    public static Integer RECORDS_TO_PROCESS_LIMIT = 49000000;

    //  Single log file for each nightly run which will be updated throughout the process.
    public Accel_Application_Error__c log;

    //  Custom metadata used. This will normally have a developername of the name of this executing class.
    public  Batch_Job_Setting__mdt jobMdt;

    //  Various internal stateful counters
    private Integer     iNumAccountsFailed = 0, iTotalRecordsSelected = 0,iNumAccountsUpdated = 0;
    private Integer     iTotalRecordsProcessed = 0,iNumExeCalls = 0;

    //  Used for Unit Testing.
    @TestVisible private static Boolean FORCE_PARTIAL_DML_EXCEPTION = false;

    /**
     * @param iBatchSize  The size of the batch.
     */
    public BatchSample(Integer iBatchSize) {
        this.batchSize = iBatchSize;
        this.initLog();                                         //  Insert a log.
        this.jobMdt = BatchjobSvc.queryForMetadata(jobName);    //  Query Metadata for params.
        log.Execution_Details__c += '\n * Constructor:  custom mdt = '+this.jobMdt;
    }

    /**
     * Primary query method
     *
     * @param bc  The Batchable Context.
     * @return    A Database.QueryLocator of Marketing_Request__c sObject Results.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
        this.jobId = bc.getJobId();
        log.Initiating_Job_Id__c = this.jobId;
        log.Execution_Details__c += '\n* Start: Batch Size Requested ' + batchSize + '\n \n';

        AppLogSvc.updateLog(log);

        Database.QueryLocator ql = Database.getQueryLocator([
                SELECT Id, Name,CreatedDate
                FROM Account
                WITH SECURITY_ENFORCED
                LIMIT :RECORDS_TO_PROCESS_LIMIT
        ]);
        return ql;
    }

    /**
     * Roll through the queried batch and do a touch updated for example.
     *
     * @param bc        The Batchable context.
     * @param scope     The Scope. ie a List of Account sObjects queried in the start method.
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {

        this.iTotalRecordsSelected += scope.size();
        this.iNumExeCalls++;

        if (jobMdt.Log_Execute_Method__c) {
            Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
            log.Execution_Details__c += '\n* In #' + iNumExeCalls + ' execute of Batch ' + bc.getJobId()
                    + '.-->  # of account records in scope=' + scope.size() + '\n';
            AppLogSvc.updateLog(log);
        }

        List<Account> accountsToUpdate = new List<Account>();

        //  Simple Sample Business logic if created in the past month update (touch the record)
        Integer x = 0;
        for (Account account : scope) {
            if(account.createdDate >= Date.today().addMonths(-1)) {
                if(FORCE_PARTIAL_DML_EXCEPTION && x == 0) {
                    account.Type = 'BogusTypeGoBoom'; //  Force Restricted picklist value on 1 account.
                }
                x++;
                this.iTotalRecordsProcessed ++;
                accountsToUpdate.add(account);
            }
        }

        if(!accountsToUpdate.isEmpty()) {

            //  Fire an update using partial commits!
            List<Database.SaveResult> results = Database.update(accountsToUpdate, false);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results.get(i);
                if(sr.isSuccess()) {
                    this.iNumAccountsUpdated++;
                } else {
                    //  One can further determine the errors via Database.SaveResult.
                    //  @see BatchSweepstakesLocUpdate
                    this.iNumAccountsFailed++;
                }
            }
        }
    }

    /**
     * No more iterations. the job is complete. Update final counters on the log, send emails if you want etc.
     * @param bc        The Batchable context.
     */
    public void finish(Database.BatchableContext bc) {

        Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);

        this.writeFinalLog(log);
        log = AppLogSvc.retrieveLog(log.Id);
        System.debug(LoggingLevel.INFO, '---> in finish of batch job:' + this.jobId + ' log is:' + log);
        System.debug(LoggingLevel.INFO, '---> Status = ' + log.Overall_Job_Status__c);
    }

    /**
     * Inserts a new log to be used in this entire Batch job run.
     */
    private void initLog() {

        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);

        log.Overall_Job_Status__c = 'Processing';
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 0;
        log.Total_Records_Selected__c = 0;
        log.Stack_Trace__c = ' ';
        log.Batch_Size__c = this.batchSize;
        log.Execution_Details__c = ' ';

        insert log;
        this.log = log;
    }

    /**
     * Writes job level totals from the finish method.
     * @param log The current Accel_Application_error__c log in ctx.
     */
    private void writeFinalLog(Accel_Application_Error__c log) {

        if (log != null && log.Id != null) {

            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of Batch ' + this.jobId + '\n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Updated__c = iNumAccountsUpdated;
            log.Total_Updates_Failed__c = iNumAccountsFailed;
            log.Total_Records_Processed__c = iTotalRecordsProcessed;
            log.Execution_Details__c += '* Total Records Selected = '+ iTotalRecordsSelected+ '\n';
            log.Execution_Details__c += '* Total Accounts Attempted to Update = ' + log.Total_Records_Processed__c + '\n';
            log.Execution_Details__c += '* Total Accounts Updated = '+log.Total_Records_Updated__c + '\n';
            log.Execution_Details__c += '* Total Account Updates Failed = '+log.Total_Updates_Failed__c + '\n';
            log.Overall_Job_Status__c  = 'Success';

            AppLogSvc.updateLog(log);
        }
    }
}