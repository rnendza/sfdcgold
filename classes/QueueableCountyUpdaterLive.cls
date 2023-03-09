/**
 * This is a revamp of a previous class which was scheduled to fire on a 1 minute interval.
 * This is intended to be called live (ie in the account trigger after update) and eventually
 * meant to deprecate the previously scheduled version (QueueableCountyUpdater).
 *
 * Note Long time SFDC Bug.. Queueables don't handle mocks well for callouts. we must dance around it.
 *
 * @see QueueableCountyUpdater
 *
 * @todo incorporate failure email logic.
 * @todo create custom mdt for this.
 */
global without sharing class QueueableCountyUpdaterLive implements  Queueable, Database.AllowsCallouts {

    Integer MAX_ACCOUNTS_TO_PROCESS = 50;
    Boolean ROLL_IT_BACK = false;
    Integer iNumAccountsWithBadData = 0;
    Integer iNumAccountsUpdated = 0;
    Integer iNumAccountsFailed = 0;
    Integer iNumTotalRecordsProcessed = 0;

    Map<Id,Account> mFailedAccounts = new Map<Id,Account>();
    Map<Id,Account> mSuccessfulAccounts = new Map<Id,Account>();

    String jobName = 'QueueableCountyUpdaterLive';

    //  Fed into the queueable via the constructor
    private Set<Id> accountIds = new Set<Id>();

    @TestVisible private Database.SaveResult platformEventSaveResult;
    public Map<Id,Accel_Application_Error__c> allLogsByAccountId = new Map<Id,Accel_Application_Error__c>();
    public Id jobId;

    public final Static String BASE_EP = 'https://geo.fcc.gov/api/census/block/find?latitude=';
    public final Static String TEST_JSON_RESPONSE = '{"Block":{"FIPS":"170438460033003","bbox":[-88.077141,41.793499,-88.074175,41.79639]},"County":{"FIPS":"17043","name":"DuPage"},"State":{"FIPS":"17","code":"IL","name":"Illinois"},"status":"OK","executionTime":"0"}';

    global QueueableCountyUpdaterLive(Set<Id> accountIds, Boolean bRollItBack) {
        ROLL_IT_BACK = bRollItBack;
        this.accountIds = accountIds;
        System.debug('----> instantiating QueueableCountyUpdaterLive with accountIds='+accountIds+'...bRollItBack='+bRollItBack);
    }

    /**
     * Implements the queueable execute interface.
     * @param ctx The Queueable context.
     */
    global void execute(QueueableContext ctx){
        this.jobId = ctx.getJobId();
        System.debug(LoggingLevel.INFO, '---> in queueableCountyUpdater with ctx: '+ctx);
        performExecute();
    }

    /**
     * 1. Filter the accounts to only those that we want to update.
     * 2. Callout to the provider getting the county names based on Shipping addy lat / long.
     * 3. Update the actual account.
     * 4. Log successes / failures.
     * 5. Fire platform event to notify any subscribers.
     */
    public void performExecute() {

        List<Account> accountsToSearch = filterAccounts();
        Map<Id,AccountWrapper> mAccountsToUpd = new Map<Id,AccountWrapper>();

        if(!accountsToSearch.isEmpty()) {
            mAccountsToUpd = calloutToProvider(accountsToSearch);
        }
        System.debug('---> total number of accounts to update:'+mAccountsToUpd.size());
        performAccountUpdates(mAccountsToUpd);

        if(!ROLL_IT_BACK) {
            if(!mFailedAccounts.isEmpty()) {
                logFailedAccounts();
            }
            writeLog();
            fireAccountUpdatedPlatformEvent();
        }
    }

    /**
     * Rolls through the accounts for which we found county information and updates the Account.CountyLU__c field
     * to the valid county as well as the Account.County_Auto_Updated__c field.
     *
     * @implNotes
     * If the user supplied the rollItBack parameter = true in the constructor. The Database trans will be rolled back
     *
     * @param   mAccountWrappers  A Map of AccountId => AccountWrapper.
     *
     * @see Account.County_LU__c
     * @see https://geo.fcc.gov/api/census/#!/block/get_block_find  (Source of county data)
     */
    public void performAccountUpdates( Map<Id,AccountWrapper> mAccountWrappers) {

        Savepoint sp = Database.setSavepoint();

        //  In memory.. set AccountWrapper.county and AccountWrapper.account with match from external provider.
        List<AccountWrapper> accountWrapsToUpd = tagCountyLuAndRegionLu(mAccountWrappers);

        //  Destructure Account sObject from Account Wrapper so that we can use it for an update for the Lookup field.
        List<Account>  accountsToUpd = new List<Account>();
        for(AccountWrapper accountWrapper : accountWrapsToUpd) {
            accountsToUpd.add(accountWrapper.account);
        }
        //  Fire a Database update (allow partial commits as accounts often fail due to validation rules / process builders etc.
        List<Database.SaveResult> results = Database.update(accountsToUpd, false);

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results.get(i);
            iNumTotalRecordsProcessed++;
            Accel_Application_Error__c log = allLogsByAccountId.get(accountsToUpd.get(i).id);
            log.Total_Records_Processed__c = 1;

            if (!sr.isSuccess()) {
                String errorMsg = '';
                for (Database.Error error : results.get(i).getErrors()) {
                    errorMsg += error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
                    System.debug(LoggingLevel.ERROR, accountsToUpd.get(i).Id + ' - ' + errorMsg);
                }
                log.Execution_Details__c += '\n* ERROR ON UPDATE='+errorMsg;
                log.Total_Updates_Failed__c = 1;
                log.Overall_Job_Status__c = 'Failed';
            } else {
                this.mSuccessfulAccounts.put(accountsToUpd.get(i).Id, accountsToUpd.get(i));
                log.Execution_Details__c += '\n* County set to '+accountWrapsToUpd.get(i).county;
                log.Total_Records_Updated__c = 1;
                log.Process_End_Date__c = System.now();
                log.Overall_Job_Status__c = 'Success';
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

    /**
     * Query all county records and throw in a map with a concat key of county.Name+'_'+county.State__c a
     * county names are not unique across states.
     *
     * Roll through the account wrappers using the accountWrapper.county property to match against the results
     * of the County__c sObject query. if found right it on accountWrapper.county and populate appropriate look ups.
     *
     * @param mAccountWrappers A Map of AccountId => AccountWrappers to update.
     * @return                 A List of AccountWrappers to update (if any) otherwise empty.
     *
     * @todo filter query by county names in mAccountWrappers as we may eventually have too many counties.
     */
    @TestVisible
    private static List<AccountWrapper> tagCountyLuAndRegionLu(Map<Id,AccountWrapper> mAccountWrappers) {
        List<AccountWrapper> accountWrapsUpdated = new List<AccountWrapper>();

        //  @todo filter this county query!
        Map<Id,County__c> mCountiesByIds = new Map<Id,County__c>([
                SELECT Id,Name,Covaid_Region__c,State__c,FIPS_Text__c
                FROM   County__c
        ]);

        Map<String,County__c> mCountiesByNames = new Map<String,County__c>();
        Map<String,County__c> mCountiesByFIPS = new Map<String,County__c>();
        for(County__c county : mCountiesByIds.values()) {
            //  ie Dupage_IL, County sObject into the map.
            mCountiesByNames.put(county.Name + '_'+county.State__c, county);
            if(county.FIPS_Text__c != null) {
                mCountiesByFIPS.put(county.FIPS_Text__c + '_'+county.State__c, county);
            }
        }

        for(AccountWrapper accountWrapper : mAccountWrappers.values()) {
            Account account = accountWrapper.account;

            if(accountWrapper.county != null && account.ShippingState != null) {
                String concatKey = accountWrapper.County+'_'+account.ShippingState;
                String fipsKey =  accountWrapper.fips+'_'+account.ShippingState;
                County__c county;
                if(mCountiesByNames.containsKey(concatKey)) {
                    county = mCountiesByNames.get(concatKey);
                    if(county != null) {
                        //  Save the county string name stamp the account sObject lookups
                        accountWrapper.county = county.Name;
                        account.County_LU__c = county.Id;
                        account.Covid_Region_LU__c = county.Covaid_Region__c;
                        account.County_Auto_Updated__c = true;
                        accountWrapsUpdated.add(accountWrapper);
                    }
                } else if(mCountiesByFIPS.containsKey(fipsKey)) {
                    county = mCountiesByFIPS.get(fipsKey);
                    if(county != null) {
                        accountWrapper.county = county.Name;
                        account.County_LU__c = county.Id;
                        account.Covid_Region_LU__c = county.Covaid_Region__c;
                        account.County_Auto_Updated__c = true;
                        accountWrapsUpdated.add(accountWrapper);
                    }
                }

            }
        }
        // return the accountWrapper objects so that an actual Database update can occur.
        return accountWrapsUpdated;
    }

    /**
     * Query Account with the accountIds passed into this queueable. Only process those that have a Shipping Latitude.
     * @return a List of Account sObjects.
     */
    public List<Account> filterAccounts() {

        List<Account> accounts = [
                SELECT Id, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy,
                        ShippingState,County_LU__c,Shipping_Address_Accuracy__c
                FROM   Account
                WHERE  ID IN :accountIds
                ORDER BY  LastModifiedDate DESC
        ];
        System.debug('----> Total # of accounts found  ..'+accounts.size());
        List<Account> accountsToSearch = new List<Account>();

        Integer iUpdateCount = 0;
        for(Account account : accounts) {
            if(account.ShippingLatitude != null) {
                if (iUpdateCount < MAX_ACCOUNTS_TO_PROCESS) {
                    accountsToSearch.add(account);
                    iUpdateCount++;
                }
            } else {
                mFailedAccounts.put(account.Id,account);
            }
        }
        System.debug('-----> Number of Accounts with Bad Data:'+mFailedAccounts.size());
        System.debug('-----> Number of Accounts to Process:'+accountsToSearch);

        this.iNumAccountsWithBadData += mFailedAccounts.size();
        this.iNumAccountsFailed++;
        return accountsToSearch;
    }

    /**
     * A Wrapper class to give us some place to stash the county name string as opposed to Account.County__c
     */
    public class AccountWrapper {
        Account account;
        String county;
        String fips;
        public AccountWrapper(Account account) {
            this.account = account;
        }
    }

    /**
     * Callout to the provider to get the county name with the provide lat / lng.
     * Stamp the log record in memory. Set the county name retrieved from the provider
     * on the AccountWrapper.county property for consumption in calling clients.
     *
     * @param accounts  A List of Account sObjects to process
     * @return          A Map of AccountId => AccountWrapper
     * @see AccountWrapper
     *
     * @todo pull the call to the CustomMetaData service to retrieve the geo accuracy value out of the for loop!
     */
    public Map<Id, AccountWrapper> calloutToProvider(List<Account> accounts) {
        Map<Id,AccountWrapper> mAccountsToUpd = new Map<Id,AccountWrapper>();

        String baseEp = BASE_EP;

        for (Account account : accounts) {
            Accel_Application_Error__c log = this.buildLog();
            log.Account__c = account.Id;
            log.Overall_Job_Status__c = 'Processing';
            log.Total_Records_Selected__c = 1;

            String ep = baseEp;
            ep += account.ShippingLatitude + '&longitude=' + account.ShippingLongitude + '&format=json';
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ep);
            req.setMethod('GET');
            log.Execution_Details__c += '\n* Endpoint='+ep;

            Http http = new Http();
            String jsonResponse = '';
            //  We can't properly mock a callout in a queueable so we have to fake it. 
            if (!Test.isRunningTest()) {
                HttpResponse response = http.send(req);
                jsonResponse = response.getBody();
            } else {
                jsonResponse = TEST_JSON_RESPONSE;
            }
            log.Execution_Details__c += '\n\n* ===========  JSON RESPONSE ==============';
            log.Execution_Details__c += '\n'+jsonResponse;
            //  We don't absolutely know the JSON response that will be returned so we must parse it apart
            //  and seek the 'County' key from the provider.
            Map<String, Object> m = (Map<String, Object>) Json.deserializeUntyped(jsonResponse);
            Map<String, Object> m2 = (Map<String, Object>) m.get('County');
            String county = (String) m2.get('name');
            String fips = (String) m2.get('FIPS');

            //  @todo this should probably be searching for the address accuracy in a map that was stashed above the loop.
            if (String.isNotEmpty(county)) {

                String geoAccuracy = account.ShippingGeocodeAccuracy;
                if(geoAccuracy != null) {
                    account.Shipping_Address_Accuracy__c = CustomMetadataSvc.retrieveGeoAccuracyDisplayValue(geoAccuracy);
                }
                //  Set the county on a new object property here since there is no where to stash it on the Account__c sObject.
                //  return to the account as we will tag the lookup value in the calling method.
                AccountWrapper accountWrapper = new AccountWrapper(account);
                accountWrapper.county = county;
                accountWrapper.fips = fips;
                mAccountsToUpd.put(account.Id, accountwrapper);
            } else {
                String geoAccuracy = account.ShippingGeocodeAccuracy;
                if(geoAccuracy != null) {
                    account.Shipping_Address_Accuracy__c = CustomMetadataSvc.retrieveGeoAccuracyDisplayValue(geoAccuracy);
                } else {
                    account.Shipping_Address_Accuracy__c = 'Weak';
                }
            }
            log.Execution_Details__c += '\n\n* Setting shipping address accuracy = '+account.Shipping_Address_Accuracy__c;
            allLogsByAccountId.put(account.Id,log);
        }
        return mAccountsToUpd;
    }


   /**
    * Build (do not insert) an Accel_Application_Error__c sObject.
    *
    * @return  an Accel_Application_Error__c sObject.
    */
    private Accel_Application_Error__c buildLog() {
        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);

        log.Overall_Job_Status__c = 'Processing';
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 1;
        log.Total_Records_Selected__c = 0;
        log.Stack_Trace__c = ' ';
        log.Execution_Details__c = ' ';
        log.JobType__c = 'Queueable';
        log.User__c = UserInfo.getUserId();
        log.Initiating_Job_Id__c = this.jobId;

        return log;
    }

    public void writeLog() {

        if(!allLogsByAccountId.isEmpty()) {
            insert allLogsByAccountId.values();
        }
    }

    /**
     * Fire a platform event with an array of account ids so that any subscribing client
     * can be informed that the Account was updated.
     *
     * @param updatedAccounts A Map of AccountId ==> Account sObject
     */
    @TestVisible
    private void fireAccountUpdatedPlatformEvent() {

        Set<Id> accountIds = mSuccessfulAccounts.keySet();
        if(!accountIds.isEmpty()) {
            Record_Updated_Event__e pe = new Record_Updated_Event__e();

            List<Id> lAccountIds = new List<Id>();
            lAccountIds.addAll(accountIds);
            String sAccountIds = String.join(lAccountIds, ',');
            pe.Record_Ids__c = sAccountIds;
            pe.SObject_API_Name__c = 'Account';

            this.platformEventSaveResult = EventBus.publish(pe);
            System.debug('---> pe Save Result=' + this.platformEventSaveResult);
        }
    }
    private void logFailedAccounts() {

        for(Account account : mFailedAccounts.values()) {
            Accel_Application_Error__c log = this.buildLog();
            log.Account__c = account.Id;
            log.Overall_Job_Status__c = 'Failed';
            log.Execution_Details__c += '\n* '+account;
            log.Stack_Trace__c += '\n*  No callout made.. No lat long info on account ';
            log.Total_Records_Selected__c = 1;
            log.Total_Records_Processed__c = 0;
            log.Process_End_Date__c = System.now();
            allLogsByAccountId.put(account.Id, log);
        }
    }
}