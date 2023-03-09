/**
 * Requirements:
 *
 * Account fields to update every night:SweepstakesCurrOptIn__c,SweepstakesCurrCostShare__c
 *
 * Default value for these fields are false and $0, they need to be swapped to true and
 * {marketing-request->Location_Cost_Share_Amount__c} (should be $50 for these) if they meet the criteria based off
 * the marketing objects being analyzed each night:
 *  https://accelentertainment.lightning.force.com/lightning/r/Report/00O1I000006RrpAUAS/view?queryScope=userFolders
 *
 * Look at:
 * - marketing requests of record type ‘Sweepstakes’
 * - the marketing request object needs a Product with Accel Name ‘AE Player’
 * - the cost_share_sent_to_accounting field on the marketing request needs to not be null
 * - if an account matches these criteria -> set its 2 sweepstakes fields above to the appropriate true and $ values
 * - if an account DOES NOT match these criteria anymore (someone went in and changed the marketing request to indicate
 *   location is not longer a participant), and they previously had true/$ values set, false them out
 *
 *  General Flow --> Start (Query MR Reqs) --> Exec (process batch - query accounts - update accounts) --> Finish (write logs / Done)
 *
 * ==========================================================
 *  Sample adhoc execution:
 *  Integer iBatchSize = 50;
 *  Boolean bCommit = false, bLogExeMethod = true;
 *  Id scheduledJobId = null;
 *
 *  Database.executeBatch(new BatchSweepstakesLocUpdate(bCommit,iBatchSize,bLogExeMethod,scheduledJobId),iBatchSize);
 * ==========================================================
 *
 * @see BatchjobSvc
 * @see AppLogSvc
 * @see Batch_Job_Setting__mdt  (With dev name of BatchSweepstakesLocUpdate)
 * @see Accel_Application_Error__c  (Label = Accel Application Logs ie. the target sObject for logging)
 * @see https://accel-entertainment.monday.com/boards/942883797/pulses/1014836805
 *
 */
public class BatchSweepstakesLocUpdate implements Database.Batchable <SObject>, Database.Stateful {

    public static String jobName = 'BatchSweepstakesLocUpdate';
    public static String DEFAULT_PRODUCT_NAME       = 'AE Player Rewards (Sweepstakes)';
    public static String DEFAULT_MKTG_RT_DEV_NAME   = 'Sweepstakes';

    public Id jobId, scheduledJobId;

    private Boolean commitTrans = false;
    private Integer batchSize;

    //  Used for Unit Testing.
    @TestVisible private static Boolean FORCE_ALL_DML_EXCEPTION = false;
    @TestVisible private static Boolean FORCE_PARTIAL_DML_EXCEPTION = false;
    @TestVisible private static Boolean SEND_EMAIL_ON_FAIL = false;
    @TestVisible private static Boolean SEND_EMAIL_ON_COMPLETION = false;
    @TestVisible private static String  TEST_EMAIL_USERNAMES = '';

    //  This is primarily used if we want to limit real time testing. (Gov limit is 50 mil)
    public  static Integer RECORDS_TO_PROCESS_LIMIT = 49000000;

    //  Overwritten with custom metadata.
    public Set<String> marketingRecordTypesToProcess = new Set<String>{DEFAULT_MKTG_RT_DEV_NAME};
    public Set<String> marketingProductsToFind = new Set<String>{DEFAULT_PRODUCT_NAME};
    public Boolean logFailedRecordIds = true, logExeMethod = false, logSuccessfulRecordIds = false;
    public String  emailTemplateDevName = BatchjobSvc.DEFAULT_EMAIL_TEMPLATE;
    public Boolean sendEmailOnStatusFail = false, sendEmailOnJobCompletion = false;
    public Set<Id> emailWhoUserIds = new Set<Id>();

    //  Various internal stateful counters
    public Integer     iNumAccountsFailed = 0, iNumAccountsSetToOptIn = 0, iNumAccountsSetToOptOut = 0;
    public Integer     iTotalRecordsSelected = 0,iNumAccountsFound = 0,iNumAccountsUpdated = 0;
    public Integer     iTotalRecordsProcessed = 0;
    private Integer iNumExeCalls = 0;

