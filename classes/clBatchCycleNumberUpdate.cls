/**
 * clBatchCycleNumberUpdate will select Cash_Logistic_Setting__mdt.Next_Cycle__c and increment by 1.
 * If it is equal to 28. It will reset this value to 1.   (Cash logics business rule on how the data is set up)
 */
public class  clBatchCycleNumberUpdate implements  Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{

    public static String jobName = 'clBatchCycleNumberUpdate'; // Important as your custom mdt is keyed by this.
    public Id jobId;
    private Integer batchSize = 50;

    //  Single log file for each nightly run which will be updated throughout the process.
    public Accel_Application_Error__c log;

    //  Custom metadata used. This will normally have a developername of the name of this executing class.
    public  Batch_Job_Setting__mdt jobMdt;

    public  Cash_Logistics_Setting__mdt clSchMdt;
    public  final static String CL_SCH_MDT_DEV_NAME = 'Scheduler';

    private Integer nextCycle;

    //  Various internal stateful counters
    private Integer     iTotalRecordsSelected = 0,iNumUpdated = 0;
    private Integer     iNumProcessed = 0,iNumExeCalls = 0;

    /**
     * @param pNextCycle  The Route__c.Cycle_Number__c value passed into the constructor.
     */
    public clBatchCycleNumberUpdate(Integer pNextCycle) {
        this.nextCycle = pNextCycle;
        this.initLog();                                         //  Insert a log.
        this.jobMdt = BatchjobSvc.queryForMetadata(jobName);    //  Query Metadata for params.
        log.Execution_Details__c += '\n * Constructor:  cycle number passed = '+ pNextCycle;
    }

    public clBatchCycleNumberUpdate() {
        this.initLog();                                         //  Insert a log.
        this.jobMdt = BatchjobSvc.queryForMetadata(jobName);    //  Query Metadata for params.
        log.Execution_Details__c += '\n * Constructor:  custom mdt = '+this.jobMdt;
    }

    /**
     * @param bc  The Batchable context.
     * @return    A QueryLocator with the CL Setting.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        this.jobId = bc.getJobId();
        log.Initiating_Job_Id__c = this.jobId;
        log.Execution_Details__c += '\n* Start Method: Batch Size Requested ' + batchSize + '\n \n';

        Database.QueryLocator ql = Database.getQueryLocator([
                SELECT  Id,Next_Cycle__c
                FROM    Cash_Logistics_Setting__mdt
                WHERE   DeveloperName = :CL_SCH_MDT_DEV_NAME
        ]);
        return ql;
    }

    /**
     * @param bc     The Batchable ctx.
     * @param scope  A List of Mdt records (1 in this case)
     */
    public void execute(Database.BatchableContext bc, List<Cash_Logistics_Setting__mdt> scope) {

        this.iTotalRecordsSelected += scope.size();
        this.iNumExeCalls++;
        this.clSchMdt = (Cash_Logistics_Setting__mdt) scope[0];

        if(this.nextCycle == null) {
            System.debug('---> current cycle value=' + this.clSchMdt.Next_Cycle__c);
            if(Integer.valueOf(this.clSchMdt.Next_Cycle__c) == 28) {
                this.nextCycle = 1;
            } else {
                this.nextCycle = Integer.valueOf(this.clSchMdt.Next_Cycle__c) + 1;
            }
        }
        if (jobMdt != null && jobMdt.Log_Execute_Method__c) {
            log.Execution_Details__c += '\n* Current cycle number prior to update -->'+clSchMdt.Next_Cycle__c;
            log.Execution_Details__c += '\n* Cycle number that we want to update to -->'+this.nextCycle;
        }

        System.debug('---> incremented cycle value='+this.nextCycle);

        String mdtName = 'Cash_Logistics_Setting__mdt';
        String recordDevName = 'Scheduler';
        String label = 'Scheduler';
        Map<String,Object> mFields = new Map<String,Object>();
        mFields.put('Next_Cycle__c',this.nextCycle);
        this.iNumProcessed ++;

        Id jobId = clRouteProcessingSheetsController.updateCustomMetadata(mdtName,recordDevName,label,mFields);
        System.debug(LoggingLevel.INFO,'--> IN EXEC FIRING ASYNC JOB = '+jobId);
        if (jobMdt != null && jobMdt.Log_Execute_Method__c) {
            log.Execution_Details__c += '\n* firing asycn job to update custom metadata for cycle number = '+this.nextCycle;
            log.Execution_Details__c += '\n* Please view  '+ clRouteProcessingSheetsController.jobName + ' log for results';
        }
        this.iNumUpdated++;
    }

    private void initLog() {

        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);

        log.Overall_Job_Status__c = 'Processing';
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 0;
        log.Total_Records_Selected__c = 0;
        log.Stack_Trace__c = ' ';
        log.Batch_Size__c = this.batchSize;
        log.Execution_Details__c = ' ';
        this.log = log;
    }

    /**
     * @param bc  DB
     */
    public void finish(Database.BatchableContext bc) {
        this.writeFinalLog(log);
        System.debug(LoggingLevel.INFO, '---> in finish of batch job:' + this.jobId + ' log is:' + log);
        System.debug(LoggingLevel.INFO, '---> Status = ' + log.Overall_Job_Status__c);
    }

   /**
    *  Writes job level totals from the finish method.
    *  @param log The current Accel_Application_error__c log in ctx.
    */
    private void writeFinalLog(Accel_Application_Error__c log) {

        if (log != null) {

            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of Batch ' + this.jobId + '\n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Processed__c = iNumProcessed;
            log.Execution_Details__c += '* Total Records Selected = '+ iTotalRecordsSelected+ '\n';
            log.Execution_Details__c += '* Total Records Processed = ' + log.Total_Records_Processed__c + '\n';
            log.Overall_Job_Status__c  = 'Success';
            insert log;
        }
    }
}