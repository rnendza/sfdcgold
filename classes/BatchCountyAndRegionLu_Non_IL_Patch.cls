public class BatchCountyAndRegionLu_Non_IL_Patch implements Database.Batchable<Sobject>, Database.Stateful {

    Datetime startTime, endTime;

    Boolean ROLL_IT_BACK = false;
    Integer iNumAccountsWithBadData = 0;
    Integer iNumAccountsUpdated = 0;
    Integer iNumAccountsFailed = 0;
    Integer iNumTotalRecordsProcessed = 0;
    Map<Id,String> mFailedAccounts = new Map<Id,String>();
    String jobName = 'BatchCountyAndRegionLu_Non_IL_Patch';


    public BatchCountyAndRegionLu_Non_IL_Patch() {}

    /**
     * Allows a test run / rolling back the delete transaction.
     * @param rollItBack  true if we should roll back the delete trans, otherwise false.
     */
    public BatchCountyAndRegionLu_Non_IL_Patch(Boolean rollItBack) {
        THIS.ROLL_IT_BACK = rollItBack;
    }


    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = System.now();

        return Database.getQueryLocator(
        [
                SELECT Id,  County_LU_Auto_Update__c,County_LU__c,Covid_Region__c,ShippingState,County_LU__r.State__c
                        //SELECT Id, County__c, County_LU_Auto_Update__c,County_LU__c,Covid_Region__c,ShippingState,County_LU__r.State__c

                FROM Account
                WHERE ShippingState != 'IL'
                AND County_LU__r.State__c = 'IL'
                ORDER BY LastModifiedDate DESC
        ]
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

        Map<Id,County__c> mCountiesByIds = new Map<Id,County__c>([
                SELECT Id,Name,Covaid_Region__c,State__c
                FROM   County__c
        ]);

        Map<String,County__c> mCountiesByNames = new Map<String,County__c>();
        for(County__c county : mCountiesByIds.values()) {
            mCountiesByNames.put(county.Name + '_'+county.State__c, county);
        }

       /* for(Account account : accounts) {
            if(account.County__c != null && account.ShippingState != null) {
                String concatKey = account.County__c+'_'+account.ShippingState;
                County__c county = mCountiesByNames.get(concatKey);
                if(county != null) {
                    account.County_LU__c = county.Id;
                    account.Covid_Region_LU__c = county.Covaid_Region__c;
                    account.County_LU_Auto_Update__c = TRUE;
                    mAccountsToUpd.put(account.Id,account);
                } else {
                    //blank it out
                    account.County_LU__c = null;
                    account.Covid_Region_LU__c = null;
                    account.County_LU_Auto_Update__c = FALSE;
                    mAccountsToUpd.put(account.Id,account);
                }
            }
        }*/
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
        genEmail(log);
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
    private void genEmail(Accel_Application_Error__c log) {
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

        String subject = 'Accel SFDC Batch Account County And Region LU Patch Process complete! ' + iNumAccountsUpdated + ' records updated.';
        String msg = '';
        msg += '<br/>Start Time:<b> ' + startTime.format() + '</b>';
        msg += '<br/>End Time:<b> ' + endTime.format() + '</b><br/>';
        msg += '<br/><br/># of Account records Processed:<b> ' + iNumTotalRecordsProcessed + '</b>';
        msg += '<br/># of Account Updates that Succeeded:<b> ' + iNumAccountsUpdated + '</b>';
        msg += '<br/># of Account Updates that Failed:<b> ' + iNumAccountsFailed + '</b>';
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
        List<String> emailAddys = new List<String>{'rick@chicagosalesforceconsulting.com'};
        String body = msg;
        EmailSvc.sendEmail(emailAddys, subject, body);
    }
}