    private Map<Id,Account> mSuccessfulUpdates  = new Map<Id,Account>();
    private Map<Id,String> mFailedUpdates      = new Map<Id,String>();

    //  Single log file for each nightly run which will be updated throughout the process.
    public Accel_Application_Error__c log;

    /**
     * Main constructor. Init a new log file and query for custom mdt.
     * Note these Params can read off custom metadata

     * @param bCommitTrans   True if the trans should be committed, false if rolled back.
     * @param iBatchSize     Mostly for log reporting purposes.
     * @param bLogExeMethod  Write logs for each execution of the execute method (if there are many records be careful!)
     * @param scheduledJobId The Id of the scheduled job that triggered this (if any)
     *
     * @see Batch_Job_Setting__mdt  (With dev name of BatchSweepstakesLocUpdate)
     */
    public BatchSweepstakesLocUpdate(Boolean bCommitTrans, Integer iBatchSize, Boolean bLogExeMethod,Id scheduledJobId) {

        this.batchSize = iBatchSize;                    //  Use a small number for cpu intensive objects if updating.
        this.scheduledJobId = scheduledJobId;
        this.logExeMethod = bLogExeMethod;              //  Only log the iterative exe method if a small amt of batches run.
        this.initLog();                                 //  Insert a log.
        this.setQueryFromMetadata();                    //  Query Metadata for params.
        this.commitTrans = bCommitTrans;
    }

    /**
     * We can really only get part of what we need here as we would rather return Account records for
     * update in the exec method but we can't as we are limited by sub query limitations.
     *
     * @param bc  The Batchable Context.
     * @return    A Database.QueryLocator of Marketing_Request__c sObject Results.
     *
     * @implNote
     * Cost_share_sent_to_accounting__c != NULL is evaluated upon update to the account.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
        this.jobId = bc.getJobId();
        log.Initiating_Job_Id__c = this.jobId;
        log.Execution_Details__c += '\n* Start Method - Batch Size Requested = '+batchSize ;
        AppLogSvc.updateLog(log);

        Database.QueryLocator ql = Database.getQueryLocator([
                SELECT  Id,Account__c,Location_Cost_Share_Amount__c,Location_Cost_Share_Amount_Rollup__c,
                        Cost_Share_Sent_To_Accounting__c,
                        Account__r.SweepstakesCurrCostShare__c, Account__r.SweepstakesCurrOptIn__c
                FROM    Marketing_Request__c
                WHERE   RecordType.DeveloperName         IN :marketingRecordTypesToProcess
                AND     Id IN
                (
                        SELECT  Marketing_Request__c
                        FROM    Marketing_Request_Products__c
                        WHERE   Product__r.Name IN      :marketingProductsToFind
                )
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT :RECORDS_TO_PROCESS_LIMIT
        ]);
        Integer totalResults = BatchjobSvc.findQueryLocatorSize(ql);
        log.Execution_Details__c += '\n* Total # of results in the Start Method Query: '+totalResults + '\n \n';
        AppLogSvc.updateLog(log);

        return ql;
    }

    /**
     * Query the accounts to update and update appropriate values per business rules,
     *
     * @param bc        The Batchable context.
     * @param scope     The Scope. ie a List of Marketing_Request__c sObjects queried in the start method.
     */
    public void execute(Database.BatchableContext bc, List<Marketing_Request__c> scope) {

        iNumExeCalls++;
        this.iTotalRecordsSelected += scope.size();

        //  Query the accounts associated with the marketing requests.
        Map<Id,Account> mAccountsByIds = queryAccounts(scope);

        if(logExeMethod) {
            Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
            log.Execution_Details__c += '\n* In #' + iNumExeCalls + ' execute of Batch ' + bc.getJobId()
                    + '.-->  # of marketing records in scope=' + scope.size() + '\n';
            log.Execution_Details__c += '* QueryAccounts() from queueable.  # of accounts found='+mAccountsByIds.size() + '\n';
            AppLogSvc.updateLog(log);
        }

        //  Update the accounts per business rules.
        if(!mAccountsByIds.isEmpty()) {
            Map<Id,List<Marketing_Request__c>> mrReqsByAccountId = mapMrReqsByAccountId(scope);
            List<Account> updateAccounts = updateAccounts(mAccountsByIds,mrReqsByAccountId);
            System.debug('----> updated accounts='+updateAccounts);
        }
    }

