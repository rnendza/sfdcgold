/**
 *
 * parameters:
 * https://developers.google.com/maps/documentation/geocoding/overview#ReverseGeocoding
 *
 * response:
 * https://developers.google.com/maps/documentation/geocoding/overview#reverse-response
 */
global class QueueableMuniSample implements  Queueable, Database.AllowsCallouts, Database.RaisesPlatformEvents {

    public static String jobName = 'QueuableMuniSample';
    public Id jobId, scheduledJobId;
  
    //  Overwritten with custom metadata.
    public Boolean logFailedRecordIds = true;
    public Set<Id> emailWhoUserIds = new Set<Id>();
    public Set<Id> accountIds = new Set<Id>();

    public Map<Id,Accel_Application_Error__c> allLogsByAccountId = new Map<Id,Accel_Application_Error__c>();


    Integer MAX_ACCOUNTS_TO_PROCESS = 50;
    Boolean ROLL_IT_BACK = false;
    Integer iNumAccountsWithBadData = 0;


    global QueueableMuniSample(Integer imaxAccountsToProcess, Boolean bRollItBack) {
        MAX_ACCOUNTS_TO_PROCESS = iMaxAccountsToProcess;
        ROLL_IT_BACK = bRollItBack;
    }
    global QueueableMuniSample() {

    }

    global QueueableMuniSample(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    /**
     * Implements the queueable execute interface.
     * @param ctx The Queueable context.
     */
    global void execute(QueueableContext ctx){
        this.jobId = ctx.getJobId();
        if(!Test.isRunningTest()) {
            performExecute();
        }
    }
    /**
     *
     */
    public void performExecute() {

        Map<Id,Account> accountsToSearch = filterAccounts();
        //Map<Account, GoogleGeoCodeJsonToApex> mGeocodeByAccount = new Map<Account, GoogleGeoCodeJsonToApex>();

        Map<Id, String> mMuniNameByAccountId = new Map<Id,String>();
        Map<Id,AccountData> mAllAccounts = new Map<Id,AccountData>();
        if(!accountsToSearch.isEmpty()) {
            mAllAccounts = calloutToProvider(accountsToSearch.values());
        }

        System.debug('---> total number of accounts to update:'+mAllAccounts.size());
        List<String> csvRowValues = new List<String>();
        String csvColumnHeader = 'Accel Account, Accel City, Accel County, Accel Muni, Google Muni\n';
        String msg = csvColumnHeader;

        for(Id accountId : mAllAccounts.keySet()) {
            AccountData accountData = mAllAccounts.get(accountId);
            Account a = accountData.account;
            Accel_Application_Error__c log = allLogsByAccountId.get(a.Id);
            log.Total_Records_Processed__c = 1;
            GoogleGeoCodeJsonToApex obj = accountData.jsonObj;
            String gMuni;

            Boolean foundIt = false;
            for(GoogleGeoCodeJsonToApex.Results  result: obj.results ) {
                if(foundIt) {
                    break;
                }
                System.debug('---> result types='+result.types);
                System.debug('---> result='+result);
                if(result.types.contains('street_address')) {
                    for (GoogleGeoCodeJsonToApex.Address_components addr : result.address_components) {
                        if (addr.types.contains('locality') && addr.types.contains('political')) {
                            gMuni = addr.long_name;
                            mMuniNameByAccountId.put(a.Id, gMuni);
                            System.debug('--- found it!');
                            accountData.googleMuniName = gMuni;
                            foundIt = true;
                            log.Total_Records_Selected__c = 1;
                            break;
                        } else {
                            //mMccountsToUpd.remove(a);
                        }
                    }
                }
            }
            if(gMuni != null) {
                log.Execution_Details__c += '\n* Google Muni Name ='+gMuni;
            } else {
                log.Execution_Details__c += '\n* xxx Google could not find muni for given address xxxx';
            }
            accountData.log = log;

            String rowStr = a.Name +','+a.ShippingCity+','+ a.County_LU__r.Name+','+a.MunicipalityLookup__r.Name+','+gMuni +'\n';
            System.debug(rowStr);
            msg+=rowStr;
            csvRowValues.add(rowStr);

        }
        //List<Accel_Application_Error__c> allLogs = new List<Accel_Application_Error__c>(getAllLogs(mAllAccounts));
        Set<String> allMuniNames = getAllMuniNames(mAllAccounts);

        //insert allLogs;


        List<Municipality__c> municipalities = [
                SELECT Id,Name,State__c
                FROM Municipality__c
                WHERE Name IN :allMuniNames
        ];
        System.debug('--> matching munis:'+municipalities);
        Map<String,Municipality__c> municipalitiesByName = new Map<String,Municipality__c>();
        for(Municipality__c muni : municipalities) {
            municipalitiesByName.put(muni.Name,muni);
        }

        Map<Id,Account> accountsToUpdate = new Map<Id,Account>();

        for(Id accountId : mAllAccounts.keySet()) {
            AccountData data = mAllAccounts.get(accountId);
            if(data.googleMuniName != null) {
                if (municipalitiesByName.containsKey(data.googleMuniName)) {
                    data.muni = municipalitiesByName.get(data.googleMuniName);
                    data.log.Execution_Details__c += '\n* Found Accel Muni Id = '+data.muni.Id;
                    data.log.Overall_Job_Status__c = 'Success';
                    data.log.Total_Records_Updated__c = 1;
                    data.account.MunicipalityLookup__c = data.muni.Id;
                    accountsToUpdate.put(data.account.Id,data.account);
                } else {
                    data.userErrorMsg += 'Google Municipality:  '+data.googleMuniName + ' not found in Accel Municipalities';
                    data.log.Execution_Details__c += '\n* Could not find Accel Muni Id for Google Muni '+data.googleMuniName;
                    data.log.Overall_Job_Status__c = 'Failed';
                }
            } else {
                data.userErrorMsg += 'Google could not locate a municipality for this location';
                data.log.Execution_Details__c += '\n* '+data.userErrorMsg;
                data.log.Overall_Job_Status__c = 'Failed';
            }
        }

        System.debug('---> final Map='+mAllAccounts);
        System.debug(msg);
        List<Accel_Application_Error__c> allLogs = new List<Accel_Application_Error__c>(getAllLogs(mAllAccounts));
        insert allLogs;
        System.debug('--> allLogs='+allLogs);

        if(!accountsToUpdate.isEmpty()) {
            System.debug('---> updating: '+ accountsToUpdate.size() + ' accounts');
            update accountsToUpdate.values();

            Record_Updated_Event__e pe = new Record_Updated_Event__e();

            List<Id> lAccountIds = new List<Id>();
            lAccountIds.addAll(accountsToUpdate.keySet());
            String accountIds = String.join(lAccountIds,',');
            pe.Record_Ids__c = accountIds;
            pe.SObject_API_Name__c = 'Account';

            Database.SaveResult sr = EventBus.publish(pe);


            //for(String accountId)

        }

        for(Accel_Application_Error__c log : allLogs) {
            log.Process_End_Date__c = System.now();
        }
        update allLogs;

        String documentName = 'Google_Muni_Callout_Test-'+ Datetime.now().format('MMM') + Datetime.now().year();
        //String csvColumnHeader = 'Accel Account, Accel City, Accel County, Accel Muni, Google Muni\n';
        String csvFile = csvColumnHeader + String.join(csvRowValues,'\n');
        blob csvBlob = Blob.valueOf(csvFile);
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        csvAttc.setBody(csvBlob);
        csvAttc.setFileName(documentName);


        EmailSvc.sendEmail(new List<String>{'rick@chicagosalesforceconsulting.com'},null,'Google email results',
                'Attached',new List<Messaging.EmailFileAttachment>{csvAttc},null);


        // Insert the generated CSV file in Document object under "Setup Audit Trail Logs".
//        Document doc = new Document(Name = documentName, Body = Blob.valueOf(csvFile), FolderId = folders[0].Id, Type = 'csv', ContentType='application/vnd.ms-excel');
//        insert doc;

    }

    public Map<Id,Account> filterAccounts() {

        List<Account> accounts;
        if(this.accountIds.isEmpty()) {
            accounts = [
                   // SELECT Id, Name,County_LU__r.Name,MunicipalityLookup__r.Name,ShippingCity,ShippingState,
                          //  County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,
                            SELECT Id, Name,County_LU__r.Name,MunicipalityLookup__r.Name,ShippingCity,ShippingState,
                            County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy
                    FROM Account
                    WHERE County_Auto_Updated__c = TRUE
                    ORDER BY LastModifiedDate DESC
            ];
            System.debug('----> Total # of accounts found with county_auto_updated__c = TRUE ..' + accounts.size());
        } else {
            accounts = [
                    SELECT Id, Name,County_LU__r.Name,MunicipalityLookup__r.Name,ShippingCity,ShippingState,
                             County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy

                              //      SELECT Id, Name,County_LU__r.Name,MunicipalityLookup__r.Name,ShippingCity,ShippingState,
                          //  County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude, ShippingGeocodeAccuracy
                    FROM Account
                    WHERE ID IN :accountIds
                    ORDER BY LastModifiedDate DESC
            ];
            System.debug('----> Total # of accounts using accountIds passed ..' + accounts.size());
        }
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
        Map<Id,Account> m = new Map<Id,Account>();
        for(Account a : accountsToSearch) {
            m.put(a.Id,a);
        }
        return m;
    }

    public Map<Id,AccountData> calloutToProvider(List<Account> accounts) {
        Map<Id,AccountData> mAllAccounts = new Map<Id,AccountData>();

        Map<Account, GoogleGeoCodeJsonToApex> mAccountsToUpd = new Map<Account, GoogleGeoCodeJsonToApex>();
        Map<Account, GoogleGeoCodeJsonToApex> mFailedAccounts = new Map<Account, GoogleGeoCodeJsonToApex>();

        Http http = new Http();
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String baseEp = httpRequest.getEndpoint();
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());

        for (Account account : accounts) {
            GoogleGeoCodeJsonToApex jsonObj;
            AccountData accountData = new AccountData(account);



            Accel_Application_Error__c log = this.buildLog();
            log.Account__c = account.Id;
            String epSuffix = '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;
            httpRequest.setEndpoint(baseEp + epSuffix);
            String jsonResponse = '';
            //if (!Test.isRunningTest()) {
                try {
                    HttpResponse res = http.send(httpRequest);
                    String ep = httpRequest.getEndpoint();

                    log.Execution_Details__c += '* Request = '+ removeApiKey(ep) + '\n';
                    if(res.getStatusCode() == GoogleSvc.HTTP_OK) {
                        jsonResponse = res.getBody();
                        jsonObj = GoogleGeoCodeJsonToApex.parse(jsonResponse);
                        log.Execution_Details__c += '\n* ==== Google JSON Response =====  \n';
                        log.Execution_Details__c += JSON.serialize(jsonObj) + '\n';
                        mAccountsToUpd.put(account, jsonObj);
                    } else {
                        //log and/or email
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR,e);
                }
//            } else {
//                jsonResponse = TEST_JSON_RESPONSE;
//            }
            accountData.log = log;
            accountData.jsonObj = jsonObj;
            mAllAccounts.put(account.Id,accountData);


            allLogsByAccountId.put(account.Id,log);

        }
        return mAllAccounts;
    }

    @TestVisible
    private static String removeApiKey(String ep) {
        String key = ep.substringBetween('key=','&latlng=');
        return ep.replace(key, '[removed_api_key]');
    }

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

    public class AccountData {

        public Account account;
        public Municipality__c muni;
        public Accel_Application_Error__c log;
        public GoogleGeoCodeJsonToApex jsonObj;
        public String googleMuniName;
        public String userErrorMsg = '';

        public AccountData(Account acct) {
            this.account = acct;
        }
    }

    private Set<String> getAllMuniNames(Map<Id,AccountData> m ) {
        Set<String> muniNames = new Set<String>();
        for(AccountData accountData : m.values()) {
            muniNames.add(accountData.googleMuniName);
        }
        return muniNames;
    }

    private Set<Accel_Application_Error__c> getAllLogs(Map<Id,AccountData> m ) {
        Set<Accel_Application_Error__c> logs = new Set<Accel_Application_Error__c>();
        for(AccountData accountData : m.values()) {
            logs.add(accountData.log);
        }
        return logs;
    }
}