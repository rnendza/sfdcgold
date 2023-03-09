/**
 * Ui backing class for Portal Admin - PA Advisory Loader. Performs RESTful search of provider data
 * as well as operations to upsert this data into PA_Advisory__c.
 *
 * @see PortalAdvisoryLoaderSvc
 * @see PortalAdvisoryLoaderControllerTest
 */
public class PortalAdvisoryLoaderController {

    public final static String MAP_KEY_PA_ADVISORY_STATE    = 'MAP_KEY_PA_ADVISORY_STATE';
    public final static String MAP_KEY_USER_RECORDS         = 'MAP_KEY_USER_RECORDS';
    public final static String MAP_KEY_PA_ADVISORY_RECORDS  = 'MAP_KEY_PA_ADVISORY_RECORDS';
    public final static String MAP_KEY_PERF_STATS           = 'MAP_KEY_PERF_STATS';
    public final static String MAP_KEY_PROVIDER_ERROR       = 'MAP_KEY_PROVIDER_ERROR';
    public final static String MAP_KEY_CALLOUT_PARAMS       = 'MAP_KEY_CALLOUT_PARAMS';

    public static Boolean DEBUG_LIMITS                   = true;
    public static Boolean DEBUG_PARAMS                   = true;
    public static Boolean WRITE_APP_LOGS                 = false;                                // @todo future use
    public static Accel_Application_Error__c log         = new Accel_Application_Error__c();     // @todo future use

    public static PerformanceStats performanceStats = new PerformanceStats();
    public static ProviderError providerError;  // mainly for bad http status codes.

    /**
     * Performs a live RESTful search to the PA Advisory Svc.
     *
     * @param calloutParams A CalloutParams object with the following minimal required fields:
     *                      dStartDate          Date   Advisory Start Date.
     *                      dEndEnd             Date   Advisory End Date.
     *                      customMdtDevName    String The Api_Setting__mdt dev name.
     *
     * @return              ResponseDto containing UserRecords in values object, and provider errors as well as perf stats.
     *
     * @see CalloutParams
     */
    @AuraEnabled
    public static ResponseDto doLiveSearch( CalloutParams calloutParams) {
        ResponseDto dto = new ResponseDto();
        buildCalloutParams(calloutParams,dto);
        dto.values.put(MAP_KEY_CALLOUT_PARAMS,calloutParams);

        if(DEBUG_PARAMS) {
            debugCalloutParams(dto,calloutParams);
        }

        if(dto.severity == 'error') { // some issue with dates or the customMdt dev name.
            return dto;
        }

        List<PortalAdvisoryLoaderSvc.UserRecord> userRecords = doRetrievePaData(calloutParams);
        dto.isSuccess = !userRecords.isEmpty();
        if((dto.message == null || dto.message == '') && !dto.isSuccess) {
            dto.message = 'No Records Found for provided date range: startDate: '+calloutParams.sStartDate + ' endDate: '+calloutParams.sEndDate;
            dto.severity = 'warning';
        }
        if(dto.isSuccess && calloutParams.matchToSfdcRecs) {
            matchToSfdcRecords(userRecords);
        }
        dto.values.put(MAP_KEY_USER_RECORDS,userRecords);

        if(providerError != null) {
            dto.message = 'Invalid Provider Response when performing the callout.. Provider HTTP Response= ' + providerError;
            dto.values.put(MAP_KEY_PROVIDER_ERROR,providerError);
        }
        if(DEBUG_LIMITS){
            dto.values.put(MAP_KEY_PERF_STATS,performanceStats);
        }
        return dto;
    }

