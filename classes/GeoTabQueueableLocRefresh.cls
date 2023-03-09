/**
 * This will perform a partial update. ie. it will attempt to update as many service resources as possible ie.
 * it won't fair one one SR erroring out due to an unrelated error. It will not succeed on gov limits such as
 * too much CPU time.. other automation sitting on top of ServiceResource cannot be handled from this class.
 *
 * An in memory Accel_Applications_Error_Log__c will be written, both here and by ref in the services, but will only
 * be inserted if commanded by the custom mdt setting. Ie. GeoTab_Setting__mdt.GeoTabQueueableRefresh
 *
 * General Execution Path:
 * 1. Constructor
 * 2. execute
 * 3. performExecute
 * 4. retrieveServiceResources
 * 5. performCallout
 * 6. processDeviceStatusInfo
 * 7. updateServiceResources
 * 8. writeFinalLogs
 *
 * @see GeoTab_Setting__mdt
 * @see API_Setting__mdt
 * @see GeoTabSvc.getDeviceStatusInfo
 * @see GeoTabQueueableLocRefreshTest
 * @see Accel_Application_Error__c
 */
public class GeoTabQueueableLocRefresh implements Queueable, Database.AllowsCallouts {

    @TestVisible private static String              jobName             =  'GeoTabQueueableLocRefresh';
    @TestVisible private static String              OWA_EMAIL_ADDY      = 'crm@accelentertainment.com';
    @TestVisible private Set<Id>                    serviceResourceIds;
    @TestVisible private Id                         jobId;
    @TestVisible private Accel_Application_Error__c log;

    //  Various internal stateful counters
    private Integer     iTotalRecordsFailed = 0, iTotalRecordsSelected = 0, iTotalRecordsUpdated = 0;
    private Integer     iTotalRecordsProcessed = 0,iNumExeCalls = 0;
    public  Boolean     logFailedRecordIds = true;
    public  String      sJobId = 'n/a';
    public  String      sErrorsBody = '';  //  For an errors email
    public  Set<String> resourcesUpdated = new Set<String>();


    private Map<Id,String> mFailedUpdates      = new Map<Id,String>();
    private GeoTab_Setting__mdt mdt = GeoTabSvc.queryForMetadata(GeoTabQueueableLocRefresh.class.getName());
    public static String EMAIL_SUBJ = 'Accel - Salesforce - GeoTab GPS Error';
    public static String DRIVING_STATUS = 'Driving';
    public static String STOPPED_STATUS = 'Stopped';

    public static Boolean FORCE_PARTIAL_DML_EXCEPTION = false; //  Used for Unit Testing.

    /**
     * Overloaded async queueable method.
     * Use this constructor if we don't want to process all service resources with a GeoTabId__c value.
     * i.e something called from the command line on an adhoc basis or ui maybe.
     *
     * @param serviceResourceIds  Specific service resource ids to zone in on.
     */
    public GeoTabQueueableLocRefresh(Set<Id> serviceResourceIds) {
        this.serviceResourceIds = serviceResourceIds;
        this.initLog();
    }

    /**
     * Process all ServiceResource sObjects with a GeoTabId__c value.
     */
    public GeoTabQueueableLocRefresh() {
        this.initLog();
    }

    /**
     * Standard async queueable execute method.
     * @param ctx The Queueable context.
     */
    public void execute(QueueableContext ctx) {
        this.jobId = ctx.getJobId();
        this.sJobId = jobId;
        performExecute();
    }

    /**
     *  1. Retrieve the service resources to process.
     *  2. Perform the callout to get DeviceStatusInfo.
     *  3. Process the results and match them up against Service Resource record by device.id = SR.GeoTabId__c.
     *  4. Perform update of lat/lng and activity status on ServiceResource sObject.
     *  5. Write final log if commanded by custom mdt.
     *
     *  Note: Queueable execute delegated here for easy call and log observation from anon apex.
     */
    public void performExecute() {

        this.log.Initiating_Job_Id__c = this.sJobId;
        this.iNumExeCalls++;
        String logMsg = '\n * Execute running with job id: ' + this.sJobId + '\n';
        this.log.Execution_Details__c += logMsg;

        Map<String, ServiceResource> mSrs = this.retrieveServiceResources();

        if (!mSrs.isEmpty()) {
            GeoTabDeviceStatusInfoResult statusInfo = performCallout();
            if(mdt.Log_Callout_Response__c) {
                Integer iSize = statusInfo.result != null ? statusInfo.result.size() : 0;
                logMsg = '\n* Number of DeviceStatusInfoRows: '+iSize +'\n';
                this.log.Execution_Details__c += logMsg;
                System.debug(LoggingLevel.DEBUG,logMsg);
            }
            this.processDeviceStatusInfo(statusInfo);
        } else {
            this.logNoResourceFound();
        }
        this.writeFinalLog(this.log);
        this.sendErrorEmail(this.sErrorsBody);
    }

