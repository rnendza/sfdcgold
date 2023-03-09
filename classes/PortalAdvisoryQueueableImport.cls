/**
 * Call the RESTful api with the provided constructor params.
 * Search for provider records and parse xml.
 * Upserts into PA_Advisory__c.
 * Writes Accel_Application_Error__c.
 *
 * @see PortalAdvisoryQueueableDateIncrement
 * @see PortalAdvisoryLoaderController
 * @see PortalAdvisoryLoaderSvc
 *
 * @todo modify public props to private.
 */
global class PortalAdvisoryQueueableImport implements  Queueable, Database.AllowsCallouts {

    public static final String PA_ADVISORY_IMPORT_MDT_TYPE_DEV_NAME     = 'PA_Advisory_Import';
    public static final String DEFAULT_ENDPOINT_DEV_NAME                = 'PGCBSelfExclusionService_Prod';

    public static Community_Async_Job_Setting__mdt mdtCommunityAsyncJobSetting =
            CommunityAsyncSettings.retrieveCommunityAsyncMdt(PA_ADVISORY_IMPORT_MDT_TYPE_DEV_NAME);

    public PortalAdvisoryLoaderController.CalloutParams paCalloutParams;

    public Id jobId;
    public Boolean incrementMdtDates = false;  //  Only set if called with no arg constructor.

    @TestVisible private Accel_Application_Error__c log;
    @TestVisible private String jobName = 'PortalAdvisoryQueueableImport';
    @TestVisible private String appLogRtDevName = 'PA_Advisory';

    /**
     * Uses Values from Community_Async_Job_Setting__mdt only. Will fire job to increment date counters by 1 day.
     *
     * Usage Example:
     *
     * PortalAdvisoryQueueableImport q = new PortalAdvisoryQueueableImport();
     * System.enqueueJob(q);
     */
    public PortalAdvisoryQueueableImport() {
        initLog();
        this.paCalloutParams = new PortalAdvisoryLoaderController.CalloutParams();
        this.paCalloutParams.dStartDate         = mdtCommunityAsyncJobSetting.Start_Date__c;
        this.paCalloutParams.dEndDate           = mdtCommunityAsyncJobSetting.End_Date__c;
        this.paCalloutParams.customMdtDevName   = mdtCommunityAsyncJobSetting.API_Setting_Dev_Name__c;
        this.incrementMdtDates = true;
    }


    /**
     * Manual override to adhoc run with start and end dates. Used default custom mdt dev name.
     *
     * @param startDate     The startDate to call the rest service with.
     * @param endDate       The endDate to call the rest service with.
     *
     * Usage Example:
     *
     * PortalAdvisoryQueueableImport q = new PortalAdvisoryQueueableImport( Date.today().addDays(-1),Date.today() );
     * System.enqueueJob(q);
     */
    public PortalAdvisoryQueueableImport(Date startDate,Date endDate) {
        initLog();
        this.paCalloutParams = new PortalAdvisoryLoaderController.CalloutParams();
        this.paCalloutParams.dStartDate         = startDate;
        this.paCalloutParams.dEndDate           = endDate;
        this.paCalloutParams.customMdtDevName   = mdtCommunityAsyncJobSetting.API_Setting_Dev_Name__c;
    }

    /**
     * Manual override to adhoc run with fully customized parameters.
     * @param calloutParams     The CalloutParams.
     *
     * Usage Example:
     *
     * PortalAdvisoryLoaderController.CalloutParams params = new PortalAdvisoryLoaderController.CalloutParams();
     *
     * Date dStartDate = Date.today().addDays(-10);
     * Date dEndDate = Date.today().addDays(-9);
     * params.dStartDate = dStartDate;
     * params.dEndDate = dEndDate;
     * params.customMdtDevName = PortalAdvisoryQueueableImport.DEFAULT_ENDPOINT_DEV_NAME;
     *
     * PortalAdvisoryQueueableImport q = new PortalAdvisoryQueueableImport( params );
     * System.enqueueJob(q);
     */
    public PortalAdvisoryQueueableImport(PortalAdvisoryLoaderController.CalloutParams calloutParams) {
        initLog();
        log.Execution_Details__c += '* CalloutParms constructor..\n\n';
        this.paCalloutParams = new PortalAdvisoryLoaderController.CalloutParams();
        if(calloutParams != null) {
            this.paCalloutParams.dStartDate = calloutParams.dStartDate;
            this.paCalloutParams.dEndDate = calloutParams.dEndDate;
            this.paCalloutParams.customMdtDevName = calloutParams.customMdtDevName;
        }
    }

    /**
     *
     * @param ctx The Queueble ctx.
     */
    global void execute(QueueableContext ctx) {
        jobId = ctx.getJobId();
        log.Initiating_Job_Id__c = jobId;
        ResponseDto dto = performExecute();
        log.Execution_Details__c += '----- JOB ' + jobId + ' EXECUTION COMPLETED -----';
        createLog();
    }

    /**
     * Upserts the Pa_Advisory__c records (calls out to rest provider searching with date params)
     * Parses xml and upserts the records.
     *
     * Evaluates the results for logging purposes.
     *
     * @return ResponseDto containing xyz.
     * @see PortalAdvisoryLoaderController.doUpsertPaRecords
     *
     * @implNote  We must launch an additional queuable to update the custom metadata or else we
     *            will get a mixed DML message.
     *
     * @todo finish apexdoc.
     */
    public ResponseDto performExecute() {
        ResponseDto dto = PortalAdvisoryLoaderController.doUpsertPaRecords(this.paCalloutParams);
        log.Execution_Details__c += '* Upsert message: '+dto.message +' Upsert severity:'+dto.severity + '\n\n';

        System.debug(LoggingLevel.INFO,'---> upsert dto '+dto);

        PortalAdvisoryLoaderController.CalloutParams modifiedParms =
                (PortalAdvisoryLoaderController.CalloutParams)dto.values.get(PortalAdvisoryLoaderController.MAP_KEY_CALLOUT_PARAMS);
        log.Execution_Details__c += '* '+modifiedParms + '\n\n';

        if(dto.isSuccess) {
            List<PortalAdvisoryLoaderSvc.UserRecord> userRecords =
                    (List<PortalAdvisoryLoaderSvc.UserRecord>)dto.values.get(PortalAdvisoryLoaderController.MAP_KEY_USER_RECORDS);

            List<PA_Advisory__c> touchedAdvisories =
                    (List<PA_Advisory__c>)dto.values.get(PortalAdvisoryLoaderController.MAP_KEY_PA_ADVISORY_RECORDS);

            log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_SUCCESS;
            log.Total_Records_Upserted__c = touchedAdvisories.size();
            log.Total_Records_Selected__c = userRecords.size();
            log.Total_Records_Processed__c = userRecords.size();
            log.Execution_Details__c += '* Total Xml User Records Found: '+userRecords.size() + '\n\n';
            log.Execution_Details__c += '* Total Pa_Advisory__c Records Upserted: '+touchedAdvisories.size() + '\n\n';
        }
        //  @todo clean this up!
        if(dto.isSuccess && incrementMdtDates) {
            Id jId;
            if(!Test.isRunningTest()) {
                jId = System.enqueueJob(new PortalAdvisoryQueueableDateIncrement());
            }
            System.debug('---> Firing increment queueable: '+jId);
            log.Execution_Details__c += '* Firing increment queueable jobId='+jId+'\n\n';
        } else {
            if(dto.severity == 'error') {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_FAILED;
                log.Execution_Details__c += '* Bypassing enqueue of date increment job due to date override constructor called or job failure...\n\n';
            } else {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_SUCCESS;
                if(incrementMdtDates) {
                    Id jId = System.enqueueJob(new PortalAdvisoryQueueableDateIncrement());
                    System.debug('---> Firing increment queueable: ' + jId);
                    log.Execution_Details__c += '* Firing increment queueable jobId=' + jId + '\n\n';
                }
            }
        }
        if(this.jobId == null) {
            createLog();
        }
        return dto;
    }

    /**
     * Inserts a new log to be used in this job.
     */
    @TestVisible
    private void initLog() {
        log = AppLogSvc.buildLog(appLogRtDevName,jobName);
        log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_PROCESSING;
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 0;
        log.Total_Records_Selected__c = 0;
        log.Total_Records_Upserted__c = 0;
        log.Stack_Trace__c = ' ';
        log.Execution_Details__c = ' ';
        log.JobType__c = 'Queueable';
    }

    /**
     * Actually insert the Accel_Application_Error__c record.
     */
    @TestVisible
    private  void createLog() {
        log.Process_End_Date__c = System.now();
        insert log;
    }
}