    /**
     * Uses the advisoryNumber and advisoryType from the provider REST xml and matches against
     * the external Id field (Advisory_Number_And_Type__c) on SFDCPA_Advisory__c sObject..
     * If found attaches PA_Advisory__c to UserRecord so we can identify if the REST
     * record was already processed by SFDC as well as link to it. Modifies by reference.
     *
     * @param userRecords The UserRecords from the provider xml
     */
    @TestVisible
    private static  void matchToSfdcRecords(List<PortalAdvisoryLoaderSvc.UserRecord> userRecords) {

        Map<String,PortalAdvisoryLoaderSvc.UserRecord> mAdvisories = new Map<String,PortalAdvisoryLoaderSvc.UserRecord>();


        if(userRecords != null && !userRecords.isEmpty()) {
            for (PortalAdvisoryLoaderSvc.UserRecord ur : userRecords) {
                String concatKey =  ur.advisoryNumberAndType;
                mAdvisories.put(concatKey,ur);
            }
        }
        if(!mAdvisories.isEmpty()) {
            List<PA_Advisory__c> paAdvisories = [
                    SELECT Id, Name,Advisory_Number_And_Type__c
                    FROM   PA_Advisory__c
                    WHERE  Advisory_Number_And_Type__c IN :mAdvisories.keySet()
            ];
            if(!paAdvisories.isEmpty()) {
                for(PA_Advisory__c paAdvisory : paAdvisories) {
                    if(mAdvisories.containsKey(paAdvisory.Advisory_Number_And_Type__c)) {
                        PortalAdvisoryLoaderSvc.UserRecord ur = mAdvisories.get(paAdvisory.Advisory_Number_And_Type__c);
                        ur.paAdvisory = paAdvisory;
                    }
                }
            }
        }
    }

