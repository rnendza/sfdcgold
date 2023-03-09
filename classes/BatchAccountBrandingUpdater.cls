/**
 * ===  BatchAccountBrandingUpdater =====
 *
 * This class will be used to update Account.Branding__c for existing account records.
 *
 * Pseudo: (Expected execution time. 2.5hrs)
 *
 * 1. SELECT All Accounts where Account.Branding__c = NULL (no value assined to picklist yet.
 *
 * 2a.  If criteria xzy set Account.Branding__c = 'Tom's Amusements'  ~~ a couple of hundred at best.
 *  b.  Else set Account.Branding__c  'Accel Entertainment ~~ about 20K
 *
 * 3. Fire update using partial commit (update whatever accounts we can.
 *
 * 4. Record the account Id and reason we could not update the account.
 *
 * 5. Send an email with processed, updated, failed as well as failure info.
 *
 * 6. Write a log to Accel_Application__c errors with similar results to the email
 *
 */
public class BatchAccountBrandingUpdater implements Database.Batchable<Sobject>, Database.Stateful {

    Datetime startTime, endTime;

    Boolean ROLL_IT_BACK = false;
    Integer iNumAccountsWithBadData = 0;
    Integer iNumAccountsUpdated = 0;
    Integer iNumAccountsFailed = 0;
    Integer iNumTotalRecordsProcessed = 0;
    Map<Id,String> mFailedAccounts = new Map<Id,String>();
    String jobName = 'BatchAccountBrandingUpdater';
    public final static String  OWA_EMAIL_ADDY          = 'crm@accelentertainment.com';
    public final static string BRANDING_AE = 'Accel Entertainment';
    public final static string BRANDING_TOMS = 'Tom\'s Amusements';
    public final static String  ATTACHMENT_CONTENT_TYPE = 'text/csv';
    public final static String  ATTACHMENT_FILE_EXT     = '.csv';
    List<Account> allAccounts = new List<Account>();

    String  tomsAccountsCsv = '';


    public BatchAccountBrandingUpdater() {}

    /**
     * Allows a test run / rolling back the delete transaction.
     * @param rollItBack  true if we should roll back the delete trans, otherwise false.
     */
    public BatchAccountBrandingUpdater(Boolean rollItBack) {
        THIS.ROLL_IT_BACK = rollItBack;
    }


    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = System.now();

