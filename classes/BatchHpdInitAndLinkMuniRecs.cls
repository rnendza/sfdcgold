/**
 * Inits zero valued hpd total monthly and daily records and then puts a link on the account record back
 * to this records. (does this so future processes can be mere updates rather then upsert / insert.
 */
global class BatchHpdInitAndLinkMuniRecs  implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    global Integer iNumMonthlyHpdtsInserted = 0;
    global Integer iNumDailyHpdtsInserted = 0;
    global Integer iTotalInserted = 0;
    global Integer iNumMonthlyHpdtsUpdated = 0;
    global Integer iNumDailyHpdtsUpdated = 0;
    global Integer iTotalUpdated = 0;
    global Integer iNumMunis = 0;

    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;

    global BatchHpdInitAndLinkMuniRecs() {
        formattedLocalStartTimeString = DateTime.now().format();
    }
    global database.querylocator start(Database.BatchableContext bc) {
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.MUNICIPALITY_AGGREGATION_DEVNAME);

        return Database.getQueryLocator([
                SELECT  Id,Hold_Per_Day_Total__c, Hold_Per_Day_Total_Daily__c
                FROM    Municipality__c
        ]);
    }
    /**
     *
     *
     * @param bc
     * @param scope
     */
    global void execute(Database.BatchableContext bc, List<Municipality__c> scope) {
        iNumMunis += scope.size();
        Map<String,Object> mReturn = HpdStatsHelper.initHpdMunicipalityTotalRecs(scope);
      //  iNumDailyHpdtsInserted += (Integer)mReturn.get('NUM_DAILY_INSERTED');
        iNumMonthlyHpdtsInserted += (Integer)mReturn.get('NUM_MONTHLY_INSERTED');
      //  List<Municipality__c> dailyMuniUpdates = HpdStatsHelper.linkMunicipalityWithHpd(scope,'Daily');
        List<Municipality__c> monthlyMuniUpdates = HpdStatsHelper.linkMunicipalityWithHpd(scope,'Monthly');
       // iNumDailyHpdtsUpdated += dailyMuniUpdates.size();
        iNumMonthlyHpdtsUpdated += monthlyMuniUpdates.size();
    }
    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        iTotalInserted = iNumMonthlyHpdtsInserted + iNumDailyHpdtsInserted;
        iTotalUpdated = iNumMonthlyHpdtsUpdated + iNumDailyHpdtsUpdated;

        String subject = 'Accel SFDC Batch HPD Init and link for Municipality Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '<br/># of Munis Processed:<b> ' + iNumMunis + '</b></br>';
       // msg += '<br/># of Daily Muni Hpds inserted:<b> ' + iNumDailyHpdtsInserted + '</b></br>';
        msg += '<br/># of Monthly Muni Hpds inserted:<b> ' + iNumMonthlyHpdtsInserted+ '</b></br>';
        msg += '<br/># of Hold Per Day Totals inserted for Munis:<b> ' + iTotalInserted + '</b></br>';
       // msg += '<br/># of Daily Muni Hpds linked:<b> ' + iNumDailyHpdtsUpdated + '</b></br>';
        msg += '<br/># of Monthly Muni Hpds linked:<b> ' + iNumMonthlyHpdtsUpdated+ '</b></br>';
        msg += '<br/># of Hold Per Day Totals linked to for Munis:<b> ' + iTotalUpdated+ '</b></br>';

        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.MUNICIPALITY_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
}