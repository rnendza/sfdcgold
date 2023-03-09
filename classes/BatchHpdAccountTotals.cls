/**
 * This class will aggregate Hold Per Day Data up to the Account Level.
 * Chained to the batch job is aggregation up to the municipal level.
 */
global class BatchHpdAccountTotals implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    global Integer iNumHpdsUpdated = 0;
    global Integer iNumAccountsPRocessed = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;
    global String frequency = '';
    
    //used only for compilation issues on deploy.. not referenced...
    public final static String ACCT_AGGREGATION_DEVNAME = 'HPD_Account_Aggregation';

    public Integer iMonths = -12;

    global BatchHpdAccountTotals(String frequency, Integer iMonths) {
        formattedLocalStartTimeString = DateTime.now().format();
        this.frequency = frequency;
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
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        List<String> accountTypes = hpdTotalSetting.HPD_Account_Types__c.split(',');
        return Database.getQueryLocator([
                SELECT  Id,Hold_Per_Day_Total__r.HPD_Total_VGT_Count__c,Hold_Per_Day_Total__c,Hold_Per_Day_Total_Daily__c
                FROM    Account
                WHERE   type in :accountTypes
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope) {

        Set<Id> accountIds = new Set<Id>();
        List<Hold_Per_Day_Total__c> holdPerDaySummariesToUpd = new List<Hold_Per_Day_Total__c>();
        if(!scope.isEmpty()) {
            iNumAccountsPRocessed += scope.size();
            for(Account account : scope) {
                accountIds.add(account.id);
            }
            String rtName  = '';
            if(frequency == 'Monthly') {
                rtName = 'Monthly Hpd';
            } else {
                rtName = 'Daily Hpd';
            }
            holdPerDaySummariesToUpd = HpdSvc.updateHpdTotals(iMonths,'Account',accountIds, rtName,frequency,null);
            Database.SaveResult[] srList = Database.update(holdPerDaySummariesToUpd, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    iNumHpdsUpdated++;
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('HPD Summary fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        Id batchId;
        String subject = 'Accel SFDC Batch HPD'+frequency+' Account Aggregation ('+iMonths+') Automation process complete! ';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '<br/>Frequency:<b> ' + frequency + '</b><br/>';
        msg += '</br><br/># of Accounts Processed:<b> ' + iNumAccountsPRocessed + '</b>';
        msg += '<br/># of Hold Per Day Total Records updated:<b> ' + iNumHpdsUpdated + '</b></br>';


        if(iMonths != 0) {
            iMonths = getFrequency();
            if (!Test.isRunningTest() && iMonths <0) {
                BatchHpdAccountTotals b = new BatchHpdAccountTotals(frequency,iMonths);
                // 1/18 Retrieve Custom metadata to set batch size dynamically. ie. query n accounts at once..
                Double dBatchSize = hpdTotalSetting.Account_Batch_Size__c;
                Integer iBatchSize = dBatchSize != null ? Integer.valueOf(dBatchSize) : 400;
                batchId = Database.executeBatch(b, iBatchSize);
                msg += '<br/>Firing Batch Job ' + batchId + ' (BatchHpdAccountTotals) for '+frequency + 'for ' + iMonths + '  Months' +
                        ' with a batch size of '+iBatchSize;
            }
        }
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }

    @TestVisible
    private Integer getFrequency() {
        Integer iMonths;
        if(this.iMonths == -12 ) {
            iMonths = -6;
        } else if(this.iMonths == -6) {
            iMonths = -3;
        } else if (this.iMonths == -3) {
            iMonths = -2;
        } else if (this.iMonths == -2) {
            iMonths = -1;
        } else if( this.iMonths == -1 && this.frequency == 'Monthly') {
            iMonths = 0;
        } else {
            iMonths = 0;
        }
        return iMonths;
    }
}