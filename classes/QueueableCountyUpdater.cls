/**
 * Note Long time SFDC Bug.. Queueables don't handle mocks well for callouts. we must dance around it.
 */
global class QueueableCountyUpdater implements  Queueable,
                                                Database.AllowsCallouts {

    Integer MAX_ACCOUNTS_TO_PROCESS = 50;
    Boolean ROLL_IT_BACK = false;
    String  countyState;
    Integer iNumAccountsWithBadData = 0;
    Integer iNumAccountsUpdated = 0;
    Integer iNumAccountsFailed = 0;
    Integer iNumTotalRecordsProcessed = 0;
    Map<Id,String> mFailedAccounts = new Map<Id,String>();
    String jobName = 'QueueableCountyUpdater';

    public final Static String BASE_EP = 'https://geo.fcc.gov/api/census/block/find?latitude=';
    public final Static String TEST_JSON_RESPONSE = '{"Block":{"FIPS":"170438460033003","bbox":[-88.077141,41.793499,-88.074175,41.79639]},"County":{"FIPS":"17043","name":"DuPage"},"State":{"FIPS":"17","code":"IL","name":"Illinois"},"status":"OK","executionTime":"0"}';

    global QueueableCountyUpdater(Integer imaxAccountsToProcess, Boolean bRollItBack) {
        MAX_ACCOUNTS_TO_PROCESS = iMaxAccountsToProcess;
        ROLL_IT_BACK = bRollItBack;
        System.debug('----> instantiating QueueableCountyUpdater with iMaxAccountsToProcess='+imaxAccountsToProcess+'...bRollItBack='+bRollItBack);
    }
    global QueueableCountyUpdater(Integer imaxAccountsToProcess, Boolean bRollItBack,String sState) {
        MAX_ACCOUNTS_TO_PROCESS = iMaxAccountsToProcess;
        ROLL_IT_BACK = bRollItBack;
        this.countyState = sState;
        System.debug('----> instantiating QueueableCountyUpdater with iMaxAccountsToProcess='+imaxAccountsToProcess+'...bRollItBack='+bRollItBack);
    }
    /**
     * Implements the queueable execute interface.
     * @param ctx The Queueable context.
     */
    global void execute(QueueableContext ctx){
        System.debug(LoggingLevel.INFO, '---> in queueableCountyUpdater with ctx: '+ctx);
        if(!Test.isRunningTest()) {
            performExecute();
        }
    }
    public void performExecute() {
        List<Account> accountsToSearch = filterAccounts();
        Map<Id,Account> mAccountsToUpd = new Map<Id,Account>();
        if(!accountsToSearch.isEmpty()) {
            mAccountsToUpd = calloutToProvider(accountsToSearch);
        }
        System.debug('---> total number of accounts to update:'+mAccountsToUpd.size());
        performAccountUpdates(mAccountsToUpd);

        if(!ROLL_IT_BACK) {
            writeLog();
        }
    }

    /**
     * Rolls through the accounts for which we found county information and updates the Account.County__c field
     * to the valid county as well as the Account.County_Auto_Updated__c field.
     *
     * @implNotes
     * If the user supplied the rollItBack parameter = true in the constructor. The Database trans will be rolled back
     *
     *`@param   mAccounts  The List of Account sObjects to update.
     *
     * @see Account.County__c
     * @see https://geo.fcc.gov/api/census/#!/block/get_block_find  (Source of county data)
     */
    public void performAccountUpdates( Map<Id,Account> mAccounts) {

        Savepoint sp = Database.setSavepoint();
        List<Database.SaveResult> results = Database.update(mAccounts.values(), false);
        Accel_Application_Error__c log = retrieveCurrentLog(jobName);

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results.get(i);
            iNumTotalRecordsProcessed++;
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

    public List<Account> filterAccounts() {

        List<Account> accounts = new List<Account>();
        if(this.countyState == null) {
            accounts = [
                    SELECT Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy
                    //  SELECT  Id, County__c, County_Auto_Updated__c,County_LU_Auto_Update__c,ShippingLatitude,ShippingLongitude

                    FROM Account
                    WHERE County_Auto_Updated__c = FALSE
                    ORDER BY LastModifiedDate DESC
            ];
        } else {
            accounts = [
                    SELECT Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy,
                            ShippingState
                               //     SELECT Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy,
                           // ShippingState
                    FROM Account
                    WHERE County_Auto_Updated__c = FALSE
                    AND   ShippingState = :countyState
                    ORDER BY LastModifiedDate DESC
            ];
        }
        System.debug('----> Total # of accounts found with county_auto_updated__c = false ..'+accounts.size());
        List<Account> accountsToSearch = new List<Account>();
        List<Account> accountsWithBadData = new List<Account>();
        Integer iUpdateCount = 0;
        for(Account account : accounts) {
            if(account.ShippingLatitude != null) {
                if (iUpdateCount < MAX_ACCOUNTS_TO_PROCESS) {
                    accountsToSearch.add(account);
                    iUpdateCount++;
                }
            } else {
                accountsWithBadData.add(account);
            }
        }
        System.debug('-----> Number of Accounts with Bad Data:'+accountsWithBadData.size());
        System.debug('-----> Number of Accounts to Process:'+accountsToSearch);

        this.iNumAccountsWithBadData += accountsWithBadData.size();
        return accountsToSearch;
    }

    public Map<Id, Account> calloutToProvider(List<Account> accounts) {
        Map<Id, Account> mAccountsToUpd = new Map<Id, Account>();

        String baseEp = BASE_EP;

        for (Account account : accounts) {
            String ep = baseEp;
            ep += account.ShippingLatitude + '&longitude=' + account.ShippingLongitude + '&format=json';
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ep);
            req.setMethod('GET');

            Http http = new Http();
            String jsonResponse = '';
            if (!Test.isRunningTest()) {
                HttpResponse response = http.send(req);
                jsonResponse = response.getBody();
            } else {

                jsonResponse = TEST_JSON_RESPONSE;
            }

            Map<String, Object> m = (Map<String, Object>) Json.deserializeUntyped(jsonResponse);
            Map<String, Object> m2 = (Map<String, Object>) m.get('County');
            String county = (String) m2.get('name');

            if (String.isNotEmpty(county)) {
               // account.County__c = county;
                account.County_Auto_Updated__c = true;
                String geoAccuracy = account.ShippingGeocodeAccuracy;
                if(geoAccuracy != null) {
                    account.Shipping_Address_Accuracy__c = CustomMetadataSvc.retrieveGeoAccuracyDisplayValue(geoAccuracy);
                }
                mAccountsToUpd.put(account.Id, account);
            } else {
                String geoAccuracy = account.ShippingGeocodeAccuracy;
                if(geoAccuracy != null) {
                    account.Shipping_Address_Accuracy__c = CustomMetadataSvc.retrieveGeoAccuracyDisplayValue(geoAccuracy);
                } else {
                    account.Shipping_Address_Accuracy__c = 'Weak';
                }
            }
        }
        return mAccountsToUpd;
    }

    public void writeLog() {

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

    @TestVisible
    private void clearAutoUpdateCheckbox() {
        List<Account> accounts = [
            SELECT Id, County_Auto_Updated__c FROM Account WHERE County_Auto_Updated__C = TRUE LIMIT :MAX_ACCOUNTS_TO_PROCESS
        ];
        for(Account a : accounts) {
            a.County_Auto_Updated__C = FALSE;
        }
        update accounts;
    }
}