    /**
     * Update completion information on the log file in context.
     * @param bc   The Batchable context.
     */
    public void finish(Database.BatchableContext bc) {

        Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
        this.writeFinalLog(log);
        log = AppLogSvc.retrieveLog(log.Id);
        System.debug(LoggingLevel.INFO, '---> in finish of batch job:'+this.jobId + ' log is:'+log);
        System.debug(LoggingLevel.INFO, '---> Status = '+log.Overall_Job_Status__c + 'sendEmailOnJobCompletion='+
                this.sendEmailOnJobCompletion + ' sendEmailOnStatusFail='+this.sendEmailOnStatusFail);

        if(!this.sendEmailOnJobCompletion) {
            //  Only Send an Email when the Job Fails.
            if (log.Overall_Job_Status__c == 'Failed' && this.sendEmailOnStatusFail) {
                if (this.infoExistsToSendEmail()) {
                    List<Messaging.SendEmailResult> sendResults =
                            BatchjobSvc.sendEmail(log, this.emailWhoUserIds, this.emailTemplateDevName);
                    System.debug('---> email send results=' + sendResults) ;
                }
            }
        } else {
            //  Always send an email
            if(infoExistsToSendEmail()) {
                String dynaHtml = buildCustomHtml();
                EmailTemplate t = [ SELECT Id FROM EmailTemplate WHERE DeveloperName = :this.emailTemplateDevName];

                List<Messaging.SendEmailResult> sendResults =
                        BatchjobSvc.sendEmail(log, this.emailWhoUserIds, t.Id,dynaHtml);

                System.debug('---> email send results=' + sendResults) ;
            }
        }
    }

    /**
     * Query the account records using the account ids from the Marketing_Request__c sObjects queried
     *
     * @param marketingRequests  A List of Marketing_Request__c sObjects.
     * @return                   A Map of AccountId ==> Account sObj.
     */
    private Map<Id,Account> queryAccounts(List<Marketing_Request__c> marketingRequests) {

        Map<Id,Account> mAccountsByIds = new Map<Id,Account>();

        if(!marketingRequests.isEmpty()) {
            Map<Id,List<Marketing_Request__c>> mrReqsByAccountId = mapMrReqsByAccountId(marketingRequests);
            mAccountsByIds = new Map<Id,Account>([
                    SELECT Id,SweepstakesCurrCostShare__c,SweepstakesCurrOptIn__c
                    FROM   Account
                    WHERE  Id IN :mrReqsByAccountId.keySet()
                    AND    Id NOT IN : mSuccessfulUpdates.keySet()
            ]);
            this.iNumAccountsFound += mAccountsByIds.size();
        }
        System.debug('---->  accounts found in exec='+mAccountsByIds);
        return mAccountsByIds;
    }

