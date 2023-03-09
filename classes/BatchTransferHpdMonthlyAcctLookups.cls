/**
 * Currently only supports Monthly. could probably never do this in apex in dailies as it's just too much data to agg.
 *
 * While understanding this will probably 1 account at time, ya never know in the future.  Regardless
 * You probably want to set a pretty low batch size here as Account is currently a pretty fragile object.
 *
 *
 * Savepoint sp = Database.setSavepoint();
 * update [SELECT Id FROM Account WHERE ShippingState != null LIMIT 50];
 * Database.rollback(sp);
 *
 * Pseudo:
 *
 * (1) Aggregate Monthly Hold_Per_Day__c records for the given source account Ids pulling the latest Hpd.Date__c.
 * (2) Parse the Agg Results out into Source Account Maps.
 * (3) Query for Target Account Most Recent Hpd Lookup fields.
 * (4) Roll through the target accounts using info from (2) to overlay lookup fields
 *     a. Create XferResults custom object to store old / new info for email.
 * (5) Run update on target accounts.
 * (6) Build results email.
 * (7) Send results email / log in Accel_Application_Error__c
 */
global class BatchTransferHpdMonthlyAcctLookups implements     Database.Batchable <AggregateResult>,
                                                                Database.Stateful {

    global final static String MONTHLY_HPD_DEV_NAME = 'Monthly_HPD';

    global Map<Id,Id> mSourceAcctId_TargetAcctId;
    global Map<Id,Id> mTargetAcctId_SourceAcctId = new Map<Id,Id>();
    global Boolean commitTrans = false;
    global Boolean chainHpdTotalAccountFix = false;

    global Map<Account,List<Hold_Per_Day__c>> mProcessed = new Map<Account,List<Hold_Per_Day__c>>();
    global List<XferResult> xferResults = new List<XferResult>();
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;

    private Integer batchSize;
    private Integer totalRecordsModified = 0;
    private String chainedBatchJobId;
    private List<Exception>  exceptions = new List<Exception>();
    private Map<Id,String> mIgnoredRecords = new Map<Id,String>();
    private String recipientUserEmail;
    global String asyncJobName;

    /**
     * @param mSourceAcctId_TargetAcctId A map of source account id => target account id
     * @param bCommitTrans. if true, will run as normal. if false will rollback and not update accounts. (good for testing)
     */
    global BatchTransferHpdMonthlyAcctLookups(  Map<Id,Id> mSourceAcctId_TargetAcctId, String sRecipientUserEmail,
                                                Boolean bCommitTrans, Boolean bChainHpdTotalAccountFix, String sAsyncJobName) {
        this.commitTrans = bCommitTrans;
        this.chainHpdTotalAccountFix = bChainHpdTotalAccountFix;
        this.mSourceAcctId_TargetAcctId = mSourceAcctId_TargetAcctId;
        this.recipientUserEmail = sRecipientUserEmail;
        if(mSourceAcctId_TargetAcctId != null) {
            this.mTargetAcctId_SourceAcctId = reverseMap(mSourceAcctId_TargetAcctId);
        }
        this.asyncJobName = sAsyncJobName;
    }
    global BatchTransferHpdMonthlyAcctLookups(   Map<Id, Id> mSourceAcctId_TargetAcctId, String sRecipientUserEmail,
            Boolean bCommitTrans, Boolean bChainAccountFix) {

        this( mSourceAcctId_TargetAcctId,sRecipientUserEmail,bCommitTrans,bChainAccountFix,null );
        String defaultAsyncJobName = BatchTransferHpdMonthlyAcctLookups.class.getName() + '_' + System.now();
        this.asyncJobName = defaultAsyncJobName;
    }
    /**
     * Pull source account information.
     * @param bc
     * @return a Iterable of aggregate results for the source accounts.
     * @TODO should this be the target accounts most recent hpds?????????????????????????????????????????
     * as we may have moved them in the previous chained job????????????????
     */
    global Iterable<AggregateResult> start(Database.BatchableContext bc) {
        formattedLocalStartTimeString = Datetime.now().format();
        String className = BatchTransferHpdMonthlyAcctLookups.class.getName();
        Async_Job__c jobTemp = AsyncSvc.retrieveInitiatingAsyncJob(this.asyncJobName);
        Boolean isInitiator = false;
        if(jobTemp!= null && jobTemp.Parent_Job_Id__c == bc.getJobId()) {
            isInitiator = true;
        }
        Async_Job__c job = AsyncSvc.insertAsyncJob(     bc.getJobId(), asyncJobName, className,
                'Initiating '+ className,'Processing',null,'Processing',isInitiator);



        List<Id> sourceAccountIds = new List<Id>(mSourceAcctId_TargetAcctId.keySet());
        List<Id> targetAccountIds = mSourceAcctId_TargetAcctId.values();
        String monthlyHpdDevName = MONTHLY_HPD_DEV_NAME;

        String soql = '';   //  note can't use bind variables here.
        soql += 'SELECT Account__c accountId, Account__r.Name accountName,  ' +
                '       Max(Id) latestHpdId, Max(Name) latestHpdName ,Max(Date__c) latestHpdDate ';
        soql += 'FROM   Hold_Per_Day__c ';
        soql += 'WHERE  Account__c               IN  (\''+String.join(targetAccountIds,'\',\'')+'\') ';
        soql += 'AND    RecordType.DeveloperName  =  \''+ monthlyHpdDevName + '\' ';
        soql += 'GROUP By Account__c, Account__r.Name ';
        if(!isInitiator) {
            AsyncSvc.OverallJobDetails ojd = new AsyncSvc.OverallJobDetails(BatchTransferHpdMonthlyAcctLookups.class.getName()
                    + ' - start', 'running soql query:'+soql );
            List<AsyncSvc.OverallJobDetails> ojds = new List<AsyncSvc.OverallJobDetails>{ojd};
            AsyncSvc.updateJobStatus(this.asyncJobName, 'Processing', 'Processing',ojds,'Processing');
        }

        return new AggregateResultIterable(soql);
    }
    /**
     *
     * @param bc
     * @param scope
     * @todo we can't be su
     */
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {

            if (batchSize == NULL || scope.size() > batchSize) batchSize = scope.size();

            Map<Id, Hold_Per_Day__c> mTargetAccountId_TargetHpd = new Map<Id, Hold_Per_Day__c>();
            Map<Id, Account> mTargetAccountId_TargetAccount = new Map<Id, Account>();

            for (SObject sObj : scope) {
                AggregateResult ar = (AggregateResult) sObj;
                this.parseAggregateResults(mTargetAccountId_TargetHpd, mTargetAccountId_TargetAccount, ar);
            }

            List<Account> accountsToUpd = new List<Account>();
            List<Id> targetAccountIds = new List<Id>(mSourceAcctId_TargetAcctId.values());

            Map<Id, Account> mTargetAccountsByIds = new Map<Id, Account> ([
                    SELECT Id, Name, Most_Recent_Hold_Per_Day__c, Most_Recent_Hold_Per_Day__r.Name
                    FROM Account
                    WHERE Id IN :targetAccountIds
            ]);

            for (Account targetAccount : mTargetAccountsByIds.values()) {
                //  Save the diff so we can send in an email --
                XferResult res = new XferResult(
                        new Account(
                                Id = targetAccount.Id, Name = targetAccount.Name,
                                Most_Recent_Hold_Per_Day__c = targetAccount.Most_Recent_Hold_Per_Day__c,
                                Most_Recent_Hold_Per_Day__r = new Hold_Per_Day__c (
                                        Id = targetAccount.Most_Recent_Hold_Per_Day__c,
                                        //  we need to hide the hpd autonumber name in another field
                                        Machine_Model__c = targetAccount.Most_Recent_Hold_Per_Day__r.Name
                                )
                        )
                );
                Id sourceAccountId = mTargetAcctId_SourceAcctId.get(targetAccount.Id);
                //  store the source account for the email;
                //res.sourceAccount = mSourceAccountId_SourceAccount.get(sourceAccountId);
                //  pull the source account hpd info into the target account.
                Hold_Per_Day__c targetHpd = ((Hold_Per_Day__c) mTargetAccountId_TargetHpd.get(targetAccount.Id));

                if(targetHpd != null) {
                    //  Now overwrite values on tgt account with source acct.
                    targetAccount.Most_Recent_Hold_Per_Day__c = targetHpd.Id;

                    res.newHpd = new Hold_Per_Day__c (
                            Id = targetAccount.Most_Recent_Hold_Per_Day__c,
                            //  we need to hide the hpd autonumber name in another field
                            Machine_Model__c = mTargetAccountId_TargetHpd.get(targetAccount.Id).Machine_Model__c
                    );
                    this.xferResults.add(res);
                    accountsToUpd.add(targetAccount);
                    //  Remove lookups on source account (discontinued)
                } else {
                    mIgnoredRecords.put(sourceAccountId,' Discarded (probably a most recent hold per day mismatch ie. legacy records had dailies copied over but did not address account lookups)');
                }
            }
            if (!accountsToUpd.isEmpty()) {
                Savepoint sp = Database.setSavepoint();
                update accountsToUpd;
                totalRecordsModified += accountsToUpd.size();
                if (!commitTrans) {
                    Database.rollback(sp);
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            exceptions.add(e);
        }
    }

    /**
     *
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {

        formattedLocalEndTimeString = DateTime.now().format();

        List<String> toAddresses = new List<String>();
        if(recipientUserEmail != null && recipientUserEmail != '') {
            toAddresses.add(recipientUserEmail);
        } else {
            toAddresses.add('rick@chicagosalesforceconsulting.com');
        }
        String owaEmailAddy = 'crm@accelentertainment.com';

        String subject = 'Batch - [ Account ] Most Recent Hpd Lookup Transfer Completed: ';
        subject += totalRecordsModified +' record';
        if(totalRecordsModified > 1) subject += 's';
        subject += ' updated';

        if (chainHpdTotalAccountFix) {
            if (batchSize == null ) batchSize = 25; //just in case the first class didn't have any records to work on
            if (!Test.isRunningTest()) {
                chainedBatchJobId =  Database.executeBatch(
                        new BatchTransferHpdTotalMonthlyAcctLookups(mSourceAcctId_TargetAcctId, recipientUserEmail,commitTrans,asyncJobName)
                        , batchSize);
            }
        }
        String overallJobStatus = '';
        String parentJobStatus = 'Completed';
        String batchGroupStatus = parentJobStatus;
        if(chainedBatchJobId != null) {
            overallJobStatus = ' Finished ' + BatchTransferHpdTotalMonthlyAcctLookups.class.getName() + ' Chaining Batch Job: ' + chainedBatchJobId;
            batchGroupStatus = 'Processing';
        } else {
            overallJobStatus = 'All Jobs Complete!';
            batchGroupStatus = 'Completed';
        }
        AsyncSvc.updateJobStatus(this.asyncJobName, parentJobStatus, overallJobStatus,null,batchGroupStatus);


        String body = buildHtmlBody();
        EmailSvc.sendEmail(toAddresses,null,subject,body,null,owaEmailAddy);
    }
    /**
     *
     * Note we can't user the name field on hpd (autonumber) so we have to hide the name somewhere else.
     * @param mAccountId_Hpd
     */
    private void parseAggregateResults( Map<Id,Hold_Per_Day__c> mTargetAccountId_TargetHpd,
                                        Map<Id,Account> mTargetAccountId_TargetAccount,
                                        AggregateResult ar) {

        Id accountId = (Id)ar.get('accountId');
        String accountName = (String)ar.get('accountName');

        Id latestHpdId = (Id)ar.get('latestHpdId');
        Date latestHpdDate = (Date)ar.get('latestHpdDate');
        String latestHpdName = (String)ar.get('latestHpdName');

        Hold_Per_Day__c hpd = new Hold_Per_Day__c (
                Id=latestHpdId, Date__c = latestHpdDate, Machine_Model__c = latestHpdName,
                Account__r = new Account (
                        Id=accountId,
                        Name=accountName
                )
        );
        mTargetAccountId_TargetAccount.put(accountId, new Account(Id=accountId, Name=accountName));
        mTargetAccountId_TargetHpd.put( accountId, hpd);
    }
    /**
     *
     *
     * @return
     */
    private String buildHtmlBody() {
        String body = '';
        String exeSummary = '';
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        if(commitTrans) {
            exeSummary += '<span class="accel-font-success">Transaction was committed!</span>';
        } else  {
            exeSummary += '<span class="accel-font-error">Transaction was rolled back due to user supplied parameter.&nbsp;&nbsp;</span>';
            exeSummary += '<span>The results would have been the following if the transaction was committed:</span>';
        }
        String caption = 'Modified HPD Lookups on accounts from source accounts to target accounts.';
        body += '<html>';
        body += '  <head>';
        body += '   <style>' + buildCssStyles() + '</style>';
        body += '  </head>';
        body += '<body>';
        body += '<table bgcolor="#9AA0A6" width="100%" border="0" cellpadding="0" cellspacing="0"';
        body += '<tr>';
        body += '<td align="center" style="padding-top:80px;padding-bottom:80px">';
        //=------------ summary table ----------------------------------------
        body += '  <table cellpadding="0" cellspacing="0" bgcolor="#ffffff" width="85%" class="accel-summary-email-table">';
        body += '   <tr>';

        body += '     <td align="left" style="padding:20px;" >';
        body += '        <table cellpadding="0" cellspacing="0" padding="5">';
        body += '    <thead>';
        body += '      <tr>';
        body += '        <th class="row-info"></th>';
        body += '        <th class="row-desc"></th>';
        body += '      </tr>';
        body += '    </thead>';
        body += '    <tbody>';
        body += '          <tr>';
        body += '            <td >Execution Summary</td> ';
        body += '            <td>'+exeSummary+'</td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Batch Apex Class</td> ';
        body += '            <td>BatchTransferHpdTotalMonthlyAcctLookups</td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Executing User</td> ';
        body += '            <td>' + UserInfo.getUserName() + '</td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Org Base URL</td> ';
        body += '            <td>'+baseUrl + '</td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Start Time</td> ';
        body += '            <td>'+formattedLocalStartTimeString + '</td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>End Time</td> ';
        body += '            <td>'+formattedLocalEndTimeString + '</td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Param: Target Account Ids</td> ';
        body += '            <td>';
        if(mSourceAcctId_TargetAcctId.size() > 10) {
            body += ' (Too many to display)';
        } else {
            for (Id targetId : mTargetAcctId_SourceAcctId.keySet()) {
                body += targetId + ',';
            }
        }
        body += '            </td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Param: Source Account Ids</td> ';
        body += '            <td>';
        if(mSourceAcctId_TargetAcctId.size() > 10) {
            body += ' (Too many to display)';
        } else {
            for (Id sourceId : mSourceAcctId_TargetAcctId.keySet()) {
                body += sourceId + ',';
            }
        }
        body += '            </td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Param: bCommitTrans</td> ';
        body += '            <td>';
        String cssClass = commitTrans ? 'accel-font-success' : 'accel-font-error';
        body += ' <span class="'+cssClass+'">';
        body += commitTrans;
        body += ' </span>';
        body += '            </td>';
        body += '          </tr>';
        if(chainHpdTotalAccountFix) {
            body += '          <tr>';
            body += '          <td>';
            body += '          Next Execution Step ';
            body += '          </td>';
            body += '          <td style="color:orange">';
            body += '          Firing chained BatchTransferHpdTotalMontlyAcctLookups for Account.Hold_Per_Day_Total__c batch Id '+chainedBatchJobId;
            body += '          </td>';
            body += '          </tr>';
        }
        body += '          </tbody';
        body += '          </table>';
        body += '     </td>';
        body += '  </tr>';
        body += '  </table>';
        //-------------- end summary table -------------------------------------
        // ------------------------------- main table ----------------------------------------
        body += '<hr></hr>';
        body += '  <table cellpadding="0" cellspacing="0" bgcolor="#ffffff" width="85%" class="accel-summary-email-table">';
        body += '   <tr>';
        body += '     <td align="left" style="padding:20px;" >';
        body += '  <table cellpadding="0" cellspacing="0" class="accel-email-table" padding="5" bgcolor="#ffffff">';
        body += '    <caption class="accel-caption" style="padding-bottom:10px;background-color:#ffffff">' + caption + '</caption>';
        body += '    <thead>';
        body += '      <tr>';
        body += '        <th class="row-Tgt-Name">Target Account Name </th>';
        body += '        <th class="row-Tgt-Prev">Tgt Prev Most Recent Hpd</th>';
        body += '        <th class="row-Tgt-New">Tgt New Most Recent Hpd</th>';
        body += '      </tr>';
        body += '    </thead>';
        body += '    <tbody>';

        // -- Note.. Hpd Name (AutoNumber) is hidden (no not updated... sigh.) in Machine_Model__c out of necessity.
        for(XferResult res : this.xferResults) {

            body += '      <tr>';
            body += '        <td><a href="'+baseUrl+'/'+res.targetAccount.Id+'">' + res.targetAccount.Name+'</a></td>';
            if(res.targetAccount.Most_Recent_Hold_Per_Day__c != null) {
                body += '        <td><a href="' + baseUrl + '/' + res.targetAccount.Most_Recent_Hold_Per_Day__c + '">'
                        + res.targetAccount.Most_Recent_Hold_Per_Day__r.Machine_Model__c + '</a></td>';
            } else {
                body += '<td>N/A</td>';
            }
            body += '        <td><a href="'+baseUrl+'/'+res.newHpd.Id+'">' + res.newHpd.Machine_Model__c+'</a></td>';
            body += '      </tr>';
        }
        body += '    </tbody>';
        body += '</table>';
        // ---------------------------------- end main table -----------------------------------
        body += '</td>';
        body += '</tr>';
        body += '</table>';
        body += '</td>';
        body += '</tr>';
        //---------------------------- spit out exceptions in exe method -----------------------
        if(!exceptions.isEmpty()) {
            body += '<tr>';
            body += '<td>System Exceptions Caught!!';
            body += '</td>';
            body += '</tr>';
            for(Exception e : exceptions) {
                body += '<tr>';
                body += '<td>';
                body += e.getMessage() + ' ' + e.getLineNumber();
                body += '</td>';
                body += '</tr>';
            }
        }
        if(!mIgnoredRecords.isEmpty()) {
            body += '<tr>';
            body += '<td>Caught / Ignored Records!';
            body += '</td>';
            body += '</tr>';
            for(Id ignoredSourceId  : mIgnoredRecords.keySet()) {
                body += '<tr>';
                body += '<td>';
                body += 'Source Account Id='+ignoredSourceId+ '..Reason:'+mIgnoredRecords.get(ignoredSourceId);
                body += '</td>';
                body += '</tr>';
            }
        }
        body += '</table>';
        body += '</body>';
        body += '</html>';

        return body;
    }
    /**
    * Note this is dummed down immensely to support picky email clients.  (hello google)
    *
    * @return
    */
    private String buildCssStyles() {
        String css = '';
        css += '.accel-summary-email-table {width:85%;}';
        css += '.accel-email-table{ border-collapse:collapse; width:85%;}';
        css += '.accel-caption{ text-align:left;}';
        css += '.accel-email-table tr th {text-align:left}';

        css += '.row-info {width:25%;}';
        css += '.row-desc {width:75%}';

        css += '.row-Tgt-Name {width:30%;}';
        css += '.row-Src-Name {width:30%}';
        css += '.row-Tgt-Prev {width:20%}';
        css += '.row-Tgt-New {width:20%}';

        css += '.accel-font-success {color:blue}';
        css += '.accel-font-error {color:red}';

        return css;
    }
    /**
     *
     */
    private class XferResult {
        Account targetAccount;
        Account sourceAccount;
        Hold_Per_Day__c newHpd;

        public XferResult(Account tgtAccount) {
            this.targetAccount = tgtAccount;
        }
    }
    // ------  Random util methods ---------------------------------

    /**
     * Reverses a map.
     * @param a Map of Id => Id  (Values of source map must be unique!)
     * @return a Map of Id => Id that is the inverse of the passed parameter.
     */
    private Map<Id,Id> reverseMap(Map<Id,Id> m ) {
        Map<Id,Id> mReverse = new Map<Id,Id>();
        for(Id keyId : m.keySet()) {
            Id valueId = m.get(keyId);
            mReverse.put(valueId,keyId);
        }
        return mReverse;
    }
}