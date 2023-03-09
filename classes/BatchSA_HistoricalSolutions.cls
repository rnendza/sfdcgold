global class BatchSA_HistoricalSolutions implements Database.Batchable <SObject>, Database.Stateful {

    public final static String OWA_EMAIL_ADDY = 'crm@accelentertainment.com';
    public final static Integer RECORDS_TO_PROCESS_LIMIT = 49000000;

    private Boolean commitTrans = false;
    private Integer batchSize;
    private Integer totalRecordsModified = 0;
    private Integer batchesRun = 0;
    private String formattedLocalStartTimeString;
    private String formattedLocalEndTimeString;
    private List<String> recipientUserEmails;
    private String asyncJobName;
    private String className;
    private Boolean fakeServiceAppointmentException = false;
    private Set<Id> serviceAppointmentIdsUpdated = new Set<Id>();
    private List<UpdateResult> updateResultsSuccess;
    public List<UpdateResult> updateResultsErrors;
    private String defaultUserEmail = 'rick@chicagosalesforceconsulting.com';
    private String exportFileName = 'SA_Historical_Solutions';  //  ultimately prefixed and suffixed

    private Set<String> solutionPlValues = new Set<String>();
    private Map<String, Solution__c> mSolutionsByName = new Map<String, Solution__c>();
    /**
     * All roads lead back here. Primary constructor.
     *
     * @param recipientUserEmails   A list of email addresses to send results to.
     * @param bCommitTrans          Set to true if we want to commit / otherwise false.
     * @param sAsyncJobName         A unique name to store in custom Async_Apex__c object for result logging.
     */
    global BatchSA_HistoricalSolutions(List<String> recipientUserEmails, Boolean bCommitTrans, String sAsyncJobName) {
        this.commitTrans = bCommitTrans;
        this.recipientUserEmails = recipientUserEmails;
        this.asyncJobName = sAsyncJobName;
        this.className = BatchSA_HistoricalSolutions.class.getName();
        if (this.asyncJobName == null) {
            this.asyncJobName = this.className + '_' + System.now();
        }
        if (this.recipientUserEmails == null) {
            this.recipientUserEmails = new List<String>{
                    defaultUserEmail
            };
        }
        this.updateResultsSuccess = new List<UpdateResult>();
        this.updateResultsErrors = new List<UpdateResult>();
        this.solutionPlValues = this.getSolutionPlValues();
        this.mSolutionsByName = this.getSolutionSObjects();
    }

    //  =========  Merely a bunch of overloads to allow for more client flexibility. ============

    /**
     * @param recipientUserEmails   A list of email addresses to send results to.
     * @param bCommitTrans          Set to true if we want to commit / otherwise false.
     */
    global BatchSA_HistoricalSolutions(List<String> recipientUserEmails, Boolean bCommitTrans) {
        this(recipientUserEmails, bCommitTrans, null);
    }
    /**
     * @param recipientUserEmails    list of email addresses to send results to.
     */
    global BatchSA_HistoricalSolutions(List<String> recipientUserEmails) {
        this(recipientUserEmails, false);
    }
    global BatchSA_HistoricalSolutions() {
        this(null);
    }

    /**
     * Unit testing only for Exceptions.
     *
     * @param recipientUserEmails
     * @param bCommitTrans
     * @param sAsyncJobName
     * @param bFakeException
     */
    global BatchSA_HistoricalSolutions(List<String> recipientUserEmails, Boolean bCommitTrans, String sAsyncJobName,
        Boolean bFakeException) {
        this (recipientUserEmails, bCommitTrans, sAsyncJobName);
        this.fakeServiceAppointmentException = bFakeException;
    }
    /**
     *
     *
     * @param bc
     * @return
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        formattedLocalStartTimeString = Datetime.now().format();
        return Database.getQueryLocator([
                SELECT  Id,Solution__c, Accel_Solution__c, Accel_Solution__r.Name,
                        AppointmentNumber
                FROM    ServiceAppointment
                WHERE   Accel_Solution__c   = NULL
                AND     Solution__c         != NULL
                LIMIT   :RECORDS_TO_PROCESS_LIMIT
        ]);
    }

    /**
     *
     * @param bc
     * @param scope
     */
    global void execute(Database.BatchableContext bc, List<ServiceAppointment> scope) {
        if (batchSize == null || scope.size() > batchSize) batchSize = scope.size();
        this.batchesRun++;

        List<ServiceAppointment> sasToUpd = new List<ServiceAppointment>();
        for (ServiceAppointment sa : scope) {
            Solution__c solution = mSolutionsByName.get(sa.Solution__c);
            if (solution != null) {
                sa.Accel_Solution__c = solution.Id;
                sasToUpd.add(sa);

                //--- TEST ONLY
                if(fakeServiceAppointmentException) {
                    sa.Id = null;
                }
            }
        }
        updateServiceAppointments(sasToUpd);
    }
    /**
     * Perform partial commits on whatever accounts that we have.. store the successful ids for reporting in the finish
     * method, store exceptions as well for reporting the finish method. Roll back if the client told us to (ie
     * they are just testing)
     *
     * @param accountsToUpd
     */
    @TestVisible
    private void updateServiceAppointments(List<ServiceAppointment> serviceAppointments) {
        Savepoint sp = Database.setSavepoint();
        List<Database.SaveResult> srs = Database.update(serviceAppointments, false);

        for (Integer i = 0; i < serviceAppointments.size(); i++) {
            Database.SaveResult sr = srs[i];
            ServiceAppointment sa = serviceAppointments[i];
            if (!sr.isSuccess()) {
                UpdateResult ur = new UpdateResult(sa);
                for (Database.Error err : sr.getErrors()) {
                    ur.dbErrors.add(new CustomDbError(err));
                }
                updateResultsErrors.add(ur);
            } else {
                serviceAppointmentIdsUpdated.add(sr.getId());
                totalRecordsModified++;
            }
        }
        if (!commitTrans) {
            System.debug(LoggingLevel.WARN, 'xxx  Rolling Back Transactions   xxxx');
            Database.rollback(sp);
        }
    }
    /**
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = Datetime.now().format();
        buildSuccessUpdateInfo();

        Async_Job__c job = AsyncSvc.retrieveAsyncJob(asyncJobName);
        if (job != null) {
            job = AsyncSvc.updateJobStatus(asyncJobName, 'Completed', 'Job is 100% done');
        }
        List<String> toAddresses = this.recipientUserEmails;

        String subject = 'Accel SFDC - Historical Solutions Update Completed - ';
        subject += totalRecordsModified + ' Record';
        if (totalRecordsModified > 1) subject += 's';
        subject += ' successfully updated';

        String body = buildEmailHtmlContent();
        List<Messaging.EmailFileAttachment> attachments = buildEmailAttachments();

        EmailSvc.sendEmail(toAddresses, null, subject, body, attachments, OWA_EMAIL_ADDY);
    }

    public class UpdateResult {

        ServiceAppointment serviceAppointment { get; set; }
        List<CustomDbError> dbErrors { get; set; }

        public UpdateResult(ServiceAppointment serviceAppointment) {
            this.serviceAppointment = serviceAppointment;
            this.dbErrors = new List<CustomDbError>();
        }
    }

    public class CustomDbError {

        List<String> errorFields { get; set; }
        String errorMsg { get; set; }
        StatusCode errorStatusCode { get; set; }

        public CustomDbError(Database.Error dbError) {
            this.errorFields = dbError.fields;
            this.errorMsg = dbError.getMessage();
            this.errorStatusCode = dbError.getStatusCode();
        }
    }
    //---------------------------------------------------------------------------------------------------------------
    public Set<String> getSolutionPlValues() {
        List<Schema.PicklistEntry> plEntries = ServiceAppointment.Solution__c.getDescribe().getPicklistValues();
        Set<String> plValues = new Set<String>();
        for (Schema.PicklistEntry plEntry : plEntries) {
            plValues.add(plEntry.getLabel());
        }
        return plValues;
    }

    public Map<String, Solution__c> getSolutionSObjects() {
        Map<Id,Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                SELECT Id,Name
                FROM Solution__c
        ]);
        Map<String, Solution__c> mSolutionsByName = new Map<String, Solution__c>();
        for (Solution__c solution : mSolutionsByIds.values()) {
            mSolutionsByName.put(solution.Name, solution);
        }
        return mSolutionsByName;
    }

    @TestVisible
    private void buildSuccessUpdateInfo() {
        Map<Id, ServiceAppointment> serviceAppointmentsByIds = new Map<Id, ServiceAppointment>([
                SELECT Id, AppointmentNumber, Solution__c, Accel_Solution__c, Accel_Solution__r.Name
                FROM ServiceAppointment
                WHERE Id IN :serviceAppointmentIdsUpdated
        ]);
        if (!serviceAppointmentsByIds.isEmpty()) {
            for (ServiceAppointment sa : serviceAppointmentsByIds.values()) {
                UpdateResult urSuccess = new UpdateResult(sa);
                updateResultsSuccess.add(urSuccess);
            }
        }
    }
    // ------  Random util methods ---------------------------------

    @TestVisible
    private List<Messaging.EmailFileAttachment> buildEmailAttachments() {

        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

        String csvSuccess = this.buildSuccessCsvString();
        String csvSuccessName = this.totalRecordsModified + '__SUCCESSES_' + exportFileName + '_' + Datetime.now() + '.csv';
        Blob csvSuccessBlob = Blob.valueOf(csvSuccess);
        Messaging.EmailFileAttachment csvSuccessAttachment = new Messaging.EmailFileAttachment();
        csvSuccessAttachment.setFileName(csvSuccessName);
        csvSuccessAttachment.setBody(csvSuccessBlob);
        attachments.add(csvSuccessAttachment);

        String csvErrors = this.buildErrorCsvString();
        String csvErrorsName = this.updateResultsErrors.size() + '__ERRORS_' + exportFileName + '_' + Datetime.now() + '.csv';
        Blob csvErrorsBlob = Blob.valueOf(csvErrors);
        Messaging.EmailFileAttachment csvErrorsAttachment = new Messaging.EmailFileAttachment();
        csvErrorsAttachment.setFileName(csvErrorsName);
        csvErrorsAttachment.setBody(csvErrorsBlob);
        attachments.add(csvErrorsAttachment);

        return attachments;
    }

    @TestVisible
    private String buildEmailHtmlContent() {
        String msg = '';
        Integer numErrors = updateResultsErrors.size();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        msg += '<br/>If you are receiving this email, it is because your email address was added to view the results of this batch job<br/><br/>';
        if (commitTrans) {
            msg += '<span style="color:green"><b> ** Transaction was committed! ** </b></span><br/>';
        } else {
            msg += '<span style="color:red"><b>NOTE!  Transaction was intentionally rolled back due to a user supplied parameter.</b>&nbsp;&nbsp;</span><br/>';
            msg += '<span>The results would have been the following if the transaction was committed:</span>';
        }
        msg += '<br/><b>Summary:</b><br/>';
        msg += '<br/>Total # of Service Appointments Updated: <b>' + totalRecordsModified + '</b>';
        msg += '<br/>Total # of Errors: <b>' + numErrors + '</b>';
        msg += '<br/>Batch Apex Class: <b>' + this.className + '</b>';
        msg += '<br/>Batch Size: <b>' + batchSize + '</b>';
        msg += '<br/>Number of Batches Run: <b>' + batchesRun + '</b>';
        msg += '<br>Recipient Email Addresses: <b>' + recipientUserEmails + '</b>';
        msg += '<br>Records Processed Limit: <b><span color="orange">' + RECORDS_TO_PROCESS_LIMIT+ '</span></b>';
        msg += '<br>Commit: <b>' + commitTrans + '</b>';
        msg += '<br/>Org Base URL: <b>' + baseUrl + '</b>';
        msg += '<br/>Start Time: <b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time: <b> ' + formattedLocalEndTimeString + '</b>';
        msg += '<br/><hr>';

        msg += '<br/><b>Pseudo:</b><br/>';
        msg += '<ul>';
//        msg += '<li>In the start method. select all accounts of types: '+this.accountTypes + '</li>';
//        msg += '<li>In the execute method run an aggregate query select max Hold_per_day__c.Date of monthly hpds</li>';
//        msg += '<li>In the execute method Set Account.Most_Recent_Hold_Per_Day__c commit as many as possible</li>';
//        msg += '<li>In the Finish method send out an email with html and csv success and failure results.</li>';
//        msg += '<li>Use a toggle of commitTrans so we can fully test this.</li>';
        msg += '</ul>';

        if (!commitTrans) {
            msg += '<br/>';
            msg += ' <span style="color:red"> ** Note **  the attached data does not exist in the target org as it was rolled back. It is example of what would exist on a commit!!!</span>';
        }
        return msg;
    }

    @TestVisible
    private String buildSuccessCsvString() {
        String header = 'Service Appointment Id,Service Appointment #,Searchable Solution Id, Searchable Solution Name,Solution PL Value\n';
        String finalString = header ;
        for (UpdateResult ur : this.updateResultsSuccess) {
            String recordString =
                    '"' + ur.serviceAppointment.Id + '","' + ur.serviceAppointment.AppointmentNumber + '","'
                            + ur.serviceAppointment.Accel_Solution__c
                            + '","' + ur.serviceAppointment.Accel_Solution__r.Name + '","'
                            + ur.serviceAppointment.Solution__c + '"\n';
            finalString += recordString;
        }
        return finalString;
    }

    @TestVisible
    private String buildErrorCsvString() {
        String header = 'Service Appointment Id,Service Appointment #,Error Status Code,Error Message,Error Fields\n';
        String finalString = header ;
        for (UpdateResult ur : this.updateResultsErrors) {
            if (ur.dbErrors != null && !ur.dbErrors.isEmpty()) {
                CustomDbError firstCustomDbError = ur.dbErrors[0];
                String recordString =
                        '"' + ur.serviceAppointment.Accel_Solution__c + '","' + ur.serviceAppointment.AppointmentNumber + '","'
                                + firstCustomDbError.errorStatusCode + '","'
                                + firstCustomDbError.errorMsg + '","'
                                + firstCustomDbError.errorFields
                                + '"\n';
                finalString += recordString;
            }
        }
        return finalString;
    }
}