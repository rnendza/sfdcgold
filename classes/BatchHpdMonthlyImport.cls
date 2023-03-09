/**
 * The goal of this to to take the place of process that used to occur in a Trigger on Hold_Per_Day__c
 * which evaluated records upon monthly imports and tagged the associated Account records with the most
 * recent hpd lookup field value.
 *
 * Do NOT fire with a batch of say over 40 as that will update accounts 40 at time and that is
 * about the most we can at this point (03_02_2020)
 */
global class BatchHpdMonthlyImport implements Database.Batchable <SObject>, Database.Stateful {

    public final static String OWA_EMAIL_ADDY = 'crm@accelentertainment.com';
    global final static String MONTHLY_HPD_DEV_NAME = 'Monthly_HPD';
    public final static String ACCT_AGGREGATION_DEVNAME = 'HPD_Account_Aggregation';

    private HPD_Total_Setting__mdt hpdTotalSetting;
    private Boolean commitTrans = false;
    private Integer batchSize;
    private Integer totalRecordsModified = 0;
    private Integer batchesRun = 0;
    private String formattedLocalStartTimeString;
    private String formattedLocalEndTimeString;
    private List<String> recipientUserEmails;
    private String asyncJobName;
    private String className;
    private Boolean fakeAccountException = false;
    private Set<Id> accountIdsUpdated  = new Set<Id>();
    private List<String> accountTypes;
    private List<UpdateResult> updateResultsSuccess;
    private List<UpdateResult> updateResultsErrors;
    private String defaultUserEmail = 'rick@chicagosalesforceconsulting.com';
    private String exportFileName = 'Monthly_Most_Recent_Hpd_Update';  //  ultimately prefixed and suffixed

    /**
     * All roads lead back here. Primary constructor.
     *
     * @param recipientUserEmails   A list of email addresses to send results to.
     * @param bCommitTrans          Set to true if we want to commit / otherwise false.
     * @param sAsyncJobName         A unique name to store in custom Async_Apex__c object for result logging.
     */
    global BatchHpdMonthlyImport(List<String> recipientUserEmails, Boolean bCommitTrans, String sAsyncJobName) {
        this.commitTrans = bCommitTrans;
        this.recipientUserEmails = recipientUserEmails;
        this.asyncJobName = sAsyncJobName;
        this.className = BatchHpdMonthlyImport.class.getName();
        if(this.asyncJobName == null) {
            this.asyncJobName = BatchHpdMonthlyImport.class.getName() + '_' + System.now();
        }
        if(this.recipientUserEmails == null) {
            this.recipientUserEmails = new List<String> {defaultUserEmail};
        }
        this.updateResultsSuccess = new List<UpdateResult>();
        this.updateResultsErrors = new List<UpdateResult>();
    }

    //  =========  Merely a bunch of overloads to allow for more client flexibility. ============

    // ---- note the below constructor is essentially for test only to force an exception as we cannot
    // ---- cannot force the val exception that we are most likely to run into (bad old data not abiding by new val rules)
    global BatchHpdMonthlyImport(   List<String> recipientUserEmails, Boolean bCommitTrans, String sAsyncJobName,
                                    Boolean fakeAccountException) {

        this( recipientUserEmails,bCommitTrans,sAsyncJobName );
        this.fakeAccountException = fakeAccountException;
    }
    /**
     * @param recipientUserEmails   A list of email addresses to send results to.
     * @param bCommitTrans          Set to true if we want to commit / otherwise false.
     */
    global BatchHpdMonthlyImport(List<String> recipientUserEmails, Boolean bCommitTrans) {
        this( recipientUserEmails, bCommitTrans, null );
    }
    /**
     * @param recipientUserEmails    list of email addresses to send results to.
     */
    global BatchHpdMonthlyImport(List<String> recipientUserEmails) {
        this( recipientUserEmails, true );
    }
    global BatchHpdMonthlyImport() {
        this( null );
    }

    //---------------------------------------------------------------------------------------------------------------

    /**
     *
     * Find all possible account ids for the given account aggregation types stored in the custom settings.
     *
     * @param bc
     * @return
     */
    global Database.QueryLocator start( Database.BatchableContext bc) {
        formattedLocalStartTimeString = Datetime.now().format();
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(ACCT_AGGREGATION_DEVNAME);
        this.accountTypes =  hpdTotalSetting.HPD_Account_Types__c.split(',');

        return Database.getQueryLocator([
                SELECT  Id
                FROM    Account
                WHERE   Type IN :accountTypes
        ]);
    }

    /**
     * Roll through the batch of account Ids and preform an aggregate query to obtain the latest monthly
     * hpd data.. In general this batch size should be kept small as we are always in danger of cpu time
     * when we update account. (I do believe we have 6x the limits in this batch job though however
     * automation will continue to get slapped on Account with little or no concern of performance so just
     * to be safe for the future.
     *
     * Note: query rows must be limited to 50k here including god knows what else is run upon update of account.
     *
     * @param bc
     * @param scope
     */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        if (batchSize == NULL || scope.size() > batchSize) batchSize = scope.size();
        this.batchesRun ++;

        Set<Id> accountIdsToProcess = new Set<Id>();
        for (SObject sObj : scope) {
            accountIdsToProcess.add(sObj.Id);
        }
        List<Account> accounts = [
                SELECT Id, Name, (
                        SELECT   Id, Name, Date__c
                        FROM     Holds_Per_Day__r
                        WHERE    RecordType.DeveloperName  =  :MONTHLY_HPD_DEV_NAME
                        AND      Account__c                  IN :accountIdsToProcess
                        ORDER By Date__C DESC
                        LIMIT 1
                )
                FROM Account
                WHERE Id In :accountIdsToProcess
        ];

        Map<Id, Hold_Per_Day__c> mSourceAccountId_SourceHpd = new Map<Id, Hold_Per_Day__c>();

        for(Account account : accounts) {
            this.parseResults(mSourceAccountId_SourceHpd, account);
        }

        if(!mSourceAccountId_SourceHpd.isEmpty()) {
            List<Account> accountsToUpd = [
                    SELECT Id, Name, Most_Recent_Hold_Per_Day__c
                    FROM Account
                    WHERE Id IN :mSourceAccountId_SourceHpd.keySet()
            ];
            for (Account account : accountsToUpd) {
                if (mSourceAccountId_SourceHpd.containsKey(account.Id)) {
                    Hold_Per_Day__c mostRecentHpd = (Hold_Per_Day__c) mSourceAccountId_SourceHpd.get(account.Id);
                    account.Most_Recent_Hold_Per_Day__c = mostRecentHpd.Id;
                }
            }
            //=========  Force an Exception in TEST CTX so we can test partial commit
            if (Test.isRunningTest() && fakeAccountException) {
                for (Integer i = 0; i < accountsToUpd.size() / 2; i++) {
                    Account account = accountsToUpd[i];
                    account.Id = null;
                }
            }
            updateAccounts(accountsToUpd);
        }
    }
    /**
     * Perform partial commits on whatever accounts that we have.. store the successful ids for reporting in the finish
     * method, store exceptions as well for reporting the finish method. Roll back if the client told us to (ie
     * they are just testing)
     *
     * @param accountsToUpd
     */
    @TestVisible
    private void updateAccounts(List<Account> accountsToUpd) {
        Savepoint sp = Database.setSavepoint();
        List<Database.SaveResult> srs = Database.update(accountsToUpd, false);

        for (Integer i = 0; i < accountsToUpd.size(); i++) {
            Database.SaveResult sr = srs[i];
            Account origAccount = accountsToUpd[i];
            if (!sr.isSuccess()) {
                UpdateResult ur = new UpdateResult(origAccount);
                for (Database.Error err : sr.getErrors()) {
                    ur.dbErrors.add(new CustomDbError(err) );
                }
                updateResultsErrors.add(ur);
            } else {
                accountIdsUpdated.add(sr.getId());
                totalRecordsModified ++;
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
        if(job != null) {
            job = AsyncSvc.updateJobStatus(asyncJobName, 'Completed', 'Job is 100% done');
        }
        List<String> toAddresses = this.recipientUserEmails;

        String subject = 'Accel SFDC - Most Recent HPD Update Completed - ';
        subject += totalRecordsModified + ' Record';
        if (totalRecordsModified > 1) subject += 's';
        subject += ' successfully updated';

        String body = buildEmailHtmlContent();
        List<Messaging.EmailFileAttachment> attachments = buildEmailAttachments();

        EmailSvc.sendEmail(toAddresses, null, subject, body, attachments, OWA_EMAIL_ADDY);
    }

    public class UpdateResult {

        Account account  {get;set;}
        List<CustomDbError> dbErrors {get;set;}

        public UpdateResult(Account account) {
            this.account    = account;
            this.dbErrors   = new List<CustomDbError>();
        }
    }

    public class CustomDbError {

        List<String>    errorFields     {get;set;}
        String          errorMsg        {get;set;}
        StatusCode      errorStatusCode {get;set;}

        public CustomDbError(Database.Error dbError) {
            this.errorFields        = dbError.fields;
            this.errorMsg           = dbError.getMessage();
            this.errorStatusCode    = dbError.getStatusCode();
        }
    }

    @TestVisible
    private void buildSuccessUpdateInfo() {
        Map<Id, Account> accountsUpdated = new Map<Id, Account>([
                SELECT  Id, Name, Most_Recent_Hold_Per_Day__c, Most_Recent_Hold_Per_Day__r.Name,
                        Most_Recent_Hold_Per_Day__r.Date__c
                FROM    Account
                WHERE   Id IN :accountIdsUpdated
        ]);
        if(!accountIdsUpdated.isEmpty()) {
            for(Account account : accountsUpdated.values()) {
                UpdateResult urSuccess = new UpdateResult(account);
                updateResultsSuccess.add(urSuccess);
            }
        }
    }
    // ------  Random util methods ---------------------------------
    private void parseResults( Map<Id,Hold_Per_Day__c> mSourceAccountId_SourceHpd, Account account) {

        Id accountId = account.Id;
        String accountName = account.Name;
        List<Hold_Per_Day__c> latestHpds = account.Holds_Per_Day__r;

        if(latestHpds != null && !latestHpds.isEmpty()) {

            Hold_Per_Day__c latestHpd = latestHpds[0];

            Id latestHpdId = latestHpd.Id;
            Date latestHpdDate = latestHpd.Date__c;
            String latestHpdName = latestHpd.Name;

            Hold_Per_Day__c hpd = new Hold_Per_Day__c (
                    Id=latestHpdId, Date__c = latestHpdDate, Machine_Model__c = latestHpdName,
                    Account__r = new Account (
                            Id=accountId,
                            Name=accountName
                    )
            );
            mSourceAccountId_SourceHpd.put( accountId, hpd);
        }
    }

    @TestVisible
    private List<Messaging.EmailFileAttachment> buildEmailAttachments() {

        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();

        String csvSuccess =  this.buildSuccessCsvString();
        String csvSuccessName = this.totalRecordsModified+'__SUCCESSES_'+exportFileName+'_'+Datetime.now()+'.csv';
        Blob csvSuccessBlob = Blob.valueOf(csvSuccess);
        Messaging.EmailFileAttachment csvSuccessAttachment = new Messaging.EmailFileAttachment();
        csvSuccessAttachment.setFileName(csvSuccessName);
        csvSuccessAttachment.setBody(csvSuccessBlob);
        attachments.add(csvSuccessAttachment);

        String csvErrors =  this.buildErrorCsvString();
        String csvErrorsName = this.updateResultsErrors.size()+'__ERRORS_'+exportFileName+'_'+Datetime.now()+'.csv';
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
        if(commitTrans) {
            msg += '<span style="color:green"><b> ** Transaction was committed! ** </b></span><br/>';
        } else  {
            msg += '<span style="color:red"><b>NOTE!  Transaction was intentionally rolled back due to a user supplied parameter.</b>&nbsp;&nbsp;</span><br/>';
            msg += '<span>The results would have been the following if the transaction was committed:</span>';
        }
        msg += '<br/><b>Summary:</b><br/>';
        msg += '<br/>Total # of Account Updated: <b>' +totalRecordsModified + '</b>';
        msg += '<br/>Total # of Errors: <b>'+numErrors + '</b>';
        msg += '<br/>Batch Apex Class: <b>'+this.className+'</b>';
        msg += '<br/>Batch Size: <b>' +batchSize + '</b>';
        msg += '<br/>Number of Batches Run: <b>'+ batchesRun+ '</b>';
        msg += '<br>Recipient Email Addresses: <b>'+recipientUserEmails+'</b>';
        msg += '<br>Commit: <b>'+commitTrans+'</b>';
        msg += '<br/>Org Base URL: <b>' +baseUrl + '</b>';
        msg += '<br/>Start Time: <b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time: <b> ' + formattedLocalEndTimeString + '</b>';
        msg += '<br/><hr>';

        msg += '<br/><b>Pseudo:</b><br/>';
        msg += '<ul>';
        msg += '<li>In the start method. select all accounts of types: '+this.accountTypes + '</li>';
        msg += '<li>In the execute method run an aggregate query select max Hold_per_day__c.Date of monthly hpds</li>';
        msg += '<li>In the execute method Set Account.Most_Recent_Hold_Per_Day__c commit as many as possible</li>';
        msg += '<li>In the Finish method send out an email with html and csv success and failure results.</li>';
        msg += '<li>Use a toggle of commitTrans so we can fully test this.</li>';
        msg += '</ul>';

        if(!commitTrans) {
            msg += '<br/>';
            msg +=' <span style="color:red"> ** Note **  the attached data does not exist in the target org as it was rolled back. It is example of what would exist on a commit!!!</span>';
        }
        return msg;
    }

    @TestVisible
    private String buildSuccessCsvString() {
        String header = 'Account Id,Account Name,Most Recent HPD Id,Most Recent HPD Name,Most Recent HPD Date\n';
        String finalString = header ;
        for (UpdateResult ur : this.updateResultsSuccess) {
            String recordString =
                    '"' + ur.account.Id + '","' + ur.account.Name + '","' + ur.account.Most_Recent_Hold_Per_Day__c
                            + '","' + ur.account.Most_Recent_Hold_Per_Day__r.Name + '","'
                            + ur.account.Most_Recent_Hold_Per_Day__r.Date__c + '"\n';
            finalString += recordString;
        }
        return finalString;
    }

    @TestVisible
    private String buildErrorCsvString() {
        String header = 'Account Id,Account Name,Error Status Code,Error Message,Error Fields\n';
        String finalString = header ;
        for ( UpdateResult ur : this.updateResultsErrors ) {
            if( ur.dbErrors != null && ! ur.dbErrors.isEmpty() ) {
                CustomDbError firstCustomDbError = ur.dbErrors[0];
                String recordString =
                        '"' + ur.account.Id + '","' + ur.account.Name + '","'
                                + firstCustomDbError.errorStatusCode + '","'
                                + firstCustomDbError.errorMsg + '","'
                                + firstCustomDbError.errorFields
                                + '"\n';
                finalString += recordString;
            }
        }
        return finalString;
    }

    public class BatchException extends Exception {}
}