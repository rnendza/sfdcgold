/**
 * The class only supports The Monthly Record Type on the Hold_Per_Day__c sObject.
 *
 * Pseudo:
 *
 * (1) Query Hole_Per_Day__c records for the given source account Ids.
 * (2) Parse the results into Source Account Maps.
 * @todo finish pseudo
 * (5) Run update on Hold_Per_Day__c records.
 * (6) Build results email.
 * (7) Send results email / log in Accel_Application_Error__c
 *
 * << NOTE >> if your going to execute this for a large number of accounts. ie > 200 it is suggested a very small
 * batch size is used (such as 25). testing seemed to work fine with that.
 */
global class BatchTransferHpdMonthlies implements   Database.Batchable <SObject>,
                                                    Database.Stateful {

    public final static String OWA_EMAIL_ADDY = 'crm@accelentertainment.com';

    global Map<Id,Id> mSourceAcctId_TargetAcctId;
    global Map<Id,Id> mTargetAcctId_SourceAcctId = new Map<Id,Id>();

    global Boolean chainAccountFix = false;
    global Boolean commitTrans = false;
    private Integer batchSize;

    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;
    private Integer totalRecordsModified = 0;
    global String chainedBatchJobId;
    global List<XferResult> xferResults = new List<XferResult>();
    private List<BatchException>  exceptions = new List<BatchException>();
    private String recipientUserEmail;
    global String asyncJobName;

    /**
     * @param mSourceAcctId_TargetAcctId A map of source account id => target account id
     * @param bCommitTrans               If true, commit the trans, if false.. this and any chained job will be rolled back.
     * @param chainAccountFix            Run the jobs to fix account hpd lookups after finish method.
     */
    global BatchTransferHpdMonthlies(Map<Id,Id> mSourceAcctId_TargetAcctId,String sRecipientUserEmail,
                                Boolean bCommitTrans, Boolean bChainAccountFix, String sAsyncJobName ) {

        this.mSourceAcctId_TargetAcctId = mSourceAcctId_TargetAcctId;
        this.commitTrans = bCommitTrans;
        this.chainAccountFix = bChainAccountFix;
        this.recipientUserEmail = sRecipientUSerEmail;
        this.asyncJobName = sAsyncJobName;
        if(mSourceAcctId_TargetAcctId != null) {
            this.mTargetAcctId_SourceAcctId = reverseMap(mSourceAcctId_TargetAcctId);
        }
    }
    /**
     * Overload allow for default of AsyncJobName
     *
     * @param mSourceAcctId_TargetAcctId
     * @param sRecipientUserEmail
     * @param bCommitTrans
     * @param bChainAccountFix
     */
    global BatchTransferHpdMonthlies(   Map<Id, Id> mSourceAcctId_TargetAcctId, String sRecipientUserEmail,
                                        Boolean bCommitTrans, Boolean bChainAccountFix) {

        this( mSourceAcctId_TargetAcctId,sRecipientUserEmail,bCommitTrans,bChainAccountFix,null );
        String defaultAsyncJobName = BatchTransferHpdMonthlies.class.getName() + '_' + System.now();
        this.asyncJobName = defaultAsyncJobName;
    }
    /**
     * Give us a QL of all monthly hpd records for the given source account ids.
     * @param bc
     * @return
     */
    global database.QueryLocator start(Database.BatchableContext bc) {
        String className = BatchTransferHpdMonthlies.class.getName();


        Async_Job__c job = AsyncSvc.insertAsyncJob(bc.getJobId(), asyncJobName,
                'Initiating ' + className,  className, 'Processing', null,
                'Processing', true);

        Set<Id> sourceAccountIds;
        if (mSourceAcctId_TargetAcctId != null) {
            sourceAccountIds = mSourceAcctId_TargetAcctId.keySet();
        }
        return Database.getQueryLocator([
                SELECT Id, Account__c, Date__c, Name, Account__r.Name,Machine_Model__c
                FROM Hold_Per_Day__c
                WHERE RecordType.Name = 'Monthly HPD'
                AND Account__c IN :sourceAccountIds
                ORDER BY Account__r.Name ASC
        ]);
    }
    /**
     * Note the majority of the effort here is to be able to show a snapshot of before / after in an email.
     *
     * @param bc
     * @param scope
     * @todo doc
     */
    global void execute(Database.BatchableContext bc, List<Hold_Per_Day__c> scope) {

        if (batchSize == NULL || scope.size() > batchSize) batchSize = scope.size();
        Map<Id, Hold_Per_Day__c> mSourceAccountId_SourceHpd = new Map<Id, Hold_Per_Day__c>();
        Map<Id, Account> mSourceAccountId_SourceAccount     = new Map<Id, Account>();

        try {
            List<Id> targetAccountIds = new List<Id>(mSourceAcctId_TargetAcctId.values());
            Map<Id, Account> mTargetAccountsByIds = retrieveTargetAccounts(targetAccountIds);
            List<Hold_Per_Day__c> hpdsToUpd = new List<Hold_Per_Day__c>();

            for (Hold_Per_Day__c holdPerDay : scope) {
                //  Build a new account sObject for storage for email display
                Account acct = new Account(Id = holdPerDay.Account__c, Name = holdPerDay.Account__r.Name);
                mSourceAccountId_SourceAccount.put(holdPerDay.Account__c, acct);

                //  Build a new hpd sObject for storage for email display.
                Hold_Per_Day__c hpd = buildHoldPerDay(holdPerDay);
                mSourceAccountId_SourceHpd.put(holdPerDay.Account__c, hpd);

                //  Add results to email array.
                XferResult res = buildResult(holdPerDay);
                res.sourceAccount = acct;
                Id targetAcctId = mSourceAcctId_TargetAcctId.get(acct.Id);
                res.targetAccount = mTargetAccountsByIds.get(targetAcctId);
                res.newHpd = hpd;
                xferResults.add(res);

                //  UPDATE the account on the target Hold_Per_Day__c record
                hpd.Account__c = targetAcctId;
                if(res.targetAccount != null) {
                    hpdsToUpd.add(hpd);
                }
            }
            Savepoint sp = Database.setSavepoint();
            update hpdsToUpd;
            totalRecordsModified += hpdsToUpd.size();
            if (!commitTrans) {
                Database.rollback(sp);  //   Only Commit if the client requests it.
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,ex);
            exceptions.add(new BatchException(ex));         //   Store exception for email display.
        }
    }
    /**
     * If we can chain the batch.. chain it. it fire next batch job.. Also build an email and send it.
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {

        formattedLocalEndTimeString = DateTime.now().format();
        if (chainAccountFix && totalRecordsModified > 0) {
            if (batchSize == null ) batchSize = 25;
            if (!Test.isRunningTest()) { // Can't do this in TEST Classes.
                //  Fire next batch if client told us to chain batches and we retrieved some records.
                chainedBatchJobId = Database.executeBatch(
                        new BatchTransferHpdMonthlyAcctLookups( mSourceAcctId_TargetAcctId, recipientUserEmail,
                                                                commitTrans, chainAccountFix,asyncJobName)
                        , batchSize);
            }
        } else {
            chainAccountFix = false;
        }
        if(Test.isRunningTest()) {
            chainedBatchJobId = bc.getJobId();  // Mock because we can't chain in TEST ctx
        }
        String overallJobStatus = '';
        String parentJobStatus = 'Completed';
        String batchGroupStatus = parentJobStatus;
        if(chainedBatchJobId != null) {
            overallJobStatus = ' Finished ' + BatchTransferHpdMonthlies.class.getName() + ' Chaining Batch Job: ' + chainedBatchJobId;
            batchGroupStatus = 'Processing';
        } else {
            overallJobStatus = 'All Jobs Complete!';
            batchGroupStatus = 'Completed';
        }
        AsyncSvc.OverallJobDetails ojd = new AsyncSvc.OverallJobDetails(BatchTransferHpdMonthlies.class.getName()
                + ' - finish', 'total records modified:'+totalRecordsModified );
        List<AsyncSvc.OverallJobDetails> ojds = new List<AsyncSvc.OverallJobDetails>{ojd};
        AsyncSvc.updateJobStatus(this.asyncJobName, parentJobStatus, overallJobStatus,ojds,batchGroupStatus);

        //  Build and send email
        List<String> toAddresses = new List<String>();
        if(recipientUserEmail != null && recipientUserEmail != '') {
            toAddresses.add(recipientUserEmail);
        } else {
            toAddresses.add('rick@chicagosalesforceconsulting.com');
        }
        String subject = 'Batch - [ Hold_Per_Day__c ]  hpd.Account__c update Transfer Complete: ';
        subject += totalRecordsModified +' record';
        if(totalRecordsModified > 1) subject += 's';
        subject += ' updated';
        String body = buildHtmlBody();
        EmailSvc.sendEmail(toAddresses,null,subject,body,null,OWA_EMAIL_ADDY);
    }
    /**
     *
     * @param holdPerDay
     * @return
     * @todo doc
     */
    private Hold_Per_Day__c buildHoldPerDay(Hold_Per_Day__c holdPerDay) {
        return new Hold_Per_Day__c (
                Id=holdPerDay.Id,  Machine_Model__c = holdPerDay.Name,
                Account__c = holdPerDay.Account__c,
                Account__r = new Account (
                        Id=holdPerDay.Account__c,
                        Name=holdPerDay.Account__r.Name
                )
        );
    }
    /**
     *
     * @param targetAccountIds
     * @return
     */
    private Map<Id,Account> retrieveTargetAccounts(List<Id> targetAccountIds) {
        return new Map<Id,Account> ([
                SELECT  Id, Name
                FROM    Account
                WHERE   Id IN :targetAccountIds
        ]);
    }
    /**
     * Private inner class.
     */
    private class XferResult {
        Hold_Per_Day__c newHpd; // the hold per day record attached to the target Account.
        Account targetAccount;
        Account sourceAccount;

        public XferResult(Hold_Per_Day__c hpd) {
            this.newHpd = hpd;
        }
    }
    // ------  Random util methods ---------------------------------

    /**
     *
     *
     * @return
     */
    private String buildHtmlBody() {
        String body = '';
        String exeSummary = '';
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        Set<Id> sourceIds = mSourceAcctId_TargetAcctId != null ? mSourceAcctId_TargetAcctId.keySet() : new Set<Id>();
        Set<Id> targetIds = mTargetAcctId_SourceAcctId != null ? mTargetAcctId_SourceAcctId.keySet() : new Set<Id>();



        if(commitTrans) {
            exeSummary += '<span class="accel-font-success">Transaction was committed!</span>';
        } else  {
            exeSummary += '<span class="accel-font-error">Transaction was rolled back due to user supplied parameter.&nbsp;&nbsp;</span>';
            exeSummary += '<span>The results would have been the following if the transaction was committed:</span>';
        }
        String caption = 'Modified Hold Per Day Records transferring from source accounts to target accounts.';
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
        if(targetIds.size() > 10) {
            body += ' (Too many to display)';
        } else {
            for (Id targetId : targetIds) {
                body += targetId + ',';
            }
        }
        body += '            </td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Param: Source Account Ids</td> ';
        body += '            <td>';
        if(sourceIds.size() > 10) {
            body += ' (Too many to display)';
        } else {
            for (Id sourceId : sourceIds) {
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
        body += '          <tr>';
        body += '            <td>Param: bChainAccountfix</td> ';
        body += '            <td>';
        String cssClass2 = chainAccountFix ? 'accel-font-success' : 'accel-font-error';
        body += ' <span class="'+cssClass2+'">';
        body += chainAccountFix;
        body += ' </span>';
        body += '            </td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Param: Actual Batch Size </td> ';
        body += '            <td>';
        body +=  batchSize;
        body += '            </td>';
        body += '          </tr>';
        if(chainAccountFix || Test.isRunningTest()) {
            body += '          <tr>';
            body += '          <td>';
            body += '          Next Execution Step ';
            body += '          </td>';
            body += '          <td style="color:orange">';
            body += '          Firing chained BatchTransferHpdMonthly  for Account Most Recent HPD Lookups batch Id '+chainedBatchJobId;
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
        body += '        <th class="row-Src-Name">Source Account Name </th>';
        body += '        <th class="row-Tgt-Hpd">Tgt New HPD</th>';
        body += '      </tr>';
        body += '    </thead>';
        body += '    <tbody>';
        // -- Note.. Hpd Name (AutoNumber) is hidden (no not updated... sigh.) in Machine_Model__c out of necessity.
        for(XferResult res : this.xferResults) { // @todo null check source account.
            body += '<tr>';
            if(res.targetAccount != null) {
                body += '<td><a href="' + baseUrl + '/' + res.targetAccount.Id + '">' + res.targetAccount.Name + '</a></td>';
            } else {
                body += '<td style="color:red">Could not find target Account in org.. check id: '+mSourceAcctId_TargetAcctId.get(res.sourceAccount.Id)+'</td>';
            }
            body += '<td><a href="' + baseUrl + '/' + res.sourceAccount.Id+ '">' + res.sourceAccount.Name + '</a></td>';
            body += '<td><a href="' + baseUrl + '/' + res.newHpd.Id+ '">' + res.newHpd.Machine_Model__c + '</a></td>';
            body += '</tr>';
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
        if(Test.isRunningTest()) {  // Temp figure out how to force from test.
            exceptions.add(new BatchException('boogie man'));
        }
        if(!exceptions.isEmpty()) {
            body += '<tr>';
            body += '<td>Exceptions Caught!!';
            body += '</td>';
            body += '</tr>';
            for(Exception e : exceptions) {
                body += '<tr>';
                body += '<td>';
                body += e.getMessage();
                body += '</td>';
                body += '</tr>';
            }
        }
        body += '</table>';
        body += '</body>';
        body += '</html>';

        return body;
    }

    private XferResult buildResult(Hold_Per_Day__c hpd) {
        return new XferResult( hpd );
    }

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
        css += '.row-Tgt-Hpd {width:40%}';

        css += '.accel-font-success {color:blue}';
        css += '.accel-font-error {color:red}';

        return css;
    }
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
    public class BatchException extends Exception {}

}