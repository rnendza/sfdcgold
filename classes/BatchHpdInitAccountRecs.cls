/**
 * Inits zero valued hpd total monthly and daily records and then puts a link on the account record back
 * to this records. (does this so future processes can be mere updates rather then upsert / insert.
 * New records are created via triggers...
 * Only run this ones with an empty Hold Per Day totals object.
 */
global class BatchHpdInitAccountRecs  implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    public final static String ACCT_AGGREGATION_DEVNAME = 'HPD_Account_Aggregation';
    global Integer iNumHpdtsInserted = 0;
    global Integer iNumHpdtsDailyInserted = 0;
    global Integer iNumHpdtsMonthlyInserted = 0;
    global Integer iNumAccountsProcessed = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;

    global BatchHpdInitAccountRecs() {
        formattedLocalStartTimeString = DateTime.now().format();
    }

    global database.querylocator start(Database.BatchableContext bc) {
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(ACCT_AGGREGATION_DEVNAME);
        List<String> accountTypes = hpdTotalSetting.HPD_Account_Types__c.split(',');
        return Database.getQueryLocator([
                SELECT  Id,MunicipalityLookup__c,Most_Recent_Hold_Per_Day__c
                FROM    Account
                WHERE   type in :accountTypes
        ]);
    }
    /**
     *
     *
     * @param bc
     * @param scope
     */
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        iNumAccountsProcessed += scope.size();
        Map<String,Object> mReturn = HpdStatsHelper.initHpdAccountTotalRecs(scope);
        List<Hold_Per_Day_Total__c> holdPerDayTotalsInserted = (List<Hold_Per_Day_Total__c>)mReturn.get('HPD_TOTALS');
        //iNumHpdtsDailyInserted += (Integer)mReturn.get('NUM_DAILY_INSERTED');
        iNumHpdtsMonthlyInserted += (Integer)mReturn.get('NUM_MONTHLY_INSERTED');
        iNumHpdtsInserted += holdPerDayTotalsInserted.size();
    }
    /**
     *
     *
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        Id batchId;
        String freq = 'Monthly';

        String subject = 'Accel SFDC Batch HPD Init for Account Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '<br/># of Accounts processed:<b> ' + iNumAccountsProcessed + '</b></br>';
        msg += '<br/># of Monthly Hold Per Day Total Records inserted:<b> ' + iNumHpdtsMonthlyInserted + '</b></br>';
      //  msg += '<br/># of Daily Hold Per Day Total Records inserted:<b> ' + iNumHpdtsMonthlyInserted + '</b></br>';
        msg += '<br/># of Hold Per Day Total Records inserted:<b> ' + iNumHpdtsInserted + '</b></br>';
        if (!Test.isRunningTest()) {
            BatchHpdLinkAccountRecsWithHpdTotals b = new BatchHpdLinkAccountRecsWithHpdTotals(freq,true);
            batchId = Database.executeBatch(b, 200);
            msg += '<br/>Firing Batch Job '+ batchId + ' (BatchHpdLinkAccountRecsWithHpdsTotals) to link Account recs with hpd '+ freq + ' total recs';
        }
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(ACCT_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
}