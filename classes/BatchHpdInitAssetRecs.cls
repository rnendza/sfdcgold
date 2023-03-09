/**
 *
 */
global class BatchHpdInitAssetRecs implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    public final static String ASSET_AGGREGATION_DEVNAME = 'HPD_Account_Aggregation'; //@TODO create asset setting
    global Integer iNumHpdtsInserted = 0;
    global Integer iNumAssetsProcessed = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;

    global BatchHpdInitAssetRecs() {
        formattedLocalStartTimeString = DateTime.now().format();
    }

    /**
     *
     *
     * @param bc
     * @return
     */
    global database.querylocator start(Database.BatchableContext bc) {
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(ASSET_AGGREGATION_DEVNAME);
//        Set<String> excludedAcctTypes = new Set<String>{
//                'Discontinued Account'
//        };
        return Database.getQueryLocator([
                SELECT Id, accountId, account.most_recent_hold_per_day__c
                FROM Asset
                WHERE recordtype.name = 'VGT'
              //  and Account.Type NOT IN :excludedAcctTypes
        ]);
    }
    /**
     *
     *
     * @param bc
     * @param scope
     */
    global void execute(Database.BatchableContext bc, List<Asset> scope) {
        iNumAssetsProcessed += scope.size();
        Map<String,Object> mReturn = HpdStatsHelper.initHpdAssetTotalRecs(scope);
        List<Hold_Per_Day_Total__c> holdPerDayTotalsInserted = (List<Hold_Per_Day_Total__c>)mReturn.get('HPD_TOTALS');
        iNumHpdtsInserted += holdPerDayTotalsInserted.size();
    }
    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        Id batchId;
        //String freq = 'Daily';

        String subject = 'Accel SFDC Batch HPD Init for Asset Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '<br/># of Assets processed:<b> ' + iNumAssetsProcessed + '</b></br>';
        msg += '<br/># of Hold Per Day Total Records inserted:<b> ' + iNumHpdtsInserted + '</b></br>';
       if (!Test.isRunningTest()) {
            BatchHpdLinkAssetRecsWithHpdTotals b = new BatchHpdLinkAssetRecsWithHpdTotals();
            batchId = Database.executeBatch(b, 100);
            msg += '<br/>Firing Batch Job '+ batchId + ' (BatchHpdLinkAssetRecsWithHpdsTotals) to  Asset recs with hpd  total recs';
        }
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(ASSET_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys, subject, body);
    }
}