    /**
     * Retrieves custom Api_Setting__mdt. Modifies Dates to provider required string value.
     *
     * @param calloutParams A CalloutParams object - modified by ref
     * @param dto           A ResponseDto object - modified by ref.
     */
    public static void buildCalloutParams(CalloutParams calloutParams, ResponseDto dto) {
        API_Setting__mdt apiSetting;

        SObject oSetting = CustomMetadataSvc.retrieveCustomMetadata(API_Setting__mdt.getSObjectType(),calloutParams.customMdtDevName);

        if(oSetting == null) {
            dto.message = 'Could not find custom metadata settings for '+calloutParams.customMdtDevName;
            dto.severity = 'error';
            System.debug(LoggingLevel.WARN,' No custom mdt found for name: '+calloutParams.customMdtDevName);
        } else {
            apiSetting = (API_Setting__mdt)oSetting;
            dto.technicalMsg += 'custom mdt:'+apiSetting;
            calloutParams.apiSetting = apiSetting;
        }
        if(calloutParams.dStartDate != null && calloutParams.dEndDate != null) {
            calloutParams.sStartDate = getDateInProviderFormat(calloutParams.dStartDate);
            calloutParams.sEndDate = getDateInProviderFormat(calloutParams.dEndDate);
        } else {
            dto.message = 'Invalid date params startDate:'+calloutParams.dStartDate + ' endDate:'+calloutParams.dEndDate;
            dto.severity = 'error';
        }
    }
    /**
     * @param calloutParams A CalloutParams object with the following minimal required fields:
     *                      dStartDate          Date   Advisory Start Date.
     *                      dEndEnd             Date   Advisory End Date.
     *                      customMdtDevName    String The Api_Setting__mdt dev name.
     *
     * @return  A ResponseDto containing the user records searched / upserted in the values map.
     */
    @AuraEnabled
    public static ResponseDto doUpsertPaRecords(CalloutParams calloutParams) {
        ResponseDto dtoCreate = new ResponseDto();

        ResponseDto dtoSearch = doLiveSearch(calloutParams);
        CalloutParams modifiedParms = (CalloutParams)dtoSearch.values.get(MAP_KEY_CALLOUT_PARAMS);
        dtoCreate.values.put(MAP_KEY_CALLOUT_PARAMS,modifiedParms);

        List<PA_Advisory__c> advisories = new List<PA_Advisory__c>();
        List<PortalAdvisoryLoaderSvc.UserRecord> userRecords = new List<PortalAdvisoryLoaderSvc.UserRecord>();

        if(dtoSearch.isSuccess) {

            userRecords = (List<PortalAdvisoryLoaderSvc.UserRecord>)dtoSearch.values.get(MAP_KEY_USER_RECORDS);
            advisories = PortalAdvisoryLoaderSvc.upsertPaRecords(userRecords);

            if(!advisories.isEmpty()) {
                matchToSfdcRecords(userRecords);
                dtoCreate.isSuccess = true;
                String msg = advisories.size() + ' PA Advisory Records successfully upserted.';
                dtoCreate.message = msg;
                dtoCreate.severity = 'success';
            } else {
                dtoCreate.message = 'No records upserted';
                dtoCreate.severity = 'warning';
            }
        } else {
            dtoCreate.statusCode = dtoSearch.statusCode;
            dtoCreate.message = dtoSearch.message;
            dtoCreate.technicalMsg = dtoSearch.technicalMsg;
            dtoCreate.severity = dtoSearch.severity;
            dtoCreate.values.put(MAP_KEY_CALLOUT_PARAMS,calloutParams);
        }
        dtoCreate.values.put(MAP_KEY_USER_RECORDS,userRecords);
        dtoCreate.values.put(MAP_KEY_PA_ADVISORY_RECORDS,advisories);
        return dtoCreate;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveCurrentPaAdvisoryObjectState() {
        ResponseDto dto = new ResponseDto();

        PaAdvisoryState state = buildPaAdvisoryState();
        dto.values.put(MAP_KEY_PA_ADVISORY_STATE,state);
        dto.isSuccess = true;

        return dto;
    }

    @TestVisible
    private static PaAdvisoryState buildPaAdvisoryState() {
        PaAdvisoryState state = new PaAdvisoryState();

        state.totalRecords = PortalAdvisoryLoaderSvc.retrieveNumAdvisoryRecords();
        state.maxAdvisoryDate = PortalAdvisoryLoaderSvc.retrieveMaxAdvisoryDate();
        state.minAdvisoryDate = PortalAdvisoryLoaderSvc.retrieveMinAdvisoryDate();

        return state;
    }

   /**
    * Fire callout / parse xml. return list of wrapped objects.
    * EP will use the named cred: ie. callout:PGCBSelfExclusionService_Prod/GetUpdatesForDateRange/01012018/05052022
    *
    * @param calloutParams            CalloutParams (Dates, Custom mdt dev name)
    * @return  a List of UserRecords objects.
    *
    * @see UserRecord
    */
    public static List<PortalAdvisoryLoaderSvc.UserRecord> doRetrievePaData( CalloutParams calloutParams) {

        List<PortalAdvisoryLoaderSvc.UserRecord> userRecords = new List<PortalAdvisoryLoaderSvc.UserRecord>();

        Long startMillis = System.now().getTime();
        if(WRITE_APP_LOGS) {
            //  @todo init log but don't insert until after callout.
        }
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        Http http = new Http();

        String ep = 'callout:'+calloutParams.apiSetting.Named_Credential__c;
        ep+='/'+calloutParams.apiSetting.API_Method__c+'/';
        ep+=calloutParams.sStartDate+'/'+calloutParams.sEndDate;

        ep = Test.isRunningTest() ? 'http://callout.pamock.com' : ep;
        calloutParams.endPoint = ep;

        req.setEndpoint(ep);
        req.setMethod(calloutParams.apiSetting.Http_Method__c);
        req.setTimeout(Integer.valueOf(calloutParams.apiSetting.Http_Request_Timeout__c));
        if (DEBUG_LIMITS) {
            System.debug('--> before http send heapSize: '+Limits.getHeapSize());
        }

        resp = http.send(req);
        if (DEBUG_LIMITS) {
            System.debug('--> got response: heapSize: '+Limits.getHeapSize());
        }

        //  @todo skip parsing if exception / write logs.
        //  @todo check resp for status codes.
        if(WRITE_APP_LOGS) {
            //  @todo insert log. (then update during further processing below)
        }
        String msg = 'Http Status Info: Code='+ resp.getStatusCode() + ' Status='+resp.getStatus();
        System.debug(LoggingLevel.INFO,msg);

        String body = resp.getBody();
        if(calloutParams.debugXmlBody) {
            System.debug(body);
        }
        if(DEBUG_LIMITS) {
            system.debug('---> body Length: ' + body.length());
        }
        if(resp.getStatusCode() == HttpStatusCodes.OK) {
            userRecords = PortalAdvisoryLoaderSvc.parsePaXmlRecords(body, calloutParams.debugUserRecords,true,calloutParams.pullImageData);
        }  else {
            providerError = new ProviderError();
            providerError.httpStatus = resp.getStatus();
            providerError.httpStatusCode = resp.getStatusCode();
            List<String> errors = PortalAdvisoryLoaderSvc.findProviderErrors(body); //  populate the error array with messages from the provider.
            if(!errors.isEmpty()) {
                for(String error : errors) {
                    providerError.errorMessages.add(error);
                }
            }
            System.debug(LoggingLevel.ERROR,'--> Provider error messages:'+providerError.errorMessages);
        }
        //  @todo branch off and insert userRecords somewhere / create sfdc files etc.etc.
        //  @see FileUploadSvc / modify if needed..

        if (DEBUG_LIMITS) {
            Long totalMillis = System.now().getTime() - startMillis;
            performanceStats.totalMillis = totalMillis;
            performanceStats.cpuTime = Limits.getCpuTime();
            performanceStats.heapSize = Limits.getHeapSize();
            System.debug('---> HEAPSIZE used ' + Limits.getHeapSize() + ' OUT OF A MAX OF ' + Limits.getLimitHeapSize());
            System.debug('---> CPU time used ' + Limits.getCpuTime() + ' OUT OF A MAX OF ' + Limits.getLimitCpuTime());
            System.debug('---> Total execution millis: '+totalMillis);
            // nothing in LIMITS class for http response but it's the same as heapsize.
        }
        return userRecords;
    }


    /**
     * @param dt
     * @return String date that provider wants mmddyyyy
     */
    @TestVisible
    private static String getDateInProviderFormat(Date dt) {
        String day = String.valueOf(dt.day());
        if(day.length() == 1) {
            day = '0'+day;
        }
        String month = String.valueOf(dt.month());
        if(month.length() == 1) {
            month = '0'+month;
        }
        return month +  day + String.valueOf(dt.year());
    }

    @TestVisible
    private static void debugCalloutParams( ResponseDto dto, CalloutParams calloutParams) {
        dto.technicalMsg += calloutParams;
    }

    public class PaAdvisoryState {
        @AuraEnabled public Integer totalRecords = 0;
        @AuraEnabled public Date maxAdvisoryDate;
        @AuraEnabled public Date minAdvisoryDate;
    }

    public class PerformanceStats {
        @AuraEnabled public Long totalMillis;
        @AuraEnabled public Integer heapSize;
        @AuraEnabled public Integer cpuTime;
    }

    public class ProviderError {
        @AuraEnabled public Integer httpStatusCode;
        @AuraEnabled public String  httpStatus;
        @AuraEnabled public List<String> errorMessages;

        public ProviderError() {
            this.errorMessages = new List<String>();
        }
    }

    /**
     * Use for easy client calls.
     * ie.     @track _calloutParams = {dStartDate: this._startDate,dEndDate: this._endDate,customMdtDevName: this.customMdtDevName}
     */
    public class CalloutParams {

        @AuraEnabled public API_Setting__mdt apiSetting {get;set;}      //  Internal Use Only customMdtDevName used to query and pop this.
        @AuraEnabled public String sStartDate {get;set;}                //  Internal Use Only dStartDate converted to provider required format here.
        @AuraEnabled public Date   dStartDate {get;set;}                //  Required!
        @AuraEnabled public String sEndDate {get;set;}                  //  Internal Use Only dEndDate converted to provider required format here.
        @AuraEnabled public Date   dEndDate {get;set;}                  //  Required!
        @AuraEnabled public Boolean pullImageData = true;               //  Optional - pull base64 Data
        @AuraEnabled public Boolean debugUserRecords = true;            //  Optional - Debug Rest User Record Results
        @AuraEnabled public Boolean debugXmlBody = false;               //  Optional - spit out entire xml body
        @AuraEnabled public Boolean matchToSfdcRecs {get;set;}          //  Optional - Match by Advisory #, Advisory Type Concat Key
        @AuraEnabled public String endPoint {get;set;}                  //  Optional - Not really used.. replaced by Named Cred.
        @AuraEnabled public String customMdtDevName {get;set;}          //  Required!

        public CalloutParams() {
            this.matchToSfdcRecs = false;
        }
    }
}