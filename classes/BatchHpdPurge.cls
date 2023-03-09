/**
 * BatchHpd Purge will automate deletion of HPD Daily and HPD Aggregate records.
 *
 * Records that should be deleted are where the date is > 37 (setting.Months_Back__c) months ago.
 *
 * If today is 11/18/2020, all records before and including 10/17/2017 can be purged so the oldest date
 * of records in the system will be 10/18/2017.
 */
public class BatchHpdPurge implements Database.Batchable<Sobject>, Database.Stateful {

    Integer iTotalHpdsDeleted = 0, iTotalHpdsFailed = 0, iTotalHpdsProcessed = 0;
    Map<Id, String> mHpdId_ErrMsg = new Map<Id, String>();
    Datetime startTime, endTime;

    public static Community_Async_Job_Setting__mdt setting =
            CommunityAsyncSettings.retrieveCommunityAsyncMdt(CommunityAsyncSettings.HPD_PURGE_MDT_TYPE_DEV_NAME);

    private boolean ROLL_IT_BACK = false;

    public BatchHpdPurge() {}

    /**
     * Allows a test run / rolling back the delete transaction.
     * @param rollItBack  true if we should roll back the delete trans, otherwise false.
     */
    public BatchHpdPurge(Boolean rollItBack) {
        THIS.ROLL_IT_BACK = rollItBack;
    }

    /**
     * Pull dynamic parameters such as record type names and amount of months to go back from custom meta data.
     * Fire the main query which is basically looking for the hpd records to delete based on record type
     * and the Date__c field on the Hold_Per_Day__c sObject.
     *
     * @param bc  The Batchable Context.
     * @return    A Database.QueryLocator object with the superset of results.
     *
     * @see  Community_Async_Job_Setting__mdt
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = System.now();

        List<String> rtDevNames = setting.Scope_Record_Type_Dev_Names__c.split(',');
        Integer monthsBack = Integer.valueOf(setting.Months_Back__c);
        //Date hpdDate = Date.today().addMonths(-monthsBack);
        Date hpdDate = Date.today().addMonths(-monthsBack ).addMonths(1).addDays(-1);

        String soql = '';
        soql += ' SELECT Id ';
        soql += ' FROM Hold_Per_Day__c ';
        soql += ' WHERE RecordType.DeveloperName IN :rtDevNames';
        //soql += ' AND Date__c < :hpdDate ';
        soql += ' AND Date__c <= :hpdDate ';
        return Database.getQueryLocator(soql);
    }

    /**
     * Rolls through the scope and adds records to a map for lateer deletion.
     *
     * @param bc     The Batchable Context.
     * @param scope  The scope of the batch ie. a List of Hold_Per_Day__c sObjects.
     */
    public void execute(Database.BatchableContext bc, List<Hold_Per_Day__c> scope) {
        Map<Id, Hold_Per_Day__c> mHpdsByIds = new Map<Id, Hold_Per_Day__c>();

        for (Hold_Per_Day__c hpd : scope) {
            mHpdsByIds.put(hpd.Id, hpd);
            iTotalHpdsProcessed++;
        }
        deleteHpds(mHpdsByIds);
    }

    /**
     * Attempt to delete Hold_Per_Day__c sObjects.  Perform a partial commit in the case any records fail.
     * if Any fail. store them in a persisted map of Hpd Id => Database error info.
     *
     * If the user called the overloaded constructor, roll back the transaction if it was called with true.
     *
     * @param mHpdsByIds  a Map of Hpd id => Hold_Per_Day__c sObjects to delete.
     */
    private void deleteHpds(Map<Id, Hold_Per_Day__c> mHpdsByIds) {
        Savepoint sp;
        if (ROLL_IT_BACK) {
            sp = Database.setSavePoint();
        }
        List<Database.DeleteResult> results = Database.delete(mHpdsByIds.values(), false);

        for (Integer i = 0; i < results.size(); i++) {
            Database.DeleteResult dr = results.get(i);
            if (dr.isSuccess()) {
                iTotalHpdsDeleted++;
            } else {
                Id hpdId = dr.getId();
                handleErrors(hpdId, results.get(i).getErrors());
                iTotalHpdsFailed++;
            }
        }
        System.debug(LoggingLevel.INFO, '---> deleted: ' + iTotalHpdsDeleted);
        System.debug(LoggingLevel.INFO, '---> failed: ' + iTotalHpdsFailed);
        System.debug(LoggingLevel.INFO, '---> failed hpds: ' + mHpdId_ErrMsg);

        if (ROLL_IT_BACK) {
            System.debug(Logginglevel.WARN, 'xxxxxxxxxxxxx  rolling back trans xxxxxxxx ');
            Database.rollBack(sp);
        }
    }

