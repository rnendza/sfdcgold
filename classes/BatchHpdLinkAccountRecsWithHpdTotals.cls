/**
 * Links account to newly created hold per day total reqs.
 * if a freq of 'Monthly' is passed in the constructor.. chains this same job to then do 'Daily' as well.
 */
global class BatchHpdLinkAccountRecsWithHpdTotals implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    global Integer iNumAccountsUpdated = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;
    global String frequency = '';
    global Boolean initAssets = false;

    global BatchHpdLinkAccountRecsWithHpdTotals(String frequency, Boolean pInitAssets) {
        formattedLocalStartTimeString = DateTime.now().format();
        this.frequency = frequency;
        this.initAssets = pInitAssets;
    }
    global database.querylocator start(Database.BatchableContext bc) {
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        List<String> accountTypes = hpdTotalSetting.HPD_Account_Types__c.split(',');
        return Database.getQueryLocator([
                select  id, hold_per_day_total__c, hold_per_day_total_daily__c
                from    account
                where   Type in :accountTypes
                and     (hold_per_day_total__c = null or hold_per_day_total_daily__c = null)
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> accountsUpdated = HpdStatsHelper.linkAccountsWithHdp(scope,this.frequency);
        iNumAccountsUpdated += accountsUpdated.size();
    }

    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();

        String subject = 'Accel SFDC Batch HPD Link Account to HPD '+frequency+' Total Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '<br/> boolean initAssets:<b>'+initAssets+'</b><br/>';
        msg += '<br/># of Account Records linked for '+frequency+':<b> ' + iNumAccountsUpdated + '</b></br>';
        Id batchId;

//        if (!Test.isRunningTest() && 1 == 2 /*frequency == 'Monthly'*/) {
//            this.frequency = 'Daily';
//            BatchHpdLinkAccountRecsWithHpdTotals b = new BatchHpdLinkAccountRecsWithHpdTotals('Daily',true);
//            batchId = Database.executeBatch(b, 200);
//            msg += '<br/>Firing Batch Job again ' + batchId + ' to link ' + frequency +' account totals';
//        } else {
           if(!Test.isRunningTest() && initAssets){
                BatchHpdInitAssetRecs b = new BatchHpdInitAssetRecs();
                batchId = Database.executeBatch(b, 200);
                msg += '<br/>Firing Batch Job to init asset recs  ' + batchId ;
            }
     //   }
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
}