    /**
     * Retrieves all DeviceStatusInfo results for all devices.
     *
     * Utilizes the Svc to perform a callout to the Vendor. Passes an instance of Accel_Application_Error__c and may
     * retrieve logging updates by ref if commanded by the custom mdt.
     *
     * @return a GeoTabDeviceStatusInfoResult (contains a list in the result property).
     */
    public GeoTabDeviceStatusInfoResult performCallout() {
        GeoTabSearchParams params = new GeoTabSearchParams(new GeoTabDeviceSearch() ); // No search params needed to get all!
        this.log.Execution_Details__c += '\n* Initiating callout: '+Datetime.now() + '\n';

        GeoTabDeviceStatusInfoResult statusInfo =
                GeoTabSvc.getDeviceStatusInfo(GeoTabUtils.generateId(),params,GeoTabSvc.DEFAULT_RESULTS_LIMIT,this.log);

        this.log.Execution_Details__c += '\n* Returned from callout: '+Datetime.now() +'\n';
        return statusInfo;
    }

    /**
     * Roll through the results from the callout and match the device id to ServiceResource.GeoTabId__c if possible.
     * updates the lastknownlat / lng and activitystatus and writes logs if commanded.
     *
     * @param statusInfo A GeoTabDeviceStatusInfoResult
     */
    public void processDeviceStatusInfo(GeoTabDeviceStatusInfoResult statusInfo) {
        Map<Id,ServiceResource> mSrsToUpd = new Map<Id,ServiceResource>();

        if(statusInfo.result != null) {
            Map<String,GeoTabDeviceStatusInfo> mDeviceInfos = new Map<String,GeoTabDeviceStatusInfo>();

            for(GeoTabDeviceStatusInfo deviceStatusInfo: statusInfo.result ) {
                if(deviceStatusInfo.device != null) {
                    mDeviceInfos.put(deviceStatusInfo.device.id, deviceStatusInfo);
                }
            }
            if(!mDeviceInfos.isEmpty()) {
                Map<Id,ServiceResource> mSrs = GeoTabSvc.retrieveServiceResourcesForUpdate(mDeviceInfos.keySet());

                for(ServiceResource sr : mSrs.values()) {
                    if(mDeviceInfos.containsKey(sr.GeotabId__c)) {
                        GeoTabDeviceStatusInfo device = mDeviceInfos.get(sr.GeotabId__c);
                        sr.LastKnownLatitude  = device.latitude;
                        sr.LastKnownLongitude = device.longitude;
                        sr.ActivityStatus__c = device.isDriving ? DRIVING_STATUS : STOPPED_STATUS;
                        //  @todo push FSL!
                        sr.LastKnownLocationDate = System.now();
                        mSrsToUpd.put(sr.Id,sr);
                    }
                }
                this.iTotalRecordsProcessed = mSrsToUpd.size();
                if(!mSrsToUpd.isEmpty()) {
                    this.updateServiceResources(mSrsToUpd);
                    if(!this.resourcesUpdated.isEmpty()) {
                        log.Execution_Details__c +='\n* ServiceResource Records Updated: '+
                                String.join(new List<String>(this.resourcesUpdated), ',');
                    }
                }
            }
        } else if (statusInfo.error != null) {
            this.sErrorsBody += statusInfo.error;
        }
    }

