public with sharing class clBatchPreviousMeters  implements Database.Batchable <SObject>, Database.Stateful {

    public static String jobName = 'clBatchPreviousMeters'; // Important as your custom mdt is keyed by this.
    public Id jobId;

    private Boolean commitTrans = false;
    private Integer batchSize;
    private Date startCreatedDate;
    private Date endCreatedDate;
    private Set<Id> assetIdsToFilter;
    private List<Id> accountIdsToFilter;
    private String soql;

    //  This is primarily used if we want to limit real time testing. (Gov limit is 50 mil)
    public static Integer RECORDS_TO_PROCESS_LIMIT = 50000000;

    //  Single log file for each nightly run which will be updated throughout the process.
    public Accel_Application_Error__c log;

    //  Various internal stateful counters
    private Integer     iTotalRecordsFailed = 0, iTotalRecordsSelected = 0, iTotalRecordsUpdated = 0;
    private Integer     iTotalRecordsProcessed = 0,iNumExeCalls = 0;
    public  Boolean     logFailedRecordIds = true;

    private Map<Id,String> mFailedUpdates      = new Map<Id,String>();

    public Set<Id>  meterIdsNoAssetId          = new Set<Id>();

    //  Used for anon apex hack
    @TestVisible
    private Map<Id,Meter_Reading__c> mMetersToUpd = new Map<Id,Meter_Reading__c>();

    @TestVisible
    private Map<Id,List<Meter_Reading__c>>  mMeterReadingsStore   = new Map<Id,List<Meter_Reading__c>>();

    //  Used for Unit Testing.
    @TestVisible private static Boolean FORCE_PARTIAL_DML_EXCEPTION = false;
    @TestVisible private static Integer DEFAULT_BATCH_SIZE = 200;
    @TestVisible private static Boolean DEFAULT_COMMIT = true;

    /**
     * DEFAULT NO ARG constructor. Process all meters. (Be care as we may bust gov limits).
     */
    public clBatchPreviousMeters() {
        this.batchSize = DEFAULT_BATCH_SIZE;
        this.commitTrans = DEFAULT_COMMIT;
        this.initLog();                                         //  Insert a log.
        String logMsg = '\n * Constructor default: '+this.batchSize + ' default commit = '+this.commitTrans;
        System.debug(logMsg);
        this.log.Execution_Details__c += logMsg;
        this.log = AppLogSvc.updateLog(log);
    }

   /**
    * Allows the client to dictate the soql used. Yet another attempt to try to get this to work.
    * Adjust batch size as desired in both call and param passed.
    *
    * Usage:
    *  clBatchPreviousMeters b = new clBatchPreviousMeters(soql, 50);
    *  Id jobId = Database.executeBatch(b,50);
    *
    * @param soql         The soql to use in the start method.
    * @param iBatchSize   The size of the batch.
    *
    * @see clBatchPreviousMetersTest.test_prevMeterReadings_custom_soql_success()
    */
    public clBatchPreviousMeters(String soql, Integer iBatchSize) {
        this.batchSize = iBatchSize;
        this.soql = soql;
        this.initLog();
        String logMsg = '\n * SOQL Constructor batchsize: '+this.batchSize +
                'soql = '+soql;
        System.debug(logMsg);
        log.Execution_Details__c += logMsg;
        AppLogSvc.updateLog(log);
    }

   /**
    * Filter meters by asset ids.
    *
    * @param assetIdsToFilter = a Set<Id> of assetIds to filter in the start query.
    */
    public clBatchPreviousMeters(Set<Id> assetIdsToFilter) {
        this.batchSize = DEFAULT_BATCH_SIZE;
        this.commitTrans = DEFAULT_COMMIT;
        this.assetIdsToFilter = assetIdsToFilter;
        this.initLog();                                         //  Insert a log.
        String logMsg = '\n * Constructor default: '+this.batchSize + ' default commit = '+this.commitTrans
         + ' assetIDs='+assetIdsToFilter;
        System.debug(logMsg);
        this.log.Execution_Details__c += logMsg;
        this.log = AppLogSvc.updateLog(log);
    }
    /**
     * Filter meters by account ids.
     *
     * @param accountIdsToFilter = a List<Id> of acocuntIds to filter in the start query.
     */
    public clBatchPreviousMeters(List<Id> accountIdsToFilter) {
        this.batchSize = DEFAULT_BATCH_SIZE;
        this.commitTrans = DEFAULT_COMMIT;
        this.accountIdsToFilter = accountIdsToFilter;
        this.initLog();                                         //  Insert a log.
        String logMsg = '\n * Constructor default: '+this.batchSize + ' default commit = '+this.commitTrans
        + ' accountIds = '+accountIdsToFilter;
        System.debug(logMsg);
        this.log.Execution_Details__c += logMsg;
        this.log = AppLogSvc.updateLog(log);
    }

    /**
     * Update all Meter_Readings__c (Be care as we may bust gov limits).
     *
     * @param iBatchSize   The size of the batch.
     * @param bCommitTrans True if we want to commit the trans, otherwise false
     */
    public clBatchPreviousMeters(Integer iBatchSize, Boolean bCommitTrans) {
        this.batchSize = iBatchSize;
        this.commitTrans = bCommitTrans;
        this.initLog();                                         //  Insert a log.
        String logMsg = '\n * Constructor batchsize: '+this.batchSize + ' commit trans = '+this.commitTrans;
        System.debug(logMsg);
        this.log.Execution_Details__c += logMsg;
        this.log = AppLogSvc.updateLog(log);
    }

    /**
     * This is the most preferable constructor as it allows limiting the meter readings processed to start
     * and end created dates.
     *
     * @param iBatchSize        The size of the batch.
     * @param bCommitTrans      True if we want to commit the trans, otherwise false.
     * @param startCreatedDate  The Meter_Reading__c.CreatedDate to start the query selection with.
     * @param endCreatedDate    The Meter_Reading__c.CreatedDate to end the query with.
     */
    public clBatchPreviousMeters(Integer iBatchSize, Boolean bCommitTrans,Date startCreatedDate, Date endCreatedDate) {
        this.batchSize = iBatchSize;
        this.commitTrans = bCommitTrans;
        this.startCreatedDate = startCreatedDate;
        this.endCreatedDate = endCreatedDate;
        this.initLog();
        String logMsg = '\n * Constructor batchsize: '+this.batchSize + ' commit trans = '+this.commitTrans
                + ' startCreatedDate: '+startCreatedDate + ' endCreatedDate: '+endCreatedDate;
        System.debug(logMsg);
        log.Execution_Details__c += logMsg;
        AppLogSvc.updateLog(log);
    }

    /**
     * This uses a startCreated date but no end created date (goes to the most recent meter reading record).
     *
     * @param iBatchSize        The size of the batch.
     * @param bCommitTrans      True if we want to commit the trans, otherwise false.
     * @param startCreatedDate  The Meter_Reading__c.CreatedDate to start the query selection with.
     */
    public clBatchPreviousMeters(Integer iBatchSize, Boolean bCommitTrans,Date startCreatedDate) {
        this.batchSize = iBatchSize;
        this.commitTrans = bCommitTrans;
        this.startCreatedDate = startCreatedDate;
        this.endCreatedDate = endCreatedDate;
        this.initLog();
        String logMsg = '\n * Constructor batchsize: '+this.batchSize + ' commit trans = '+this.commitTrans
                + ' startCreatedDate: '+startCreatedDate;
        System.debug(logMsg);
        log.Execution_Details__c += logMsg;
        AppLogSvc.updateLog(log);
    }

    /**
     * Primary query method. Give me all meter readings with Cannot_Collect != TRUE
     * and filter them by any client indicates values ( overloaded constructors )
     *
     * @param bc  The Batchable Context.
     * @return    A Database.QueryLocator of Meter_Reading__c sObject Results.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        this.jobId = bc.getJobId();
        this.log  = AppLogSvc.retrieveLog(this.log.Id);
        this.log.Initiating_Job_Id__c = this.jobId;
        String soql = '';

        if(this.soql != null) {
            soql = this.soql;
        } else {
            Date endDate = this.endCreatedDate, startDate = this.startCreatedDate;
            Set<Id> assetIds = this.assetIdsToFilter;
            List<Id> accountIds = this.accountIdsToFilter;

            this.log.Execution_Details__c += '\n* Start: Batch Size Requested ' + batchSize;

            soql += 'SELECT   Id, Previous_Meter_Reading__c, Asset__c, CreatedDate ';
            soql += 'FROM     Meter_Reading__c ';
            soql += 'WHERE    Cannot_Collect__c != TRUE ';
            if (this.startCreatedDate != null) {
                soql += ' AND CreatedDate >= :startDate ';
            }
            if (this.endCreatedDate != null) {
                soql += ' AND CreatedDate <= :endDate ';
            }
            if (this.assetIdsToFilter != null) {
                soql += ' AND Asset__c IN :assetIds ';
            }
            if (this.accountIdsToFilter != null) {
                soql += ' AND Route_Processing_Sheet__r.Account__c IN :accountIds ';
            }
            soql += 'LIMIT    :RECORDS_TO_PROCESS_LIMIT ';
        }

        this.log.Execution_Details__c += '\n* Start: Query: ' +soql + '\n';
        this.log = AppLogSvc.updateLog(this.log);

        Database.QueryLocator ql = Database.getQueryLocator(soql);

        return ql;
    }

    /**
     * Roll through the queried Meters in the scope and simply stores them in persistent map for
     * processing in the finish method.
     *
     * @param bc        The Batchable context.
     * @param scope     The Scope. ie a List of Account sObjects queried in the start method.
     *
     * @implNotes If we are processing too many Meter_Readings__c we may run into a heapsize limit. if so
     *            call the constructor with Start / End date params.
     */
    public void execute(Database.BatchableContext bc, List<Meter_Reading__c> scope) {

        this.iTotalRecordsSelected += scope.size();
        this.iNumExeCalls++;
        if(this.soql == null) {
            for (Meter_Reading__c mr : scope) {
                if (mr.Asset__c == null) {
                    System.debug(LoggingLevel.WARN, 'batch execute no asset associated with meter: ' + mr);
                    meterIdsNoAssetId.add(mr.Id);
                } else {
                    this.iTotalRecordsProcessed++;
                    if (!mMeterReadingsStore.containsKey(mr.Asset__c)) {
                        mMeterReadingsStore.put(mr.Asset__c, new List<Meter_Reading__c>{mr});
                    } else {
                        List<Meter_Reading__c> storedMeters = mMeterReadingsStore.get(mr.Asset__c);
                        storedMeters.add(mr);
                    }
                }
            }
        } else {
            //  Custom after the fact fix to simulate anon apex script
            Integer i;
            Id currAsset;

            for(i=0; i<scope.size(); i++){
                currAsset = scope[i].asset__c;
                //loop through all of the sorted elements other than the last one
                if(i<scope.size()-1 && scope[i+1].asset__c == currAsset){
                    //older record exists, set this assets previous link to the older
                    scope[i].Previous_Meter_Reading__c = scope[i+1].Id;
                    this.mMetersToUpd.put(scope[i].Id,scope[i]);
                }
            }
        }
    }

    /**
     * No more iterations. the job is complete.
     * Perform update on Meter_Reading__c using cached map and write logs.
     *
     * @param bc        The Batchable context.
     */
    public void finish(Database.BatchableContext bc) {

        Map<Id,Meter_Reading__c> mMetersToUpd;
        if(!this.mMetersToUpd.isEmpty()) {
            //  anon apex hack
            mMetersToUpd = this.mMetersToUpd;
        } else {
            mMetersToUpd = tagMeters();
        }
        this.log = AppLogSvc.retrieveLog(this.log.Id);
        this.log.Execution_Details__c += '\n\n* Finish: Attempting to update '+ mMetersToUpd.size()+' meters. \n';

        //  Perform an Explicit Update Using partial Commits
        if (!mMetersToUpd.isEmpty()) {

            if(FORCE_PARTIAL_DML_EXCEPTION) {
                mMetersToUpd.values()[0].Reading_Status__c = 'BogusStatusGoBoom'; //  Force Restricted picklist value
            }
            List<Database.SaveResult> results = Database.update(mMetersToUpd.values(), false);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results.get(i);
                if(sr.isSuccess()) {
                    this.iTotalRecordsUpdated++;
                } else {
                    this.iTotalRecordsFailed++;
                    this.processSaveErrors(results, mMetersToUpd, i);
                }
            }
            if(this.iTotalRecordsFailed == 0) {
                String logMsg = '\n * Execute NO UPDATE attempts failed';
                System.debug(LoggingLevel.DEBUG,logMsg);
                this.log.Execution_Details__c += logMsg;
            }
        }
        this.writeFinalLog(this.log);
    }


    /**
     * For each unique asset tied to a Meter_Reading__c:
     * 1. Roll through all the Meter_Readings__c assocated with that asset.
     * 2. Throw the Meter_Reading__c sObjects in a Wrapper for purposes of sorting by CreatedDate DESC.
     * 3. Set the Meter_Reading__c.Previous_Meter_Reading__c value to i + 1.
     * 4. If it's the last Meter_Reading__c associated with asset, Set Meter_Reading__c.Previous_Meter_Reading__c to null.
     *
     * @return a Map of Meter_Reading__c.Id => Meter_Reading__c
     */
    public Map<Id,Meter_Reading__c> tagMeters() {
        Map<Id,Meter_Reading__c> mMetersToUpd = new Map<Id,Meter_Reading__c>();

        for(Id assetId : mMeterReadingsStore.keySet()) {
            Integer i = 0;

            List<Meter_Reading__c> meterReadings = mMeterReadingsStore.get(assetId);
            Integer iTotalMetersForAsset = meterReadings.size();

            List<MeterWrapper> meterWrappers = wrapMeters(meterReadings);
            meterWrappers.sort();

            for(MeterWrapper meterWrapper : meterWrappers) {
                if(i < iTotalMetersForAsset - 1) {
                    meterWrapper.meterReading.Previous_Meter_Reading__c = meterWrappers[i+1].meterReading.Id;
                } else {
                    //  Last one before new asset there is no more meter readings behind this!
                    meterWrapper.meterReading.Previous_Meter_Reading__c = null;
                }
                mMetersToUpd.put(meterWrapper.meterReading.Id,meterWrapper.meterReading);
                i++;
            }
        }
        return mMetersToUpd;
    }
    /**
     * @param meters A List<Meter_Reading__c> to put in the wrapper.
     * @return       A List<MeterWrapper> of the passed meter readings.
     */
    private List<MeterWrapper> wrapMeters(List<Meter_Reading__c> meters) {
        List<MeterWrapper> meterWrappers = new List<MeterWrapper>();
        for(Meter_Reading__c mr : meters) {
            meterWrappers.add( new MeterWrapper(mr));
        }
        return meterWrappers;
    }

    /**
     * A Simple wrapper of Meter_Reading__c.
     */
    public class MeterWrapper implements Comparable {
        public Meter_Reading__c meterReading;

        public MeterWrapper(Meter_Reading__c mr) {
            this.meterReading = mr;
        }

        public Integer compareTo(Object compareTo) {
            MeterWrapper compareToMeterWrapper = (MeterWrapper) compareTo;
            Integer ret = 0;
            if(meterReading.CreatedDate < compareToMeterWrapper.meterReading.CreatedDate) {
                ret = 1;
            }
            return ret;
        }
    }

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
        log.JobType__c ='BatchApex';
        insert log;
        this.log = log;
    }

    /**
     * Writes job level totals.
     * @param log The current Accel_Application_error__c log in ctx.
     */
    private void writeFinalLog(Accel_Application_Error__c log) {
        if (log != null) {
            this.log = AppLogSvc.retrieveLog(this.log.Id);
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
            log.Execution_Details__c += '* Total Meters without Assets = ' + meterIdsNoAssetId.size() + '\n';
            log.Overall_Job_Status__c = 'Success';

            if(!meterIdsNoAssetId.isEmpty()) {
                log.Stack_Trace__c+= '\n  Meter Ids Without Assets...= ' + meterIdsNoAssetId + '\n\n';
            }

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
            log.Initiating_Job_Id__c  = this.jobId;
            this.log = AppLogSvc.updateLog(log);
        }
    }
}