public class BatchGeoAccuracyLegacyUpdater implements   Database.Batchable<Sobject>,
                                                        Database.Stateful {

    Integer iTotalAccountsUpdated = 0;
    Integer iTotalAccountsFailed = 0;
    Integer iTotalAccountsProcessed = 0;

    Map<Id, String> mAccountId_ErrMsg = new Map<Id, String>();
    Datetime startTime,endTime;

    public BatchGeoAccuracyLegacyUpdater() {}

    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = System.now();

        return Database.getQueryLocator([
                SELECT  Id, Name, ShippingGeocodeAccuracy
                FROM    Account
                WHERE   Shipping_Address_Accuracy__c = NULL
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Map<Id, Account> mAccountsByIds = new Map<Id, Account>();
        for (Account account : scope) {
            iTotalAccountsProcessed ++;
            String nativeGeoValue = account.ShippingGeocodeAccuracy;
            if (nativeGeoValue != null) {
                account.Shipping_Address_Accuracy__c = CustomMetadataSvc.retrieveGeoAccuracyDisplayValue(nativeGeoValue);
            } else {
                account.Shipping_Address_Accuracy__c = 'Weak';
            }
            mAccountsByIds.put(account.Id, account);
        }
        updateAccounts(mAccountsByIds);
    }

    private void updateAccounts(Map<Id, Account> mAccountsByIds) {
        List<Database.SaveResult> results = Database.update(mAccountsByIds.values(), false);
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results.get(i);
            if (sr.isSuccess()) {
                iTotalAccountsUpdated++;
            } else {
                Id accountId = mAccountsByIds.values().get(i).Id;
                handleErrors(accountId, results.get(i).getErrors());
                iTotalAccountsFailed++;
            }
        }
        System.debug(LoggingLevel.INFO,'---> updated: '+iTotalAccountsUpdated);
        System.debug(LoggingLevel.INFO,'---> failed: '+iTotalAccountsFailed);
        System.debug(LoggingLevel.INFO,'---> failed accounts: '+mAccountId_ErrMsg);
    }

    @TestVisible
    private void handleErrors(Id accountId, List<Database.Error> errors) {

        String errorMsg = '';
        for (Database.Error error : errors) {
            errorMsg += error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
            System.debug(LoggingLevel.ERROR, accountId + ' - ' + errorMsg);
        }
        if (!mAccountId_ErrMsg.containsKey(accountId)) {
            mAccountId_ErrMsg.put(accountId, errorMsg);
        }
    }

    public void finish(Database.BatchableContext bc) {
        endTime = System.now();
        genEmail();
    }

    private void genEmail() {

        String subject = 'Accel SFDC Batch Geo Accuracy Update Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + startTime.format() + '</b>';
        msg += '<br/>End Time:<b> ' + endTime.format() +'</b><br/>';
        msg += '</br><br/># of Accounts Processed:<b> ' + iTotalAccountsProcessed + '</b>';
        msg += '</br># of Account Updates Success:<b> ' + iTotalAccountsUpdated + '</b>';
        msg += '</br># of Account Updates Failed:<b> ' + iTotalAccountsFailed + '</b>';

        if(!mAccountId_ErrMsg.isEmpty()) {
            msg += '<br/><br/><b><font color=red>Failed Updates</font></b></br>';
            for(Id accountId : mAccountId_ErrMsg.keySet()) {
                msg += '<br/> Account Id='+accountId+ '  --->Error = '+mAccountId_ErrMsg.get(accountId);
            }
        }
        //List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        List<String> emailAddys = new List<String> {'rick@chicagosalesforceconsulting.com'};
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }

}