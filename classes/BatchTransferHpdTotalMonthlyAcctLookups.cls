/**
 * Currently only supports Monthly totals.
 *
 * Pseudo:
 *
 * (1) Query Location Hold_Per_Day_Total__c records for the given source account Ids.
 * (2) Parse the results into Source Account Maps.
 * (3) Query for Target Account Hold Per Day Total Lookup fields.
 * (4) Roll through the target accounts using info from (2) to overlay lookup fields
 *     a. Create XferResults custom object to store old / new info for email.
 * (5) Run update on target accounts.
 * (6) Build results email.
 * (7) Send results email / log in Accel_Application_Error__c
 */
global class BatchTransferHpdTotalMonthlyAcctLookups implements Database.Batchable <SObject>,
                                                                Database.Stateful {

    global final static String HPD_TOTAL_DEV_NAME = 'Location';

    global Map<Id,Id> mSourceAcctId_TargetAcctId;
    global Map<Id,Id> mTargetAcctId_SourceAcctId = new Map<Id,Id>();
    global Boolean commitTrans = true;

    global List<XferResult> xferResults = new List<XferResult>();
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;
    global Integer totalRecordsModified = 0;
    private String recipientUserEmail;
    private String asyncJobName;

    /**
     * @param mSourceAcctId_TargetAcctId A map of source account id => target account id
     * @param bCommitTrans. if true, will run as normal. if false will rollback and not update accounts. (good for testing)
     */
    global BatchTransferHpdTotalMonthlyAcctLookups( Map<Id,Id> mSourceAcctId_TargetAcctId, String sRecipientUserEmail,
                                                    Boolean bCommitTrans,String asyncJobName) {
        this.commitTrans = bCommitTrans;
        this.mSourceAcctId_TargetAcctId = mSourceAcctId_TargetAcctId;
        this.recipientUserEmail = sRecipientUserEmail;
        if(mSourceAcctId_TargetAcctId != null) {
            this.mTargetAcctId_SourceAcctId = reverseMap(mSourceAcctId_TargetAcctId);
        }
        this.asyncJobName = asyncJobName;
    }
    /**
     *
     * Retrieve the source hold_per_day_total__c information.
     * @param bc
     * @return
     */
    global database.QueryLocator start(Database.BatchableContext bc) {

        String className = BatchTransferHpdTotalMonthlyAcctLookups.class.getName();
        Async_Job__c jobTemp = AsyncSvc.retrieveInitiatingAsyncJob(this.asyncJobName);
        Boolean isInitiator = false;
        if(jobTemp!= null && jobTemp.Parent_Job_Id__c == bc.getJobId()) {
            isInitiator = true;
        }
        Async_Job__c job = AsyncSvc.insertAsyncJob(     bc.getJobId(), asyncJobName, className,
                'Initiating '+ className,'Processing',null,'Processing',isInitiator);

        formattedLocalStartTimeString= DateTime.now().format();
        return Database.getQueryLocator([
                SELECT  Id, Name, Name_Field_Store__c,Account__c, Account__r.Name
                FROM    Hold_Per_Day_Total__c
                WHERE   RecordType.DeveloperName = :HPD_TOTAL_DEV_NAME
                AND     Account__c IN :mSourceAcctId_TargetAcctId.keySet()
                ORDER BY Account__r.Name ASC
        ]);
    }

    /**
     *
     * @param bc
     * @param scope
     */
    global void execute(Database.BatchableContext bc, List<Hold_Per_Day_Total__c> scope) {

        Map<Id,Hold_Per_Day_Total__c> mSourceAccountId_SourceHpd  = new Map<Id,Hold_Per_Day_Total__c>();
        Map<Id,Account> mSourceAccountId_SourceAccount      = new Map<Id,Account>();

        for(Hold_Per_Day_Total__c holdPerDayTotal : scope) {

            Hold_Per_Day_Total__c hpdTotal = buildHoldPerDayTotal(holdPerDayTotal);

            mSourceAccountId_SourceAccount.put(holdPerDayTotal.Account__c,
                    new Account(Id=holdPerDayTotal.Account__c, Name=holdPerDayTotal.Account__r.Name));
            mSourceAccountId_SourceHpd.put( holdPerDayTotal.Account__c, hpdTotal);

        }
        List<Account> accountsToUpd = new List<Account>();
        List<Hold_Per_Day_Total__c> holdPerDayTotalsToUpd = new List<Hold_Per_Day_Total__c>();

        List<Id> targetAccountIds = new List<Id>(mSourceAcctId_TargetAcctId.values());

        Map<Id,Account> mTargetAccountsByIds = retrieveTargetAccounts(targetAccountIds);

        for(Account targetAccount : mTargetAccountsByIds.values()) {
            //  Save the diff so we can send in an email --
            XferResult res = buildResult(targetAccount);
            Id sourceAccountId = mTargetAcctId_SourceAcctId.get(targetAccount.Id);
            res.sourceAccount = mSourceAccountId_SourceAccount.get(sourceAccountId);

            //  pull the source account hpd info into the target account.
            Hold_Per_Day_Total__c targetHpdTotal =  ((Hold_Per_Day_Total__c)mSourceAccountId_SourceHpd.get(sourceAccountId));
            //  update the account lookup on the target hold per day total to the target account
            targetHpdTotal.Account__c = targetAccount.Id;

            if(targetHpdTotal != null) {
                //  Now overwrite values on tgt account with source acct.
                targetAccount.Hold_Per_Day_Total__c = targetHpdTotal.Id;
                //  we need to hide the hpd autonumber name in another field
                res.newHpdTotal = new Hold_Per_Day_Total__c (
                        Id = targetAccount.Hold_Per_Day_Total__c,
                        Name_Field_Store__c = mSourceAccountId_SourceHpd.get(sourceAccountId).Name_Field_Store__c
                );
                accountsToUpd.add(targetAccount);
                holdPerDayTotalsToUpd.add(targetHpdTotal);
                this.xferResults.add(res);
            } else {
                System.debug(LoggingLevel.ERROR, 'could not find an hpd total record for source account id:'+sourceAccountId);
            }
        }
        if(!accountsToUpd.isEmpty()) {
            Savepoint sp = Database.setSavepoint();
            update accountsToUpd;
            update holdPerDayTotalsToUpd;
            totalRecordsModified += accountsToUpd.size();
            if(!commitTrans) {
                Database.rollback(sp);
            }
        }
    }
    /**
     *
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        String overallJobStatus = 'All jobs Completed';
        String parentJobStatus = 'Completed';
        String batchGroupStatus = parentJobStatus;
        AsyncSvc.updateJobStatus(this.asyncJobName, parentJobStatus, overallJobStatus,null,batchGroupStatus);


        List<String> toAddresses = new List<String>();
        if(recipientUserEmail != null && recipientUserEmail != '') {
            toAddresses.add(recipientUserEmail);
        } else {
            toAddresses.add('rick@chicagosalesforceconsulting.com');
        }
        String owaEmailAddy = 'crm@accelentertainment.com';

        String subject = 'Batch - [Account] Hold Per Data Total Transfer Completed: ';
        subject += totalRecordsModified +' records updated';
        String body = buildHtmlBody();
        EmailSvc.sendEmail(toAddresses,null,subject,body,null,owaEmailAddy);
    }

    private XferResult buildResult(Account targetAccount) {
        return new XferResult(
                new Account(
                        Id = targetAccount.Id, Name = targetAccount.Name,
                        Hold_Per_Day_Total__c = targetAccount.Hold_Per_Day_Total__c,
                        Hold_Per_Day_Total__r = new Hold_Per_Day_Total__c (
                                Id = targetAccount.Hold_Per_Day_Total__c,
                                Name_Field_Store__c = targetAccount.Hold_Per_Day_Total__r.Name
                        )
                )
        );
    }
    private Hold_Per_Day_Total__c buildHoldPerDayTotal(Hold_Per_Day_Total__c holdPerDayTotal) {
        return new Hold_Per_Day_Total__c (
                Id=holdPerDayTotal.Id,  Name_Field_Store__c = holdPerDayTotal.Name,
                Account__c = holdPerDayTotal.Account__c,
                Account__r = new Account (
                        Id=holdPerDayTotal.Account__c,
                        Name=holdPerDayTotal.Account__r.Name
                )
        );
    }
    private Map<Id,Account> retrieveTargetAccounts(List<Id> targetAccountIds) {
        return new Map<Id,Account> ([
                SELECT  Id, Name, Hold_Per_Day_Total__c, Hold_Per_Day_Total__r.Name
                FROM    Account
                WHERE   Id IN :targetAccountIds
        ]);
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
        String caption = 'Modified HPD Total Lookups on accounts from source accounts to target accounts.';
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
        for(Id targetId : mTargetAcctId_SourceAcctId.keySet()) {
            body += targetId + ',';
        }
        body += '            </td>';
        body += '          </tr>';
        body += '          <tr>';
        body += '            <td>Param: Source Account Ids</td> ';
        body += '            <td>';
        for(Id sourceId : mSourceAcctId_TargetAcctId.keySet()) {
            body += sourceId + ',';
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
        body += '        <th class="row-Tgt-Prev">Tgt Prev Hpd Total</th>';
        body += '        <th class="row-Tgt-New">Tgt New Hpd Total</th>';
        body += '      </tr>';
        body += '    </thead>';
        body += '    <tbody>';

        // -- Note.. Hpd Name (AutoNumber) is hidden (no not updated... sigh.) in Machine_Model__c out of necessity.
        for(XferResult res : this.xferResults) {

            body += '      <tr>';
            body += '        <td><a href="'+baseUrl+'/'+res.targetAccount.Id+'">' + res.targetAccount.Name+'</a></td>';
            body += '        <td><a href="'+baseUrl+'/'+res.sourceAccount.Id+'">' + res.sourceAccount.Name+'</a></td>';
            body += '        <td><a href="'+baseUrl+'/'+res.targetAccount.Hold_Per_Day_Total__c+'">'
                    + res.targetAccount.Hold_Per_Day_Total__r.Name_Field_Store__c+'</a></td>';
            body += '        <td><a href="'+baseUrl+'/'+res.newHpdTotal.Id+'">' + res.newHpdTotal.Name_Field_Store__c+'</a></td>';
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
    public class XferResult {
        Account targetAccount;
        Account sourceAccount;
        Hold_Per_Day_Total__c newHpdTotal;

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