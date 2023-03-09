/**
 * This class will aggregate Hold Per Day Data up to the Asset (ie Machine Level)
 * which helps with display TTM HPD, 12 Wk, 8 Wk, 4 Wk Hpd averages within the app.
 * This should not be batched at more then 100.
 * This will be chained to itself.. ie 1 for 12 month, 1 for 12 week, 1 for 8 week and 1 for 4 week.
 * as this is necessary do to the aggregation of HPD data and avoiding the 50K limit.
 */
global class BatchHpdAssetTotals implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    global Integer iNumHpdsUpdated = 0;
    global Integer iNumAssetsPRocessed = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;
    global String frequency = '';
    Integer iMonths = -12;

    global BatchHpdAssetTotals(Integer iMonths) {
        formattedLocalStartTimeString = DateTime.now().format();
        this.iMonths = iMonths;
    }
    /**
     *
     *
     * @param bc
     *
     * @return
     */
    global database.querylocator start(Database.BatchableContext bc) {
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ASSET_AGGREGATION_DEVNAME);
        return Database.getQueryLocator([
                SELECT  Id,Hold_Per_Day_Total__c
                FROM    Asset
                WHERE   RecordType.Name = 'VGT'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Asset> scope) {

        Set<Id> assetIds = new Set<Id>();
        List<Hold_Per_Day_Total__c> holdPerDaySummariesToUpd = new List<Hold_Per_Day_Total__c>();
        if(!scope.isEmpty()) {
            iNumAssetsPRocessed += scope.size();
            for(Asset ass : scope) {
                assetIds.add(ass.id);
            }
            String rtName  = 'Daily Hpd';
            String locType = null;
            holdPerDaySummariesToUpd = HpdSvc.updateHpdTotals(iMonths,'Asset',assetIds, rtName,null,locType);
            Database.SaveResult[] srList = Database.update(holdPerDaySummariesToUpd, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    iNumHpdsUpdated++;
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('HPD Total fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        Id batchId;
        String subject = 'Accel SFDC Batch HPD Asset Aggregation ('+iMonths+' Months)  Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '</br><br/># of Accounts Processed:<b> ' + iNumAssetsPRocessed + '</b>';
        msg += '<br/># of Hold Per Day Total Records updated:<b> ' + iNumHpdsUpdated + '</b></br>';
        //@TODO rework. maybe saving state in Custom Metadata type. and pulling iMonths from comma delimited string.
        if (!Test.isRunningTest() && iMonths <0) {
           if(this.iMonths == -12 ) {
               iMonths = -3;
           } else if(this.iMonths == -3) {
               iMonths = -2;
           } else if (this.iMonths == -2) {
               iMonths = -1;
           } else {
               iMonths = 0;
           }
            if(iMonths != 0) {
                BatchHpdAssetTotals b = new BatchHpdAssetTotals(iMonths);
                batchId = Database.executeBatch(b, 100);
                msg += '<br/>Firing Batch Job ' + batchId + ' (BatchHpdAssetTotals) for ' + iMonths + '  Months';
            }
        }
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ASSET_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
}