    /**
     * Perform a Database.update on passed ServiceResource sObjects. Branch off to any partial update errors if
     * necessary.
     *
     * @param mSrsToUpdate the Map of ServiceResource.Id ==> ServiceResource.
     */
    public void updateServiceResources(Map<Id,ServiceResource> mSrsToUpdate) {

        if(FORCE_PARTIAL_DML_EXCEPTION) {  //  Force to much data in field for unit testing.
            string sActivityStatus = '';
            for(Integer i =0; i< 300;i++) {
                sActivityStatus += i;
            }
            mSrsToUpdate.values()[0].ActivityStatus__c = sActivityStatus;
        }
        // FIRE THE UPDATE!!
        List<Database.SaveResult> results = Database.update(mSrsToUpdate.values(), false);

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results.get(i);
            if(sr.isSuccess()) {
                this.resourcesUpdated.add(sr.id);
                this.iTotalRecordsUpdated++;
            } else {
                this.processSaveErrors(results, mSrsToUpdate, i);
            }
        }
    }

    /**
     * Retrieves all service resources with a GeoTabId__c (or if serviceresource Ids passed in the constructor then
     * only those service resources with a GeoTabId__C
     *
     * @return A Map of ServiceResource.GeoTabId__c ==> ServiceResource.
     */
    public Map<String,ServiceResource> retrieveServiceResources() {
        Map<String,ServiceResource> m = new Map<String,ServiceResource>();
        List<ServiceResource> srs = GeoTabSvc.retrieveServiceResources(this.serviceResourceIds);
        if(!srs.isEmpty()) {
            for(ServiceResource sr : srs) {
               m.put(sr.GeotabId__c,sr);
            }
        }
        this.iTotalRecordsSelected = m.size();
        System.debug('\n* Total ServiceResources With GeoTabId found '+this.iTotalRecordsSelected +'\n');
        return m;
    }

    // =========   MOSTLY LOGGING AND ERROR HANDLING =========

    /**
     * Process an partial save error.
     *
     * @param results               The list of Database.SaveResults
     * @param mSrsToUpd             The original Map of ServiceResource.Id => ServiceResource sObject that was updated.
     * @param idx                   The index of record being updated.
     */
    private void processSaveErrors(  List<Database.SaveResult> results, Map<Id, ServiceResource> mSrsToUpd, Integer idx) {

        this.iTotalRecordsFailed++;
        String errorMsg = '';
        Id srId = mSrsToUpd.values().get(idx).Id;

        for (Database.Error error : results.get(idx).getErrors()) {
            errorMsg += srId + ',' + error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
            System.debug(LoggingLevel.ERROR, mSrsToUpd.values().get(idx).Id + ' - ' + errorMsg);
        }
        mFailedUpdates.put(srId, errorMsg);
    }

    /**
     * Log no resources found.
     */
    private void logNoResourceFound() {
        String logMsg = '\n* WARNING No Service Resources found with GeoTabId__c populated!\n';
        this.log.Stack_Trace__c += logMsg;
        sErrorsBody += logMsg;
        System.debug(LoggingLevel.WARN,logMsg);
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
        log.Initiating_Job_Id__c = this.sJobId;

        this.log = log;
    }

    /**
     * Writes job level totals.
     * @param log The current Accel_Application_error__c log in ctx.
     */
    private void writeFinalLog(Accel_Application_Error__c log) {
        String errors = '';

        if (log != null && (this.logFailedRecordIds != null || (mdt.Log_Callout_Request__c || mdt.Log_Callout_Response__c))) {

            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of Queueable Id= ' + this.sJobId + '\n';
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

                    log.Stack_Trace__c += '\n* Failed ServiceResource Ids ....\n';
                    log.Stack_Trace__c += allErrorIds;
                    log.Stack_Trace__c += '\n\n* Failure Messages ....';
                    for (String msg : mFailedUpdates.values()) {
                        log.Stack_Trace__c += '\n' + msg;
                    }
                    errors = log.Stack_Trace__c;
                    this.sErrorsBody = errors;
                } else {
                    System.debug(LoggingLevel.ERROR, '---> failed update record IDs:' + allErrorIds);
                }
            }

            if (log.Total_Updates_Failed__c == 0) {
                if(String.isBlank(this.sErrorsBody)) {
                    log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_SUCCESS;
                } else {
                    log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_FAILED;
                }
            } else if (log.Total_Updates_Failed__c > 0 && log.Total_Records_Updated__c > 0) {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_PARTIAL_SUCCESS;
            } else {
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_FAILED;
            }
            if(String.isNotBlank(log.Execution_Details__c)) {
                if(log.Execution_Details__c.length() >= 131000) {
                    log.Execution_Details__c = log.Execution_Details__c.left(131000);
                }
            }
            insert log;
        }
        String msg ='\n\n* Total records updated: '+log.Total_Records_Updated__c;
        System.debug(msg);
    }

    /**
     * @param sErrors  A String of error messages.
     */
    @TestVisible
    private void sendErrorEmail(String sErrors) {

        String msg = '\n\n* sendErrorEmail: mdt Emails = '+mdt.Error_Email_Addresses__c;
        System.debug(LoggingLevel.WARN,msg);
        msg = '\n\n* sendErrorEmail: Body = '+sErrors;
        System.debug(LoggingLevel.WARN,msg);

        if(String.isNotBlank(mdt.Error_Email_Addresses__c) && String.isNotBlank(sErrors)) {

            Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
            String instanceName = [select InstanceName from Organization limit 1].InstanceName;
            List<String> emailAddys = mdt.Error_Email_Addresses__c.split(',');

            String subject = EMAIL_SUBJ;

            String body = '<b><span style="color:red">Errors Occurred with GeoTab GPS Service Resource Processing.</span></b><br/>';
            body +='Please click the following link to access the log for more details: ';
            body += '<a href="'+log.External_Record_Link__c+'">View '+log.Name+'</a><br/>';
            body += '<br/>';

            if(FORCE_PARTIAL_DML_EXCEPTION) {
                body += '<b>Note:</b> This Error was forced by the client via setting FORCE_PARTIAL_DML_EXCEPTION to true.<br/><br/>';
            }

            body += '<b>Execution Date: </b>'+Datetime.now().format()+'<br/>';
            body += '<b>Instance Name: <b>'+instanceName+'<br/>';
            body += '<b>Errors:</b>';
            sErrors = sErrors.replaceAll('\n','<br/>');
            body += sErrors;

            EmailSvc.sendEmail( emailAddys,null,subject,body,null,OWA_EMAIL_ADDY );
        }
    }

}