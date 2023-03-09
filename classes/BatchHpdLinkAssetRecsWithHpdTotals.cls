global class BatchHpdLinkAssetRecsWithHpdTotals implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    global Integer iNumAssetsUpdated = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;

    global BatchHpdLinkAssetRecsWithHpdTotals() {
        formattedLocalStartTimeString = DateTime.now().format();
    }
    global database.querylocator start(Database.BatchableContext bc) {
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ACCT_AGGREGATION_DEVNAME);
    //    Set<String> excludedAcctTypes   = new Set<String>{'Discontinued Account'};
        return Database.getQueryLocator([
                select  id, hold_per_day_total__c,accountId
                from    asset
                where   recordtype.name = 'VGT'
                and     (hold_per_day_total__c = null)
             //   and     account.type NOT IN :excludedAcctTypes
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Asset> scope) {
        List<Asset> assetsUpdated = HpdStatsHelper.linkAssetsWithHdp(scope);
        iNumAssetsUpdated += assetsUpdated.size();
    }

    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();

        String subject = 'Accel SFDC Batch HPD Link Asset to HPD  Total Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '<br/># of Asset Records linked: <b> ' + iNumAssetsUpdated + '</b></br>';
        Id batchId;
        if (!Test.isRunningTest()) {
            BatchHpdInitAndLinkMuniRecs b = new BatchHpdInitAndLinkMuniRecs();
            batchId = Database.executeBatch(b, 100);
            msg += '<br/>Firing Batch Job '+ batchId + ' (BatchHpdLinkAssetRecsWithHpdsTotals) to  Asset recs with hpd  total recs';
        }

        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
}