        return Database.getQueryLocator([
                SELECT      Id, Branding__c,ShippingState,Type,RecordType.DeveloperName,CreatedBy.Username,CreatedDate
                FROM        Account
                WHERE       Branding__c = NULL
                ORDER BY    CreatedDate DESC ]
        );
    }

    /**
     * Rolls through the scope and adds records to a map for lateer deletion.
     *
     * @param bc     The Batchable Context.
     * @param scope  The scope of the batch ie. a List of Hold_Per_Day__c sObjects.
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        Map<Id, Account> mAccountsByIds = new Map<Id, Account>();

        for (Account account : scope) {
            mAccountsByIds.put(account.Id, account);
            iNumTotalRecordsProcessed++;
        }
        Map<Id,Account> mAccountsToUpd = modifyAccounts(mAccountsByIds.values());
        updateAccounts(mAccountsToUpd);
    }

    private Map<Id,Account> modifyAccounts(List<Account> accounts) {
        Map<Id, Account> mAccountsToUpd = new Map<Id, Account>();

        for (Account account : accounts) {
           if(account.ShippingState == 'GA') {
               account.Branding__c = BRANDING_TOMS;
           } else {
               account.Branding__C = BRANDING_AE;
           }
            mAccountsToUpd.put(account.Id,account);
        }
        return mAccountsToUpd;
    }


    private void updateAccounts(Map<Id, Account> mAccounts) {
        Savepoint sp = Database.setSavepoint();
        List<Database.SaveResult> results = Database.update(mAccounts.values(), false);
        Accel_Application_Error__c log = retrieveCurrentLog(jobName);

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results.get(i);
            if (!sr.isSuccess()) {
                String errorMsg = '';
                for (Database.Error error : results.get(i).getErrors()) {
                    errorMsg += error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
                    System.debug(LoggingLevel.ERROR, mAccounts.values().get(i).Id + ' - ' + errorMsg);
                }
                Boolean storeLog = true;
                if( log != null && log.Stack_Trace__c != null) {
                    if(log.Stack_Trace__c.contains(mAccounts.values().get(i).Id)) {
                        storeLog = false;
                    }
                }
                if(storeLog) {
                    mFailedAccounts.put(mAccounts.values().get(i).Id, errorMsg);
                    iNumAccountsFailed++;
                }

            } else {
                allAccounts.add(mAccounts.get(sr.getId()));
                iNumAccountsUpdated++;
            }
        }
        if (ROLL_IT_BACK) {
            System.debug(LoggingLevel.WARN, 'xxxxx rolling back trans due to user supplied parameter');
            Database.rollback(sp);
        } else {
            System.debug(LoggingLevel.INFO, iNumAccountsUpdated + ' successfully updated');
        }
    }


    public void finish(Database.BatchableContext bc) {
        endTime = System.now();
        Accel_Application_Error__c log = writeLog();
        genEmail(log,allAccounts);
    }

    public Accel_Application_Error__c writeLog() {

        String rtDevName ='Salesforce_Jobs';
        Id rtId =  SObjectType.Accel_Application_Error__c.getRecordTypeInfosByDeveloperName().get(rtDevName).getRecordTypeId();

        Accel_Application_Error__c log = retrieveCurrentLog(jobName);

        if( log != null) {
            log.User__c = UserInfo.getUserId();
            log.Total_County_of_Dirty_Records__c = this.iNumAccountsWithBadData;
            log.Total_Records_Updated__c += iNumAccountsUpdated;
            if(!mFailedAccounts.isEmpty()) {
                if(log.Stack_Trace__c == null) {
                    log.Stack_Trace__c = 'DML Errors ---> ';
                }
                if(log.Stack_Trace__c.length() < 131072) {
                    for (Id accountId : mFailedAccounts.keySet()) {
                        log.Stack_Trace__c += ',' + accountId + ',' + mFailedAccounts.get(accountId) ;
                    }
                }
            }
            if(log.Total_Executions__c == null) {
                log.Total_Executions__c = 1;
            } else {
                log.Total_Executions__c = log.Total_Executions__c + 1;
            }
            if(log.Total_Count_of_Clean_Records__c == null) {
                log.Total_Count_of_Clean_Records__c = iNumTotalRecordsProcessed;
            } else {
                log.Total_Count_of_Clean_Records__c= log.Total_Count_of_Clean_Records__c + iNumTotalRecordsProcessed;
            }
            update log;
        } else {
            log = new Accel_Application_Error__c();
            log.Stack_Trace__c = 'DML Errors ---> ';
            log.User__c = UserInfo.getUserId();
            log.Job_Name__c = jobName;
            log.RecordTypeId = rtId;
            log.Total_Executions__c = 1;
            log.Total_County_of_Dirty_Records__c = iNumAccountsWithBadData;
            log.Total_Count_of_Clean_Records__c = iNumTotalRecordsProcessed;
            log.Total_Records_Updated__c = iNumAccountsUpdated;
            log.Stack_Trace__c = '';
            if(!mFailedAccounts.isEmpty()) {
                for(Id accountId : mFailedAccounts.keySet()) {
                    log.Stack_Trace__c += accountId+','+mFailedAccounts.get(accountId);
                }
            }
            insert log;
        }
        return log;
    }

    private Accel_Application_Error__c retrieveCurrentLog(String jobName) {

        Accel_Application_Error__c log;

        List<Accel_Application_Error__c> appErrors = [
                SELECT Id, Stack_Trace__c,User__c, Job_Name__c,Total_County_of_Dirty_Records__c,
                        Total_Records_Updated__c,Total_Executions__c,Total_Count_of_Clean_Records__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = :jobName
        ];
        if(!appErrors.isEmpty()) {
            log = appErrors[0];
        }
        return log;
    }

    /**
 *  Generate an email to sent for the batch results.
 */
    private void genEmail(Accel_Application_Error__c log , List<Account> accounts) {
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        Integer iNumAeAccounts = [SELECT Count() FROM Account WHERE Branding__c = :BRANDING_AE AND Id IN :allAccounts] ;
        Integer iNumTomsAccounts = [SELECT Count() FROM Account WHERE Branding__c = :BRANDING_TOMS AND Id IN :allAccounts];

        String subject = 'Accel SFDC Batch Account Branding Update Automation process complete! ' + iNumAccountsUpdated + ' records updated.';
//        String msg = '<br/>If you are receiving this email,it is because your email address was added to the ';
//        msg += 'Community_Async_Job_Setting__mdt as a valid address to receive debug emails for this job.<br/><br/>';
        String msg = '';
        msg += '<br/>Start Time:<b> ' + startTime.format() + '</b>';
        msg += '<br/>End Time:<b> ' + endTime.format() + '</b><br/>';
        msg += '<br/><br/># of Account records Processed:<b> ' + iNumTotalRecordsProcessed + '</b>';
        msg += '<br/># of Account Updates that Succeeded:<b> ' + iNumAccountsUpdated + '</b>';
        msg += '<br/># of Account Updates that Failed:<b> ' + iNumAccountsFailed + '</b>';
        msg += '<br/># of Accounts Updated to Branding for AE:<b> ' + iNumAeAccounts + '</b>';
        msg += '<br/># of Accounts Updated to Branding for Toms:<b> ' + iNumTomsAccounts + '</b>';
        if (log != null && log.Id != null) {
            msg += '<br/><br/> A Log Has Been written here: <a href="' + baseUrl + '/' + log.Id + '">Job Result Log</a><br/>';
        }
        if (!mFailedAccounts.isEmpty()) {
            msg += '<br/><br/><b><font color=red>Failed Updates</font></b></br>';
            for (Id hpdId : mFailedAccounts.keySet()) {
                msg += '<br/> Account Id=' + hpdId + '  --->Error = ' + mFailedAccounts.get(hpdId);
            }
        }
        if(ROLL_IT_BACK) {
            msg += '</br><font color=red>xxxxxxxx   Trans rolled back as desired by client. xxxxxxxxxx </font>';
        }
        List<Messaging.EmailFileAttachment> emailFileAttachments;

        Messaging.EmailFileAttachment csvAttcAllAccounts = buildCsvAttachmentAllAccounts('branding_export',accounts);
        if(csvAttcAllAccounts != null && csvAttcAllAccounts.getBody() != null) {
            emailFileAttachments = new List<Messaging.EmailFileAttachment>();
            emailFileAttachments.add( csvAttcAllAccounts );
        }

        List<String> emailAddys = new List<String>{'rick@chicagosalesforceconsulting.com'};
        String body = msg;
        EmailSvc.sendEmail( emailAddys,null,subject,body,emailFileAttachments,OWA_EMAIL_ADDY );
    }


    public Messaging.EmailFileAttachment buildCsvAttachmentAllAccounts(String csvName, List<Account> accounts) {

        Messaging.EmailFileAttachment csvAttc   = new Messaging.EmailFileAttachment();
        AccountBrandingCsv csvBuilder           = new AccountBrandingCsv();
        String csvData                          = csvBuilder.generateCsv( accounts );
        csvName += '_'+System.now()+ATTACHMENT_FILE_EXT;

        if(csvData != null && csvData != '') {
            Blob csvBlob = Blob.valueOf(csvData);
            csvAttc.setFileName(csvName);
            csvAttc.setContentType( ATTACHMENT_CONTENT_TYPE );
            csvAttc.setBody(csvBlob);
        }
        return csvAttc;
    }

    public Messaging.EmailFileAttachment buildCsvAttachmentAllErrors(String csvName, Map<Id,String> mErrorsByIds) {

        Messaging.EmailFileAttachment csvAttc   = new Messaging.EmailFileAttachment();
        SObjectErrorCsv csvBuilder           = new SObjectErrorCsv();
        String csvData                          = csvBuilder.generateCsv( mErrorsByIds );
        csvName += '_'+System.now()+ATTACHMENT_FILE_EXT;

        if(csvData != null && csvData != '') {
            Blob csvBlob = Blob.valueOf(csvData);
            csvAttc.setFileName(csvName);
            csvAttc.setContentType( ATTACHMENT_CONTENT_TYPE );
            csvAttc.setBody(csvBlob);
        }
        return csvAttc;
    }
}