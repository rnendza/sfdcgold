public class clQueueablePreviousMeters implements Queueable {

    @TestVisible private static String jobName = 'clQueueablePreviousMeters';
    @TestVisible private Map<Id,Meter_Reading__c> mNewMeters;
    @TestVisible private Id jobId;
    @TestVisible private Accel_Application_Error__c log;

    //  Various internal stateful counters
    private Integer     iTotalRecordsFailed = 0, iTotalRecordsSelected = 0, iTotalRecordsUpdated = 0;
    private Integer     iTotalRecordsProcessed = 0,iNumExeCalls = 0;
    public  Boolean     logFailedRecordIds = true;

    private Map<Id,String> mFailedUpdates      = new Map<Id,String>();
    Set<Id> successfulRetries = new Set<Id>();

    //  Used for Unit Testing.
    @TestVisible private static Boolean FORCE_PARTIAL_DML_EXCEPTION = false;
    @TestVisible private static Boolean FORCE_FULL_EXCEPTION = false;
    @TestVisible public static Boolean DO_LOCKING_FIX = true;

    /**
     * Typically called in an AFTER INSERT. Only works for new Meters!
     *
     * @param mNewMeterReadings The new meter readings to search for previous meter readings and ultimate
     * update.
     */
    public clQueueablePreviousMeters(Map<Id, Meter_Reading__c> mNewMeterReadings) {
        this.initLog();
        this.mNewMeters = mNewMeterReadings;
        iTotalRecordsSelected = this.mNewMeters.size();
        String logMsg = '\n * Constructor processing '+this.mNewMeters.size()+' meters.';
        System.debug(logMsg);
        log.Execution_Details__c += logMsg;
    }
    /**
     * Standard queueable execute method.
     * @param ctx The Queueable context.
     */
    public void execute(QueueableContext ctx) {
        this.jobId = ctx.getJobId();
        this.log.Initiating_Job_Id__c = this.jobId;
        this.iNumExeCalls++;
        String logMsg = '\n * Execute running with job id '+this.jobId;
        this.log.Execution_Details__c += logMsg;
        performExecute();
    }
    /**
     * Delegate of queueable execute method.
     *
     * 1. Create a Map of Asset Id => Meter_Reading__c for the new Meters in context.
     * 2. Perform an Aggregate Query to group Meters by Asset grabbing the most recently created meter
     *    excluding the new meters in context.
     * 3. Match 1 with 2 based on Asset Id.
     * 4. Perform the Update.
     */
    public void performExecute() {

        Map<Id,Meter_Reading__c> mMeterReadingsToUpd = new Map<Id,Meter_Reading__c>();
        Map<Id, Id> mNewAssetId_MeterId = new Map<Id, Id>();

        for (Meter_Reading__c mrNew : mNewMeters.values()) {
            if (mrNew.Asset__c != null) {
                this.iTotalRecordsProcessed ++;
                mNewAssetId_MeterId.put(mrNew.Asset__c, mrNew.Id);
            } else {
                String logMsg = '\n* WARNING Meter Missing Asset Id :'+mrNew+'\n';
                log.Stack_Trace__c += logMsg;
                System.debug(LoggingLevel.WARN,logMsg);
            }
        }
        //  Find the most recent previous meter reading for each  Assetid associated with each incoming meter (Aggregate query).
        Map<Id, Meter_Reading__c> mAssetId_PrevMeter = findPreviousMeterReadings(mNewAssetId_MeterId.keySet());

        //  Re-query new Meters in context to ensure we have all necessary fields.
        List<Meter_Reading__c> newMeters = [
                SELECT Id,Asset__c,Previous_Meter_Reading__c
                FROM Meter_Reading__c
                WHERE Id IN :this.mNewMeters.keySet()
        ];

        //  Roll through new meter readings in context finding the most recent one grouped by asset id.
        for (Meter_Reading__c newMeter : newMeters) {
            if (mAssetId_PrevMeter.containsKey(newMeter.Asset__c)) {
                Meter_Reading__c prevMeter = mAssetId_PrevMeter.get(newMeter.Asset__c);
                newMeter.Previous_Meter_Reading__c = prevMeter.Id;
                mMeterReadingsToUpd.put(newMeter.Id,newMeter);
            }
        }
        String logMsg = '\n * Execute number of meter readings matched to update: '+mMeterReadingsToUpd.size();
        System.debug(LoggingLevel.DEBUG,logMsg);
        this.log.Execution_Details__c += logMsg;

        //  Perform an Explicit Update Using partial Commits
        if (!mMeterReadingsToUpd.isEmpty()) {

            if(FORCE_PARTIAL_DML_EXCEPTION) {
                mMeterReadingsToUpd.values()[0].Reading_Status__c = 'BogusStatusGoBoom'; //  Force Restricted picklist value
            }
            List<Database.SaveResult> results;
            try {
                results = Database.update(mMeterReadingsToUpd.values(), false);
                if(FORCE_FULL_EXCEPTION) {
                    throw new TestException('Test Exception');
                }
            } catch (Exception e) {
                //  mainly for dml locking exception caused by DLRS which do not work on a partial commit.
                String logMsg2 = '\n * Exception on Meters Update Caught..'+e;
                System.debug(LoggingLevel.DEBUG, logMsg2);
                this.log.Execution_Details__c += logMsg2;
                if(DO_LOCKING_FIX) {
                    logMsg2 = '\n * attempting retry..';
                    System.debug(LoggingLevel.DEBUG, logMsg2);
                    this.log.Execution_Details__c += logMsg2;
                    results = Database.update(mMeterReadingsToUpd.values(), false);
                    logMsg2 = '\n *after retry..';
                    System.debug(LoggingLevel.DEBUG, logMsg2);
                    this.log.Execution_Details__c += logMsg2;
                }
            }
            if(results != null) {
                for (Integer i = 0; i < results.size(); i++) {
                    Database.SaveResult sr = results.get(i);
                    if (sr.isSuccess()) {
                        this.iTotalRecordsUpdated++;
                    } else {
                        this.iTotalRecordsFailed++;
                        this.processSaveErrors(results, mMeterReadingsToUpd, i);
                    }
                }
                if (this.iTotalRecordsFailed == 0) {
                    String logMsg2 = '\n * Execute NO UPDATE attempts failed';
                    System.debug(LoggingLevel.DEBUG, logMsg2);
                    this.log.Execution_Details__c += logMsg2;
                }
            }
        }
        this.writeFinalLog(this.log);
    }

    /**
     * Find all Prev meter readings for the passed asset ids excluding the currently processed ones
     * and those marked Cannot Collect.
     *
     * @param assetIds  The set of Asset.Id(s) associated with incoming meters in context.
     * @return A Map of Asset.Id => Meter_Reading__c (MR being the previous meter reading).
     */
    @TestVisible
    private Map<Id,Meter_Reading__c> findPreviousMeterReadings(Set<Id> assetIds) {

        Map<Id,Meter_Reading__c> mAssetId_MeterReading = new Map<Id,Meter_Reading__c>();

        List<AggregateResult> ars = [
                SELECT   Asset__c,MAX(CreatedDate) maxCreatedDate, MAX(Id) maxMeterId
                FROM     Meter_Reading__c
                WHERE    Id NOT IN :mNewMeters.keySet()
                AND      Asset__c IN :assetIds
                AND      Cannot_Collect__c != TRUE
                GROUP BY Asset__c
        ];
        if(!ars.isEmpty()) {
            for(AggregateResult ar : ars) {
                Id assetId = (Id)ar.get('Asset__c');
                Id meterId =  (Id)ar.get('maxMeterId');
                Meter_Reading__c mr = new Meter_Reading__c( Id = meterId, Asset__c = assetId );
                mAssetId_MeterReading.put(assetId,mr);
            }
        }
        String logMsg = '\n * Execute findPreviousMeterReadings() grouped by asset.. Number of assets grouped: '+mAssetId_MeterReading.size();
        System.debug(LoggingLevel.DEBUG,logMsg);
        this.log.Execution_Details__c += logMsg;
        return mAssetId_MeterReading;
    }

    // =========   MOSTLY LOGGING AND ERROR HANDLING =========

    /**
     * Process an partial save error.
     *
     * @param results               The list of Database.SaveResults
     * @param sr                    The Database.SaveResult that errored out.
     * @param meterReadingsToUpdate The original Map of Meter_Reading__c.Id => Meter_Reading__c sObject that was updated.
     * @param idx                   The index of record being updated.
     */
    private void processSaveErrors(  List<Database.SaveResult> results, Map<Id, Meter_Reading__c> meterReadingsToUpdate, Integer idx) {

        this.iTotalRecordsFailed++;
        String errorMsg = '';
        Id mrId = meterReadingsToUpdate.values().get(idx).Id;

        for (Database.Error error : results.get(idx).getErrors()) {
            errorMsg += mrId + ',' + error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
            System.debug(LoggingLevel.ERROR, meterReadingsToUpdate.values().get(idx).Id + ' - ' + errorMsg);
        }
        mFailedUpdates.put(mrId, errorMsg);
    }

    public class TestException extends  Exception {

    }

    /**
     * Inserts a new log to be used in this job.
     */
    private void initLog() {

        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);

        log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_PROCESSING;
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 0;
        log.Total_Records_Selected__c = 0;
        log.Stack_Trace__c = ' ';
        log.Execution_Details__c = ' ';
        log.JobType__c ='Queueable';
        log.Initiating_Job_Id__c = this.jobId;

        this.log = log;
    }

    /**
     * Writes job level totals.
     * @param log The current Accel_Application_error__c log in ctx.
     */
    private void writeFinalLog(Accel_Application_Error__c log) {

        if (log != null) {

            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of Batch ' + this.jobId + '\n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Processed__c = iTotalRecordsProcessed;
            log.Total_Records_Updated__c = iTotalRecordsUpdated;
            log.Total_Updates_Failed__c = iTotalRecordsFailed;
            log.Execution_Details__c += '* Total Records Selected = ' + iTotalRecordsSelected + '\n';
            log.Execution_Details__c += '* Total Records Attempted to Update = ' + log.Total_Records_Processed__c + '\n';
            log.Execution_Details__c += '* Total Records Updated = ' + log.Total_Records_Updated__c + '\n';
            log.Execution_Details__c += '* Total Updates Failed = ' + mFailedUpdates.size() + '\n';
            log.Overall_Job_Status__c = 'Success';

            if (!mFailedUpdates.isEmpty()) {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_PARTIAL_SUCCESS;
                String allErrorIds = '';
                for (String accountId : mFailedUpdates.keySet()) {
                    allErrorIds += accountId + ',';
                }
                allErrorIds = allErrorIds.removeEnd(',');
                if (this.logFailedRecordIds) {
                    log.Stack_Trace__c += '\n* Failed Meter Ids ....\n';
                    log.Stack_Trace__c += allErrorIds;
                    log.Stack_Trace__c += '\n* Failure Messages ....';
                    for (String msg : mFailedUpdates.values()) {
                        log.Stack_Trace__c += '\n' + msg;
                    }
                } else {
                    System.debug(LoggingLevel.ERROR, '---> failed update record IDs:' + allErrorIds);
                }
            }

            if (log.Total_Updates_Failed__c == 0) {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_SUCCESS;
            } else if (log.Total_Updates_Failed__C > 0 && log.Total_Records_Updated__c > 0) {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_PARTIAL_SUCCESS;
            } else {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_FAILED;
            }
            insert log;
        }
    }

}