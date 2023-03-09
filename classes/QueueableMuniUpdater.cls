/**
 *
 * parameters: https://developers.google.com/maps/documentation/geocoding/overview#ReverseGeocoding
 * response: https://developers.google.com/maps/documentation/geocoding/overview#reverse-response
 */
global without sharing class QueueableMuniUpdater implements Queueable, Database.AllowsCallouts {

    @TestVisible private final static String API_KEY_MASK = '[removed_api_key]';
    @TestVisible private final static String jobName = 'QueuableMuniUpdater';
    @TestVisible private final static String LATLNG_PARAM = '&latlng=';
    @TestVisible private final static Integer MAX_ACCOUNTS_TO_PROCESS = 100;
    @TestVisible private static Boolean ROLL_IT_BACK = false;
    @TestVisible private static Boolean makeCallout = true;
    @testVisible private static Boolean doChainJob = true;
    @TestVisible private static String TEST_EMAIL_USERNAMES = '';
    @TestVisible private static Boolean SEND_EMAIL = false;

    @TestVisible private Database.SaveResult platformEventSaveResult;

    public Id jobId;

    //  Fed into the queueable via the constructor
    private Set<Id> accountIds = new Set<Id>();

    //  maintain state of internal data.
    public Map<Id, Accel_Application_Error__c> allLogsByAccountId = new Map<Id, Accel_Application_Error__c>();
    public Map<Id, AccountData> accountDataByIds = new Map<Id, AccountData>();
    private Google_Setting__mdt mdt;
    public Integer iNumAccountsWithBadData = 0;

    /**
     * No arg constructor
     */
    global QueueableMuniUpdater() {
        //
    }

    /**
     * 1 arg constructor (assumes we are not rolling back the trans.
     * @param accountIds The account Ids to process
     */
    global QueueableMuniUpdater(Set<Id> accountIds) {
        this.accountIds = accountIds;
        ROLL_IT_BACK = false;
    }

    /**
     * @param accountIds  A Set of account Ids to process
     * @param bRollItBack True if we should roll back the trans, otherwise false.
     *
     * @implNotes
     * Really we should only fire this with accountIds that have a lat/lng value but it will double check
     * on the retrieve query for this as well and discard those accounts.
     */
    global QueueableMuniUpdater(Set<Id> accountIds, boolean bRollItBack) {
        this.accountIds = accountIds;
        ROLL_IT_BACK = bRollItBack;
    }

    /**
     * Implements the queueable execute interface.
     * @param ctx The Queueable context.
     */
    global void execute(QueueableContext ctx) {
        this.jobId = ctx.getJobId();
        if (makeCallout) {
            performExecute();
        }
    }

    /**
     * Main driver in which we do the following steps:
     *
     * 1. Retrieve custom metadata for the job.
     * 2. Retrieve all account data for the account Ids.
     * 3. Call out to Google with the lat, lng on the account.
     * 4. Evaluate the Google response.
     * 5. Attempt to match the google Muni String Name against an accel Municipality__c.Name
     * 6. Update Account.Municipality_LU__c if possible.
     * 7. Insert Accel_Application_Error__c with trans information.
     * 8. Fire a Platform Event to inform clients of any updates of account data.
     * 9. Send Email (on failure only) if custom metadata is set to send email.
     */
    public void performExecute() {

        this.mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());

        // Init the accountDataByIds Map with reselected Account data.
        retrieveAccounts();

        //  Perform Callout to Google with lat / long and supplements accountDataByIds Map.
        if (!accountDataByIds.isEmpty()) {
            calloutToProvider(accountDataByIds);
        }

        //  Roll through Google JSON looking for muni data, store results on main Map.
        evalGoogleJson(accountDataByIds);

        //  Match google muni with Accel muni if possible.
        storeMuniInAccountData();
        System.debug('---> final Map=' + accountDataByIds);

        //  Roll through accountDataByIds Map and update Accel accounts with Muni Id if we can.
        updateAccelAccounts();

        //  Create Accel_Application_Error__c sObjects (logs)
        createAccelLogs();

        // Fire a Platform Event to inform clients of change.
        fireAccountUpdatedPlatformEvent();

        // If setup to send emails on an error, send an email to users / template defined in custom metadata.
        if (mdt.Send_Email_On_Failure__c) {
            sendEmail();
        }
        if (doChainJob) {
            QueueableCountyUpdaterLive q = new QueueableCountyUpdaterLive(this.accountIds, false);
            System.enqueueJob(q);
        }
    }

    /**
     * Evaluate the Json Object returned by Google.
     * @param accountDataByIds xx
     */
    public void evalGoogleJson(Map<Id, AccountData> accountDataByIds) {
        //  Add logging details to the the AccountData object in accountDataByIds Map
        for (Id accountId : accountDataByIds.keySet()) {

            AccountData accountData = accountDataByIds.get(accountId);
            Account a = accountData.account;
            Accel_Application_Error__c log = allLogsByAccountId.get(a.Id);
            log.Total_Records_Processed__c = 1;

            if (accountData.calloutException == null) {
                GoogleGeoCodeJsonToApex obj = accountData.jsonObj;
                if (obj != null) {
                    String gMuni;
                    String gState;
                    Boolean foundIt = false;
                    for (GoogleGeoCodeJsonToApex.Results result : obj.results) {
                        if (foundIt) {
                            break;
                        }

                        if (result.types.contains('street_address')) {
                            for (GoogleGeoCodeJsonToApex.Address_components addr : result.address_components) {
                                if (accountData.account.ShippingState == 'PA') {
                                    // @TODO PA Hack! Fix this!
                                    if (addr.types.contains('administrative_area_level_3') && addr.types.contains('political')) {
                                        gMuni = addr.long_name;
                                        System.debug('--- found it for PA1!');
                                        accountData.googleMuniName = gMuni;
                                        foundIt = true;
                                        log.Total_Records_Selected__c = 1;
                                        break;
                                    }
                                } else {
                                    if (addr.types.contains('locality') && addr.types.contains('political')) {
                                        gMuni = addr.long_name;
                                        System.debug('--- found it!');
                                        accountData.googleMuniName = gMuni;
                                        foundIt = true;
                                        log.Total_Records_Selected__c = 1;
                                        break;
                                    }
                                }
                            }
                            //@todo again PA hacking looping through again. fix this!
                            if (!foundIt && accountData.account.ShippingState == 'PA') {
                                for (GoogleGeoCodeJsonToApex.Address_components addr : result.address_components) {
                                    if (addr.types.contains('locality') && addr.types.contains('political')) {
                                        gMuni = addr.long_name;
                                        System.debug('--- found it PA2!');
                                        accountData.googleMuniName = gMuni;
                                        foundIt = true;
                                        log.Total_Records_Selected__c = 1;
                                        break;
                                    }
                                }
                            }


                            for (GoogleGeoCodeJsonToApex.Address_components addr : result.address_components) {
                                if (addr.types.contains('administrative_area_level_1')) {
                                    gState = addr.short_name;
                                    break;
                                }
                            }
                        } else {
                            // yet another hack. @todo figure out the dynamic stuff coming from google better
                            System.debug('----> NO RESULT TYPE OF street_address looking for street_number!');
                            if (result.types.contains('administrative_area_level_3')) {
                                for (GoogleGeoCodeJsonToApex.Address_components addr : result.address_components) {
                                    if (addr.types.contains('administrative_area_level_3') && addr.types.contains('political')) {
                                        gMuni = addr.long_name;
                                        System.debug('--- found it admin level 3 (first level)');
                                        accountData.googleMuniName = gMuni;
                                        foundIt = true;
                                        log.Total_Records_Selected__c = 1;
                                        break;
                                    }
                                }
                                for (GoogleGeoCodeJsonToApex.Address_components addr : result.address_components) {
                                    if (addr.types.contains('administrative_area_level_1')) {
                                        gState = addr.short_name;
                                        break;
                                    }
                                }
                            }

                        }
                    }
                    // Prefix the Muni Name by State for later matching so that we don't run into a bad situation
                    // where w have the same muni name in muliple states. .ie IL_Carol Stream
                    if (gMuni != null) {
                        //accountData.googleMuniName = gState + '_'+accountData.googleMuniName;

                        //System.debug('----> STATE='+gState);
                        log.Execution_Details__c += '\n* Google Muni Name =' + gMuni;
                    } else {
                        log.Execution_Details__c += '\n* xxx Google could not find muni for given address xxxx';
                    }
                    accountData.log = log;
                }
            } else {
                accountData.log.Stack_Trace__c = accountData.calloutException.getStackTraceString();
            }
        }
    }
    /**
     * Find All Accel Municipalities queried from Municipality__c then match the muni
     * name retrieved from google while ensuring it's in the same state as the account.
     * Now for PA.. there is an exception where google does not suffix the muni with borough, city etc.
     * but we have them stored in Accel Municipality__c that way so we need to do our best here on a name match.
     */
    public void storeMuniInAccountData() {
        Map<String, Municipality__c> municipalitiesByName = findMunisByName();
        for (Id accountId : accountDataByIds.keySet()) {
            AccountData data = accountDataByIds.get(accountId);
            if (data.googleMuniName != null) {
                //  'PA Hack'
                data.log.Execution_Details__c += '\n=========== munis by name=' + municipalitiesByName;
                String key = data.account.ShippingState + '_' + data.googleMuniName;
                if (municipalitiesByName.containsKey(key)
                        || municipalitiesByName.containsKey(key + ' Borough')
                        || municipalitiesByName.containsKey(key + ' City')
                        || municipalitiesByName.containsKey(key + ' Township')) {
                    Municipality__c accelMuni = municipalitiesByName.get(key);
                    if (accelMuni == null) {
                        accelMuni = municipalitiesByName.get(key + ' Borough');
                    }
                    if (accelMuni == null) {
                        accelMuni = municipalitiesByName.get(key + ' Township');
                    }
                    if (accelMuni == null) {
                        accelMuni = municipalitiesByName.get(key + ' City');
                    }
                    if (accelMuni.State__c == data.account.ShippingState) {
                        data.muni = accelMuni;
                        data.log.Execution_Details__c += '\n* Found Accel Muni Id = ' + data.muni.Id;
                        data.account.MunicipalityLookup__c = data.muni.Id;
                        data.account.Muni_Auto_Updated__c = true;
                        data.performAccountUpdate = true;
                    } else {
                        data.log.Execution_Details__c += '\n* Found Muni but invalid state';
                    }
                } else {
                    data.userErrorMsg += 'Google Municipality:  ' + data.googleMuniName + ' not found in Accel Municipalities';
                    data.log.Execution_Details__c += '\n* Could not find Accel Muni Id for Google Muni ' + data.googleMuniName;
                    data.log.Overall_Job_Status__c = 'Failed';
                }
            } else {
                data.userErrorMsg += 'Google could not locate a municipality for this location';
                data.log.Execution_Details__c += '\n* ' + data.userErrorMsg;
                data.log.Overall_Job_Status__c = 'Failed';
            }
        }
    }

    /**
     * Retrieve all accounts that are to be updated via the main instance map.
     * Perform Update. set logging data on AccountData object.
     */
    public void updateAccelAccounts() {
        List<Account> accountsToUpdate = getAllAccountsToUpdate(accountDataByIds);

        if (!accountsToUpdate.isEmpty()) {
            System.debug('---> updating: ' + accountsToUpdate.size() + ' accounts');
            List<Database.SaveResult> results = Database.update(accountsToUpdate, false);
            //@todo analyze results
            for (Account account : accountsToUpdate) {
                AccountData accountData = accountDataByIds.get(account.Id);
                accountData.log.Overall_Job_Status__c = 'Success';
                accountData.log.Total_Records_Updated__c = 1;
                accountData.accountUpdateSuccess = true;
            }
        }
    }

    /**
     * Query Municipality__c with the muni names retrieved from Google.
     *
     * @return A Map of StateCode_Muni Name => Muni SFDC Id.
     */
    public Map<String, Municipality__c> findMunisByName() {
        Set<String> allMuniNames = getAllMuniNames(accountDataByIds);

        List<Municipality__c> municipalities = [
                SELECT Id,Name,State__c
                FROM Municipality__c
                WHERE Name IN :allMuniNames
        ];
        Map<String, Municipality__c> municipalitiesByName = new Map<String, Municipality__c>();
        for (Municipality__c muni : municipalities) {
            municipalitiesByName.put(muni.State__c + '_' + muni.Name, muni);
        }
        return municipalitiesByName;
    }

    /**
     * Re-query account info and add to accountDataByIds map.
     */
    public void retrieveAccounts() {

        List<Account> accounts = [
                SELECT Id, Name,County_LU__r.Name,MunicipalityLookup__r.Name,ShippingCity,ShippingState,
                         County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy,
                        Muni_Auto_Updated__c

                             //   SELECT Id, Name,County_LU__r.Name,MunicipalityLookup__r.Name,ShippingCity,ShippingState,
                    //    County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy,
                      //  Muni_Auto_Updated__c
                FROM Account
                WHERE ID IN :accountIds
                ORDER BY LastModifiedDate DESC
        ];
        System.debug('----> Total # of accounts using accountIds passed ..' + accounts.size());

        List<Account> accountsToSearch = new List<Account>();
        List<Account> accountsWithBadData = new List<Account>();
        Integer iUpdateCount = 0;
        for (Account account : accounts) {
            AccountData accountData = new AccountData(account);
            accountDataByIds.put(account.Id, accountData);

            if (account.ShippingLatitude != null) {
                if (iUpdateCount < MAX_ACCOUNTS_TO_PROCESS) {
                    accountsToSearch.add(account);
                    accountData.performCallout = true;
                    iUpdateCount++;
                }
            } else {
                // should not happen if this is fired from the trigger but here for safety.
                accountsWithBadData.add(account);
            }
        }
        System.debug('-----> Number of Accounts with Bad Data:' + accountsWithBadData.size());
        System.debug('-----> Number of Accounts to Process:' + accountsToSearch);

        this.iNumAccountsWithBadData += accountsWithBadData.size();
    }

    /**
     * @param accounts A List of accounts to callout with
     * @return
     */
    public void calloutToProvider(Map<Id, AccountData> accountDataByIds) {

        List<Account> allAccounts = getAllAccounts(accountDataByIds);

        Map<Account, GoogleGeoCodeJsonToApex> mAccountsToUpd = new Map<Account, GoogleGeoCodeJsonToApex>();
        Map<Account, GoogleGeoCodeJsonToApex> mFailedAccounts = new Map<Account, GoogleGeoCodeJsonToApex>();

        Http http = new Http();
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String baseEp = httpRequest.getEndpoint();

        for (Account account : allAccounts) {


            String jsonResponse = '';
            GoogleGeoCodeJsonToApex jsonObj;
            AccountData accountData = accountDataByIds.get(account.Id);
            Accel_Application_Error__c log = this.buildLog();

            log.Account__c = account.Id;
            if (accountData.performCallout) {
                String epSuffix = LATLNG_PARAM + account.ShippingLatitude + ',' + account.ShippingLongitude;
                httpRequest.setEndpoint(baseEp + epSuffix);

                //if (!Test.isRunningTest()) {
                try {
                    HttpResponse res = http.send(httpRequest);
                    String ep = httpRequest.getEndpoint();

                    log.Execution_Details__c += '* Request = ' + maskApiKey(ep) + '\n';
                    if (res.getStatusCode() == GoogleSvc.HTTP_OK) {
                        jsonResponse = res.getBody();
                        jsonObj = GoogleGeoCodeJsonToApex.parse(jsonResponse);
                        System.debug('---> jsonObj=' + jsonObj);
                        log.Execution_Details__c += '\n* ==== Google JSON Response =====  \n';
                        log.Execution_Details__c += JSON.serialize(jsonObj) + '\n';
                        accountData.jsonObj = jsonObj;
                    } else {
                        log.Execution_Details__c += '\n* ==== Invalid Google Response =====  \n';
                        log.Execution_Details__c += '\n* Status Code = ' + res.getStatusCode();
                        log.Overall_Job_Status__c = 'Failed';
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, e);
                    accountData.calloutException = e;
                    log.Overall_Job_Status__c = 'Failed';
                }
            } else {
                log.Execution_Details__c += '\n* No Callout attempted as there is no lat/long on the Account!';
                log.Overall_Job_Status__c = 'Failed';
            }
            accountData.log = log;
            accountData.jsonObj = jsonObj;
            allLogsByAccountId.put(account.Id, log);
        }
    }

    public void createAccelLogs() {
        List<Accel_Application_Error__c> allLogs = new List<Accel_Application_Error__c>(getAllLogs(accountDataByIds));
        insert allLogs;
        System.debug('--> allLogs=' + allLogs);

        for (Accel_Application_Error__c log : allLogs) {
            log.Process_End_Date__c = System.now();
        }
        update allLogs;
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

    /**
     *  Inner class representing all associated data to the account(s) being processed.
     */
    public class AccountData {

        public Account account;
        public Municipality__c muni;
        public Accel_Application_Error__c log;
        public GoogleGeoCodeJsonToApex jsonObj;
        public String googleMuniName;
        public Boolean performCallout = false;
        public Boolean performAccountUpdate = false;
        public Boolean accountUpdateSuccess = false;
        public Exception calloutException;

        public String userErrorMsg = '';

        public AccountData(Account acct) {
            this.account = acct;
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

        Set<Id> accountIds = getAllSuccessfullyUpdatedAccounts(accountDataByIds).keySet();
        Record_Updated_Event__e pe = new Record_Updated_Event__e();

        List<Id> lAccountIds = new List<Id>();
        lAccountIds.addAll(accountIds);
        String sAccountIds = String.join(lAccountIds, ',');
        pe.Record_Ids__c = sAccountIds;
        pe.SObject_API_Name__c = 'Account';

        this.platformEventSaveResult = EventBus.publish(pe);
        System.debug('---> pe Save Result=' + this.platformEventSaveResult);
    }

    /**
     *
     */
    private void sendEmail() {

        String sUserNames = this.mdt.Users__c;
        Set<Id> emailWhoUserIds = new Set<Id>();

        if (Test.isRunningTest() && SEND_EMAIL) {
            sUserNames = TEST_EMAIL_USERNAMES;
            System.debug('----> in Unit Test Mode sUserNames=' + sUserNames);
        }
        if (String.isNotBlank(sUserNames)) {

            List<String> userNames = sUserNames.split(',');
            Map<Id, User> mUsersByIds = new Map<Id, User>([SELECT Id FROM User WHERE UserName IN :userNames]);

            if (!mUsersByIds.isEmpty()) {
                emailWhoUserIds.addAll(mUsersByIds.keySet());
                if (infoExistsToSendEmail(emailWhoUserIds, mdt.Email_Template_Dev_Name__c)) {
                    EmailTemplate t = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :mdt.Email_Template_Dev_Name__c];

                    List<BatchjobSvc.BatchEmailData> batchEmailData = buildEmails(t.Id,accountDataByIds.values(),emailWhoUserIds);
                    List<Messaging.SendEmailResult> sendResults = BatchjobSvc.sendEmailTemplates(batchEmailData);
                    System.debug('---> sendEmailResults='+sendResults);
                }
            }
        }
    }

    /**
     * @param templateId    xx
     * @param accountDatas  xx
     * @param whoIds        xx
     *
     * @return              xx
     */
    private List<BatchjobSvc.BatchEmailData> buildEmails(Id templateId, List<AccountData> accountDatas,Set<Id> whoIds) {

        List<BatchjobSvc.BatchEmailData> batchEmails =  new List<BatchjobSvc.BatchEmailData>();

        for(AccountData accountData : accountDatas) {
            //if(!accountData.accountUpdateSuccess) {
                BatchjobSvc.BatchEmailData data = new BatchjobSvc.BatchEmailData();

                data.templateId = templateId;
                data.dynamicHtml = buildCustomHtml(accountData);
                data.log = accountData.log;
                data.whoIds = whoIds;
                batchEmails.add(data);
            //}
        }
        return batchEmails;
    }

    /**
     * @return true if we have enough info in the custom mdt to send an email, otherwise false.
     */
    private Boolean infoExistsToSendEmail(Set<Id> emailWhoUserIds, String emailTemplateDevName) {
        Boolean sendIt = false;
        sendIt = emailWhoUserIds != null && !emailWhoUserIds.isEmpty() && emailTemplateDevName != null;
        System.debug('---> enough info exists to send email? = ' + sendIt);
        return sendIt;
    }

    /**
     * @param m  A map of AccountId => AccountData
     * @return   A Set of Raw Municipality Names (not prefixed by State)
     *
     * @implNotes
     *          PA is a tough state as google only returns the prefix in it's JSON ie. Pittsburgh
     *          but PA assigns suffixes. ie. city, borough, town etc. we must append when bumping
     *          up against Accel
     */
    private Set<String> getAllMuniNames(Map<Id, AccountData> m) {
        Set<String> muniNames = new Set<String>();

        for (AccountData accountData : m.values()) {
            if (accountData.googleMuniName != null) {
                muniNames.add(accountData.googleMuniName);
                if (accountData.account.ShippingState == 'PA') {
                    muniNames.add(accountData.googleMuniName + ' city');
                    muniNames.add(accountData.googleMuniName + ' borough');
                    muniNames.add(accountData.googleMuniName + ' town');
                }
            }
        }
        return muniNames;
    }

    /**
     * @param m  A map of AccountId => AccountData
     * @return   A Set of Accel_Application_Error__c sObjects.
     */
    private Set<Accel_Application_Error__c> getAllLogs(Map<Id, AccountData> m) {
        Set<Accel_Application_Error__c> logs = new Set<Accel_Application_Error__c>();

        for (AccountData accountData : m.values()) {
            logs.add(accountData.log);
        }
        return logs;
    }

    /**
     * @param m  A map of AccountId => AccountData
     * @return   A List of Account sObjects.
     */
    private List<Account> getAllAccounts(Map<Id, AccountData> m) {
        List<Account> accounts = new List<Account>();
        for (AccountData accountData : m.values()) {
            accounts.add(accountData.account);
        }
        return accounts;
    }
    /**
     * @param m  A map of AccountId => AccountData
     * @return   A List of Account sObjects.
     */
    private List<Account> getAllAccountsToUpdate(Map<Id, AccountData> m) {
        List<Account> accounts = new List<Account>();
        for (AccountData accountData : m.values()) {
            if (accountData.performAccountUpdate) {
                Account account = accountData.account;
                accounts.add(account);
            }
        }
        return accounts;
    }

    /**
     * @param m  A map of AccountId => AccountData
     * @return   A List of Account sObjects.
     */
    private Map<Id, Account> getAllSuccessfullyUpdatedAccounts(Map<Id, AccountData> m) {
        Map<Id, Account> accountsByIds = new Map<Id, Account>();
        for (AccountData accountData : m.values()) {
            if (accountData.accountUpdateSuccess) {
                accountsByIds.put(accountData.account.Id, accountData.account);
            }
        }
        return accountsByIds;
    }

    /**
     * @param ep  The endPoint to Mask.
     * @return    A string with the api key masked.
     */
    @TestVisible
    private static String maskApiKey(String ep) {
        String key = ep.substringBetween('key=', LATLNG_PARAM);
        return ep.replace(key, API_KEY_MASK);
    }


    /**
     * Add opt in / opt out info to the email template.
     *
     * @return valid html to inject into body of the template
     */
    private String buildCustomHtml(AccountData data) {
        String html = '';
        html += '<table border="0" cellpadding="0" cellspacing="0" width="100%">';
        html += '<tbody>';
        html += '<tr>';
        html += '<td style="width:35%"><span style="font-size:12px;">Google Muni Found:</span></td>';
        html += '<td style="width:65%"><span style="font-size:12px;">' + data.googleMuniName + '</span></td>';
        html += '</tr>';
        html += '</tbody>';
        html += '</table>';
        return html;
    }

}