    /**
     * Updates the accounts if necessary per business rules. Performs a partial commit and logs failed / successful
     * account Ids if necessary.
     *
     * @param accountsToUpdate      A map of AccountId ==> Account sObj.
     * @param mrReqsByAccountId     A map of AccountId ==> List of associated Marketing sObjects.
     *
     * @return                      A list of updated accounts.
     */
    private List<Account> updateAccounts(Map<Id,Account> accountsToUpdate, Map<Id,List<Marketing_Request__c>> mrReqsByAccountId) {

        Map<Id,Account> newAccountUpdates = new Map<Id,Account>();
        Integer iNumOptIn = 0, iNumOptOut = 0;

        for(Account account : accountsToUpdate.values()) {
            List<Marketing_Request__c> acctMRequests = mrReqsByAccountId.get(account.Id);

            if(!acctMRequests.isEmpty()) {

                Marketing_Request__c marketingRequest = acctMRequests[0];  //  Take the most recent if many.
                if(marketingRequest.Cost_Share_Sent_To_Accounting__c != null) {
                    if(!account.SweepstakesCurrOptIn__c) {
                        account.SweepstakesCurrOptIn__c = true;
                        account.SweepstakesCurrCostShare__c = marketingRequest.Location_Cost_Share_Amount__c;
                        iNumAccountsSetToOptIn++;
                        iNumOptIn ++;
                        iTotalRecordsProcessed++;
                        newAccountUpdates.put(account.Id,account);
                    }
                } else {
                    if(account.SweepstakesCurrOptIn__c) {
                        account.SweepstakesCurrOptIn__c = false;
                        account.SweepstakesCurrCostShare__c = 0;
                        iNumAccountsSetToOptOut++;
                        iNumOptOut ++;
                        iTotalRecordsProcessed++;
                        newAccountUpdates.put(account.Id,account);
                    }
                }
            }
        }

        if(!newAccountUpdates.isEmpty()) {

            Savepoint sp = Database.setSavepoint();
            //  Just here for Unit Testing so we can test a DML Error.
            if (FORCE_ALL_DML_EXCEPTION) {
                for (Account a : newAccountUpdates.values()) {
                    a.Type = 'BOGUS TYPE'; // force a restricted pl value error.
                }
            } else if (FORCE_PARTIAL_DML_EXCEPTION) {
                newAccountUpdates.values()[0].Type = 'BOGUS TYPE PARTIAL';
            }
            //  Fire an update using partial commits!
            List<Database.SaveResult> results = Database.update(newAccountUpdates.values(), false);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results.get(i);
                if (!sr.isSuccess()) {
                    processSaveError(results, sr, newAccountUpdates, i);
                } else {
                    Account account = newAccountUpdates.values().get(i);
                    mSuccessfulUpdates.put(account.Id, account);
                    iNumAccountsUpdated++;
                }
            }
            if(!commitTrans) {
                Database.rollback(sp);
            }
        } else {
            System.debug('---->  No account criteria to update. ie. the account data did not need to change based on the marketing request');
        }

