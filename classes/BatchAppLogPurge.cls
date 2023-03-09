/**
 * Batch App Log Purge will run on a weekly basis.
 * 
 * Records of the Accel_Application_Error__c object will be deleted 30 days after creation.
 * 
 */

public class BatchAppLogPurge implements Database.Batchable<Sobject>, Database.Stateful {

    Integer iTotalAppLogsDeleted = 0, iTotalAppLogsFailed = 0, iTotalAppLogsProcessed = 0;
    Map<Id, String> mAppLogId_ErrMsg = new Map<Id, String>();
    Datetime startTime, endTime;

    public static Batch_Job_Setting__mdt customMdt = 
        BatchjobSvc.queryForMetadata('App_Log_Batch_Purge');

    private boolean ROLL_IT_BACK = false;

    public BatchAppLogPurge() {}

    public BatchAppLogPurge(Boolean rollItBack) {
        THIS.ROLL_IT_BACK = rollItBack;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = System.now();

        String soql = '';
        soql += ' SELECT Id, CreatedDate ';
        soql += ' FROM Accel_Application_Error__c';
        soql += ' WHERE CreatedDate < LAST_N_DAYS:30';
        return Database.getQueryLocator(soql);
    }

    public void execute(DataBase.BatchableContext bc, List<Accel_Application_Error__c> scope) {
        Map<Id, Accel_Application_Error__c> appLogByIds = new Map<Id, Accel_Application_Error__c>();

        for(Accel_Application_Error__c ale : scope) {
            appLogByIds.put(ale.Id, ale);
            iTotalAppLogsProcessed++;
        }
        deleteAppLogs(appLogByIds);
    }

    private void deleteAppLogs(Map<Id, Accel_Application_Error__c> appLogByIds) {
        Savepoint sp;
        if (ROLL_IT_BACK) {
            sp = Database.setSavePoint();
        }

        List<Database.DeleteResult> results = Database.delete(appLogByIds.values(), false);

        for (Integer i = 0; i < results.size(); i++) {
            Database.DeleteResult dr = results.get(i);
            if (dr.isSuccess()) {
                iTotalAppLogsDeleted++;
            } 
        }
        System.debug(LoggingLevel.INFO, '---> deleted: ' + iTotalAppLogsDeleted);
        System.debug(LoggingLevel.INFO, '---> failed: ' + iTotalAppLogsFailed);

        if (ROLL_IT_BACK) {
            System.debug(Logginglevel.WARN, 'xxxxxxxxxxxxx  rolling back trans xxxxxxxx ');
            Database.rollBack(sp);
        }
    }


    public void finish(Database.BatchableContext bc) {
        endTime = System.now();

        genEmail();
    }

    /**
     * Generate an email to send for batch results.
     */
    private void genEmail() {
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        String subject = 'Accel SFDC Batch AppLog Purge Automation Process Complete! ' + iTotalAppLogsDeleted + ' records deleted.';
        String msg = '<br/>If you are receiving this email, it is because your email address was added to the ';
        msg += 'Batch_Job_Setting__mdt App Log Purge as a valid address to receive debug emails for this job.<br/><br/>';
        msg += '<br/>Start Time:<b> ' + startTime.format() + '</b>';
        msg += '<br/>End Time:<b> ' + endTime.format() + '</b><br/>';
        msg += '<br/><br/># of Accel_Application_Error__c records Processed:<b> ' + iTotalAppLogsProcessed + '</b>';
        msg += '<br/># of Accel_Application_Error__c Deletes that Succeeded:<b> ' + iTotalAppLogsDeleted + '</b>';


        if(ROLL_IT_BACK) {
            msg += '</br><font color=red>xxxxxxxx   Trans rolled back as desired by client. xxxxxxxxxx </font>';
        }

        List<String> emailAddys = customMdt.Usernames_to_email__c.split(',');
        String body = msg;
        EmailSvc.sendEmail(emailAddys, subject, body);

    }
}