    /**
     * Parse out the Database.Errors list and throw in a map of hpdId => String error message.
     *
     * @param hpdId         The Hold_Per_Day__c Id.
     * @param errors        A list of Database.Error objects.
     */
    @TestVisible
    private void handleErrors(Id hpdId, List<Database.Error> errors) {

        String errorMsg = '';
        for (Database.Error error : errors) {
            errorMsg += error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
            System.debug(LoggingLevel.ERROR, hpdId + ' - ' + errorMsg);
        }
        if (!mHpdId_ErrMsg.containsKey(hpdId)) {
            mHpdId_ErrMsg.put(hpdId, errorMsg);
        }
    }

    /**
     * Create an Accel_Application__Error_log and generate an email.
     *
     * @param bc    The Batchable Context.
     */
    public void finish(Database.BatchableContext bc) {
        endTime = System.now();
        Accel_Application_Error__c log = writeLog();
        genEmail(log);
    }

    /**
     *  Generate an email to sent for the batch results.
     */
    private void genEmail(Accel_Application_Error__c log) {
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        String subject = 'Accel SFDC Batch Hpd Purge Automation process complete! ' + iTotalHpdsDeleted + ' records deleted.';
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the ';
        msg += 'Community_Async_Job_Setting__mdt as a valid address to receive debug emails for this job.<br/><br/>';
        msg += '<br/>Start Time:<b> ' + startTime.format() + '</b>';
        msg += '<br/>End Time:<b> ' + endTime.format() + '</b><br/>';
        msg += '<br/><br/># of Hold_Per_Day__c records Processed:<b> ' + iTotalHpdsProcessed + '</b>';
        msg += '<br/># of Hold_Per_Day__c Deletes that Succeeded:<b> ' + iTotalHpdsDeleted + '</b>';
        msg += '<br/># of Hold_Per_Day__c Deletes that Failed:<b> ' + iTotalHpdsFailed + '</b>';
        if (log != null && log.Id != null) {
            msg += '<br/><br/> A Log Has Been written here: <a href="' + baseUrl + '/' + log.Id + '">Job Result Log</a><br/>';
        }
        if (!mHpdId_ErrMsg.isEmpty()) {
            msg += '<br/><br/><b><font color=red>Failed Updates</font></b></br>';
            for (Id hpdId : mHpdId_ErrMsg.keySet()) {
                msg += '<br/> Hold_Per_Day__c Id=' + hpdId + '  --->Error = ' + mHpdId_ErrMsg.get(hpdId);
            }
        }
        if(ROLL_IT_BACK) {
            msg += '</br><font color=red>xxxxxxxx   Trans rolled back as desired by client. xxxxxxxxxx </font>';
        }
        List<String> emailAddys = setting.Job_Results_Email_Addresses__c.split(',');
        String body = msg;
        EmailSvc.sendEmail(emailAddys, subject, body);
    }

    /**
     * @return an Inserted Accel_Application_Error__c (if succeeded), otherwise an empty sObject.
     */
    public Accel_Application_Error__c writeLog() {

        Accel_Application_Error__c log = new Accel_Application_Error__c();

        String rtDevName = 'Salesforce_Jobs';
        Id rtId = SObjectType.Accel_Application_Error__c.getRecordTypeInfosByDeveloperName().get(rtDevName).getRecordTypeId();

        String jobName = BatchHpdPurge.class.getName();

        log.Stack_Trace__c = '';
        log.User__c = UserInfo.getUserId();
        log.Job_Name__c = jobName;
        log.RecordTypeId = rtId;
        log.Total_Executions__c = 1;
        log.Total_County_of_Dirty_Records__c = iTotalHpdsFailed;
        log.Total_Count_of_Clean_Records__c = iTotalHpdsProcessed;
        log.Total_Records_Updated__c = iTotalHpdsDeleted;
        log.Stack_Trace__c = '';
        if (ROLL_IT_BACK) {
            log.Stack_Trace__c += 'xxxx TRANS ROLLED BACK AS DESIRED BY CLIENT! xxxxxx';
        }
        if (!mHpdId_ErrMsg.isEmpty()) {
            for (Id hpdId : mHpdId_ErrMsg.keySet()) {
                log.Stack_Trace__c += hpdId + ',' + mHpdId_ErrMsg.get(hpdId);
            }
        } else {
            log.Stack_Trace__c = '--- No ERRORS Encountered ----';
            if(!ROLL_IT_BACK) {
                log.Stack_Trace__c += ' ' + log.Total_Records_Updated__c + ' records deleted';
            }
        }
        insert log;
        return log;
    }
}