        if(logExeMethod) {
            Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
            updateLog(log,iNumOptIn,iNumOptOut);
        }
        return accountsToUpdate.values();
    }

    /**
     * Process an partial save error (ie. error updating the account)
     *
     * @param results           The list of Database.SaveResults
     * @param sr                The Database.SaveResult that errored out.
     * @param accountsToUpdate  The original Map of AccountId => Account sObject that was updated.
     * @param idx               The index of record being updated.
     */
    private void processSaveError(  List<Database.SaveResult> results,Database.SaveResult sr,
            Map<Id,Account> accountsToUpdate, Integer idx ) {

        this.iNumAccountsFailed++;
        String errorMsg = '';
        Id accountId = accountsToUpdate.values().get(idx).Id;

        for (Database.Error error : results.get(idx).getErrors()) {
            errorMsg += accountId +','+error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
            System.debug(LoggingLevel.ERROR, accountsToUpdate.values().get(idx).Id + ' - ' + errorMsg);
        }
        mFailedUpdates.put(accountId, errorMsg);
    }

    /**
     * Take a list of Marketing request and put them in a map to associated them with their account id.
     *
     * @param marketingRequests A List of Marketing_Request__c sObjects.
     * @return                  A Map of AccountId ==> List<Marketing_Request__c>.
     */
    private Map<Id,List<Marketing_Request__c>> mapMrReqsByAccountId(List<Marketing_Request__c> marketingRequests) {

        Map<Id,List<Marketing_Request__c>> mrReqsByAccountId = new Map<Id,List<Marketing_Request__c>>();

        for(Marketing_Request__c mr : marketingRequests) {
            if(mr.Account__c != null) {
                if(!mrReqsByAccountId.containsKey(mr.Account__c)) {
                    mrReqsByAccountId.put(mr.Account__c, new List<Marketing_Request__c>{mr});
                } else {
                    List<Marketing_Request__c> existingMrReqs = mrReqsByAccountId.get(mr.Account__c);
                    existingMrReqs.add(mr);
                }
            }
        }
        System.debug(LoggingLevel.DEBUG,'Map of Mktg reqs by accountId='+mrReqsByAccountId);
        return mrReqsByAccountId;
    }

    /**
     * Sets start query parameters from Custom mdt if found, otherwise retains defaults.
     */
    private void setQueryFromMetadata() {

        Batch_Job_Setting__mdt mdt = BatchjobSvc.queryForMetadata(jobName);
        if (mdt != null) {
            if (mdt.Record_Types_to_Query__c != null) {
                this.marketingRecordTypesToProcess = new Set<String>(mdt.Record_Types_To_Query__c.split(','));
            }
            if (mdt.Product_Names_To_Query__c != null) {
                this.marketingProductsToFind = new Set<String>(mdt.Product_Names_To_Query__c.split(','));
            }
            if( mdt.Log_Failed_Record_Ids__c != null) {
                this.logFailedRecordIds = mdt.Log_Failed_Record_Ids__c;
            }
            if( mdt.Log_Successful_Record_Ids__c != null) {
                this.logSuccessfulRecordIds = mdt.Log_Successful_Record_Ids__c;
            }
            this.sendEmailOnStatusFail = mdt.Send_Email_on_Status_Failed__c;
            this.sendEmailOnJobCompletion = mdt.Send_Email_On_Job_Completion__c;

            if(this.sendEmailOnStatusFail || SEND_EMAIL_ON_FAIL || SEND_EMAIL_ON_COMPLETION || this.sendEmailOnJobCompletion) {
                String sUserNames = mdt.Usernames_to_email__c;
                this.sendEmailOnStatusFail = true;
                if(Test.isRunningTest() && (SEND_EMAIL_ON_FAIL || SEND_EMAIL_ON_COMPLETION ) && String.isNotBlank(sUserNames)) {
                    sUserNames = TEST_EMAIL_USERNAMES;
                    System.debug('----> in Unit Test Mode sUserNames='+sUserNames);
                }
                if(String.isNotBlank(sUserNames)) {
                    List<String> userNames = sUserNames.split(',');
                    Map<Id,User> mUsersByIds = new Map<Id,User>([SELECT Id FROM User WHERE UserName IN : userNames]);
                    if(!mUsersByIds.isEmpty()) {
                        this.emailWhoUserIds.addAll(mUsersByIds.keySet());
                    }
                } else {
                    this.sendEmailOnStatusFail = false;
                    this.sendEmailOnJobCompletion = false;
                }
            }

            if( mdt.Email_Template_Dev_Name__c != null) {
                this.emailTemplateDevName = mdt.Email_Template_Dev_Name__c;
            }
        }
        Accel_Application_Error__c log = AppLogSvc.retrieveLog(this.log.Id);
        if(log.Execution_Details__c == null) { log.Execution_Details__c = '';}

        log.Execution_Details__c+= '* Instantiating '+jobName+ '. Mdt=' +URL.getSalesforceBaseUrl().toExternalForm() +'/'+mdt.Id + '\n';
        AppLogSvc.updateLog(log);
    }

    /**
     * @return true if we have enough info in the custom mdt to send an email, otherwise false.
     */
    private Boolean infoExistsToSendEmail() {
        Boolean sendIt = false;
        sendIt = this.emailWhoUserIds != null && !this.emailWhoUserIds.isEmpty() && this.emailTemplateDevName != null;
        System.debug('---> enough info exists to send email? = '+sendIt);
        return sendIt;
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
        log.Scheduled_Job_Id__c = this.scheduledJobId;
        log.Batch_Size__c = this.batchSize;
        log.Execution_Details__c = ' ';

        insert log;
        this.log = log;
    }

    /**
     * Update the Accel_Application_Error__c sObject that is tracing this process (Log File)
     */
    private void updateLog(Accel_Application_Error__c log,Integer iBatchOptIn, Integer iBatchOptOut) {

        log.Execution_Details__c += '\n* # of accounts set to opt in to true : '+iBatchOptIn + '\n';
        log.Execution_Details__c += '* # of accounts set to opt in to false : '+iBatchOptOut + '\n';
        log.Total_Records_Processed__c = iBatchOptOut + iBatchOptOut;

        AppLogSvc.updateLog(log);
    }
    /**
     * Writes job level totals from the finish method.
     * @param log The current Accel_Application_error__c log in ctx.
     */
    private void writeFinalLog(Accel_Application_Error__c log) {

        if(log != null && log.Id != null) {
            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of Batch '+this.jobId + '\n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Updated__c = iNumAccountsUpdated;
            log.Total_Updates_Failed__c = iNumAccountsFailed;
            log.Total_Records_Processed__c = iTotalRecordsProcessed;
            log.Execution_Details__c += '* Total Marketing Records Selected = '+ iTotalRecordsSelected+ '\n';
            log.Execution_Details__c += '* Total Accounts Set to Opt In = ' + this.iNumAccountsSetToOptIn + '\n';
            log.Execution_Details__c += '* Total Accounts Set to Opt Out = ' + this.iNumAccountsSetToOptOut + '\n';
            log.Execution_Details__c += '* Total Accounts Attempted to Update = ' + log.Total_Records_Processed__c + '\n';
            log.Execution_Details__c += '* Total Accounts Updated = '+log.Total_Records_Updated__c + '\n';
            log.Execution_Details__c += '* Total Account Updates Failed = '+log.Total_Updates_Failed__c + '\n';

            if(iNumAccountsUpdated > 0) {

                String allIds = '';
                for(String accountId : mSuccessfulUpdates.keySet()) {
                    allIds +=  accountId + ',';
                }
                allIds = allIds.removeEnd(',');
                if(this.logSuccessfulRecordIds) {
                    log.Execution_Details__c += '\n* Updated Account Ids ....\n';
                    log.Execution_Details__c += allIds;
                } else {
                    System.debug(LoggingLevel.ERROR,'---> successful update record IDs:'+allIds);
                }
            }

            if(!mFailedUpdates.isEmpty()  ) {

                String allErrorIds = '';
                for(String accountId : mFailedUpdates.keySet()) {
                    allErrorIds +=  accountId + ',';
                }
                allErrorIds = allErrorIds.removeEnd(',');
                if(this.logFailedRecordIds) {
                    log.Stack_Trace__c += '\n* Failed Account Ids ....\n';
                    log.Stack_Trace__c += allErrorIds;
                    log.Stack_Trace__c += '\n* Failure Messages ....';
                    for (String msg : mFailedUpdates.values()) {
                        log.Stack_Trace__c += '\n' + msg;
                    }
                } else {
                    System.debug(LoggingLevel.ERROR,'---> failed update record IDs:'+allErrorIds);
                }
            }
            if(!commitTrans) {
                log.Execution_Details__c += '\nxxxxxxxxxx in FINISH -> TRANSACTION HAS BEEN ROLLED BACK PER USER REQUEST xxxxxxx\n';
                log.Overall_Job_Status__c = 'Rolled Back';
            } else {
                if(log.Total_Updates_Failed__c == 0) {
                    log.Overall_Job_Status__c = 'Success';
                } else if(log.Total_Updates_Failed__C > 0 && log.Total_Records_Updated__c > 0) {
                    log.Overall_Job_Status__c = 'Partial Success';
                } else {
                    log.Overall_Job_Status__c = 'Failed';
                }
            }
            AppLogSvc.updateLog(log);
        } else {
            System.debug(LoggingLevel.WARN, '---> in finish of batch job: LOG COULD NOT BE UPDATED!');
        }
    }

    /**
     * Add opt in / opt out info to the email template. 
     *
     * @return valid html to inject into body of the template
     */
    private String buildCustomHtml() {
        String html = '';
        html += '<table border="0" cellpadding="0" cellspacing="0" width="100%">';
        html += '<tbody>';
        html += '<tr>';
        html += '<td style="width:35%"><span style="font-size:12px;">Total Set to Opt In:</span></td>';
        html += '<td style="width:65%"><span style="font-size:12px;">' +this.iNumAccountsSetToOptIn+'</span></td>';
        html += '</tr>';
        html += '<tr>';
        html += '<td style="width:35%"><span style="font-size:12px;">Total Set to Opt Out:</span></td>';
        html += '<td style="width:65%"><span style="font-size:12px;">' +this.iNumAccountsSetToOptOut+'</span></td>';
        html += '</tr>';
        html += '</tbody>';
        html += '</table>';
        return html;
    }
}