/**
 * Essentially rolls up locations (accounts) to the muni level on HPD Totals Records.
 */
global class BatchHpdMunicipalityTotals implements Database.Batchable<Sobject>, Database.Stateful {

    global Integer iNumHpdsUpdated = 0;
    global Integer iNumHpdUpdatesFailed = 0;
    global Integer iNumAccountHpdRecordsProcessed = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;

    //not used. used only to solve compilation issues.
    public final static String MUNICIPALITY_AGGREGATION_DEVNAME = 'HPD_Municipality_Aggregation';

    public String frequency;

    global BatchHpdMunicipalityTotals( String frequency ) {
        formattedLocalStartTimeString = DateTime.now().format();
        this.frequency = frequency;
    }
    /**
     * Query for all HPD Total records that are account based (location recordtype) and have a municipality.
     * @param bc - a batchable ctx.
     * @return ql -  (normally 200 records by default)
     */
    global database.querylocator start(Database.BatchableContext bc) {
        HPD_Total_Setting__mdt hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.MUNICIPALITY_AGGREGATION_DEVNAME);
        String rtDevName = hpdTotalSetting.Record_type_Dev_Name_To_Process__c;
        return Database.getQueryLocator([
                SELECT Id,Municipality__c
                FROM Hold_Per_Day_total__c
                WHERE Recordtype.developername = :rtDevName
                and Municipality__c != null
                and Frequency__c = :frequency
        ]);
    }
    /**
     * @param bc - a batchable ctx.
     * @param scope - a list of Hold_Per_Date_Total__c sObjects sent by the query locator from the start method.
     */
    global void execute(Database.BatchableContext bc, List<Hold_Per_Day_Total__c> scope) {
        Set<Id> muniIds = new Set<Id>();
        List<Hold_Per_Day_Total__c> holdPerDayTotalsToUpd = new List<Hold_Per_Day_Total__c>();
        if (!scope.isEmpty()) {
            iNumAccountHpdRecordsProcessed +=scope.size();
            for (Hold_Per_Day_Total__c hpdt : scope) {
                muniIds.add(hpdt.municipality__c);
            }
            //all muni totals.
            String locType = null;
            holdPerDayTotalsToUpd = HpdSvc.updateHpdTotals(null,'Municipality',muniIds, 'Municipality',frequency,locType);
            Database.SaveResult[] srList = Database.update(holdPerDayTotalsToUpd, false);
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
            //only munis with accel loc totals.
            locType = 'Accel Account';
            holdPerDayTotalsToUpd = HpdSvc.updateHpdTotals(null,'Municipality',muniIds, 'Municipality',frequency,locType);
            srList = Database.update(holdPerDayTotalsToUpd, false);
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

    /**
     * Sends out an email with final batch processing results.
     * @param bc - a batchable ctx.
     */
    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        String subject = 'Accel SFDC Batch HPD Municipality Automation (both daily and monthly) process complete! ';

        String msg = '<br/> If you are receiving this email, it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/><br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b>';
        msg += '<br/>Frequency:<b> ' + frequency + '</b>';
        msg += '<br/><br/># of Account Hold Per Day Totals Records processed:<b> ' + iNumAccountHpdRecordsProcessed + '</b>';
        msg += '<br/># of Hold Per Day Totals Records successfully updated:<b> ' + iNumHpdsUpdated + '</b>';
        msg += '<br/># of Hold Per Day Totals Records NOT successfully updated due to errors:<b> ' + iNumHpdUpdatesFailed+ '</b>';
        msg += '</br><br/>';

        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.MUNICIPALITY_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys, subject, body);
    }
}