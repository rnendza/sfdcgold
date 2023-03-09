/**
 * Back end svc for GeoTab operations.
 * Contains separate auth call and auth / method request combo calls.
 * Generally returns the raw HttpResponse but will return apex objects on specific get... calls.
 *
 * Use send request method for generic calls and raw response bodies.
 * Use typed getXXX requests for objects returns and tighter ex handling/ logging.
 *
 * @see GeoTabUtils
 * @see https://geotab.github.io/sdk/software/api/reference/
 * @see https://geotab.github.io/sdk/software/api/reference/#Entity
 */
public class GeoTabSvc {

    public static String    DEFAULT_API_SETTING_DEV_NAME    = 'GeoTab_Prod';    //  Custom mdt dev name.
    public static Integer   DEFAULT_RESULTS_LIMIT           = 50000;            //  Max number of rows.
    public static Boolean   SUPPRESS_JSON_NULLS             = true;             //  Suppress null JSON props.
    public static Boolean   DEBUG_METHOD_CALL               = true;
    public static String    COUNT_METHOD                    = 'GetCountOf';     //  Count method.
    public static String    GET_METHOD                      = 'Get';
    public static String    LOGRECORD_TYPE                  = 'LogRecord';
    public static String    DEVICESTATUSINFO_TYPE           = 'DeviceStatusInfo';
    public static String    DEVICE_TYPE                     = 'Device';
    public static String    USER_TYPE                       = 'User';
    public static String    MDT_DEV_NAME_AUTH               = 'Authenticate';
    public static String    MDT_DEV_NAME_DEVICE_STATUS_INFO = 'DeviceStatusInfo';

    @TestVisible
    private static Boolean FORCE_AUTH_ERROR                 = false;

    /**
     * Auths and then sends the specific http request (method / typeName) using the resultsLimit to limit the number
     * of rows and search params. Exceptions are intentionally uncaught and should be handled by the client.
     *
     * @param req           An HttpRequest object.
     * @param method        The Method Name i.e. [Get,GetFeed,Authenticate..etc].
     * @param typeName      The typeName i.e. Entity [LogRecord,Device..etc].
     * @param id            An ID is used to uniquely reference entities in the API (client generated).
     * @param search        A GeoTabSearchParams instance.
     * @param resultsLimit  The max number of json rows.
     *
     * @return              An HttpResponse object.
     *
     * @see GeoTabSearchParams
     * @see https://geotab.github.io/sdk/software/api/reference/
     * @see https://geotab.github.io/sdk/software/api/reference/#Entity
     */
    public static HttpResponse sendRequest( HttpRequest req, String method, String typeName,
                                            String id, GeoTabSearchParams search, Integer resultsLimit) {

        GeoTabAuthJsonToApex authRes = GeoTabSvc.requestAuth(req);
        GeoTabParams params = new GeoTabParams(authRes.result.credentials, typeName, id, method,resultsLimit);
        if (search != null) {
            params.params.search = search;
        }
        req.setBody(JSON.serialize(params,SUPPRESS_JSON_NULLS));
        Http http = new Http();
        HttpResponse res = http.send(req);
        return res;
    }

    /**
     * Overload... Auths and then sends the specific http request (method / typeName) using the DEFAULT RESULTS LIMIT
     * and null params.
     *
     * @param req       An HttpRequest object.
     * @param method    The Method Name i.e. [Get,GetFeed,Authenticate..etc].
     * @param typeName  The typeName i.e. Entity [LogRecord,Device..etc].
     * @param id        An ID is used to uniquely reference entities in the API (client generated).
     *
     * @return          An HttpResponse object.
     *
     * @see https://geotab.github.io/sdk/software/api/reference/
     * @see https://geotab.github.io/sdk/software/api/reference/#Entity
     */
    public static HttpResponse sendRequest( HttpRequest req, String method, String typeName, String id) {
        return sendRequest(req,method,typeName,id,null,DEFAULT_RESULTS_LIMIT);
    }

    /**
     * Overload... Auths and then sends the specific http request (method / typeName) using the resultsLimit to
     * limit the number of rows and null search params.
     *
     * @param req           An HttpRequest object.
     * @param method        The Method Name i.e. [Get,GetFeed,Authenticate..etc].
     * @param typeName      The typeName i.e. Entity [LogRecord,Device..etc].
     * @param id            An ID is used to uniquely reference entities in the API (client generated).
     * @param resultsLimit  The max number of json rows.
     *
     * @return          An HttpResponse object.
     *
     * @see https://geotab.github.io/sdk/software/api/reference/
     * @see https://geotab.github.io/sdk/software/api/reference/#Entity
     */
    public static HttpResponse sendRequest( HttpRequest req, String method,String typeName, String id,Integer resultsLimit) {
        return sendRequest(req,method,typeName,id,null,resultsLimit);
    }

    /**
     * @param typeName  The typeName i.e. Entity [LogRecord,Device..etc].
     * @param id        An ID is used to uniquely reference entities in the API (client generated).
     *
     * @return          A GeoTabCountResult (if result is null check error property)
     */
    public static GeoTabCountResult getCountOf( String typeName, String id) {
        GeoTabCountResult countRes = new GeoTabCountResult();

        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex authRes = GeoTabSvc.requestAuth(req);
        GeoTabParams params = new GeoTabParams(authRes.result.credentials, typeName, id, COUNT_METHOD);
        req.setBody(JSON.serialize(params, SUPPRESS_JSON_NULLS));
        if(DEBUG_METHOD_CALL) {
            System.debug(LoggingLevel.DEBUG,'\n--> Method Call Body: '+req.getBody() +'\n');
        }
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == HttpStatusCodes.OK) {
            String jsonResponse = res.getBody();
            System.debug('res='+jsonResponse);
            countRes = GeoTabCountResult.parse(jsonResponse);
            if(countRes.result == null) {
                countRes.error = GeoTabError.parse(jsonResponse);
            }
        }
        return countRes;
    }

    /**
     * Performs auth and calls the LogRecord Get Method.
     *
     * @param id             An ID is used to uniquely reference entities in the API (client generated).
     * @param search         A GeoTabSearchParams instance.
     * @param resultsLimit   The max number of json rows.
     *
     * @return               A GeoTabLogRecordsResult object (array of records in the result property).
     */
    public static GeoTabLogRecordsResult getLogRecords(  String id, GeoTabSearchParams search,Integer resultsLimit) {
        GeoTabLogRecordsResult logRecordsResult  = new GeoTabLogRecordsResult();

        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex authRes = GeoTabSvc.requestAuth(req);

        GeoTabParams params = new GeoTabParams(authRes.result.credentials, LOGRECORD_TYPE, id, GET_METHOD,resultsLimit);
        if (search != null) {
            params.params.search = search;
        }
        req.setBody(JSON.serialize(params, SUPPRESS_JSON_NULLS));
        if(DEBUG_METHOD_CALL) {
            System.debug(LoggingLevel.DEBUG,'\n--> Method Call Body: '+req.getBody() +'\n');
        }
        Http http = new Http();
        HttpResponse res = http.send(req);
        //if(DEBUG_METHOD_CALL) {
            System.debug(LoggingLevel.DEBUG,'\n--> Method Call Response: '+res.getBody() +'\n');
        //}

        if (res.getStatusCode() == HttpStatusCodes.OK) {
            String jsonResponse = res.getBody();
            logRecordsResult  = GeoTabLogRecordsResult.parse(jsonResponse);
            logRecordsResult.searchParams = search;
            if(logRecordsResult.result == null) {
                logRecordsResult.error = GeoTabError.parse(jsonResponse);
            }
        }
        return logRecordsResult;
    }

    /**
     * Performs auth and calls the DeviceStatusInfo Get Method. (Creates its own log internally)
     *
     * @param id             An ID is used to uniquely reference entities in the API (client generated).
     * @param search         A GeoTabSearchParams instance.
     * @param resultsLimit   The max number of json rows.
     *
     * @return               A GeoTabLogRecordsResult object (array of records in the result property).
     */
    public static GeoTabDeviceStatusInfoResult getDeviceStatusInfo(  String id, GeoTabSearchParams search,Integer resultsLimit) {
        return getDeviceStatusInfo(id,search,resultsLimit,new Accel_Application_Error__c());
    }

    /**
     * Performs auth and calls the DeviceStatusInfo Get Method. (Log is passed)
     *
     * @param id             An ID is used to uniquely reference entities in the API (client generated).
     * @param search         A GeoTabSearchParams instance.
     * @param resultsLimit   The max number of json rows.
     * @param log            An instance of Accel_Application_Error__c. This will not be inserted but populated
     *                       and returned (by ref) to the calling client.
     *
     * @return               A GeoTabLogRecordsResult object (array of records in the result property).
     */
    public static GeoTabDeviceStatusInfoResult getDeviceStatusInfo(  String id, GeoTabSearchParams search,
                                                                     Integer resultsLimit,Accel_Application_Error__c log) {

        GeoTabDeviceStatusInfoResult infoResult  = new GeoTabDeviceStatusInfoResult();
        GeoTab_Setting__mdt mdt = queryForMetadata(MDT_DEV_NAME_DEVICE_STATUS_INFO);

        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex authRes = GeoTabSvc.requestAuth(req);
        if(authRes.error != null) {
            //  Auth Failure.. Short Circuit return.
            infoResult.error = authRes.error;
            String logMsg = '\n* AUTH ERROR!: '+infoResult.error;
            log.Stack_Trace__c += logMsg;
            System.debug(LoggingLevel.ERROR,logMsg);
            return infoResult;
        } else {
            String logMsg = '\n* Auth Success: '+authRes;
            log.Execution_Details__c += logMsg;
            System.debug(logMsg);
        }

        GeoTabParams params = new GeoTabParams(authRes.result.credentials, DEVICESTATUSINFO_TYPE, id, GET_METHOD,resultsLimit);

        if (search != null) {
            params.params.search = search;
        }

        req.setBody(JSON.serialize(params, SUPPRESS_JSON_NULLS));

        if(mdt.Log_Callout_Request__c || Test.isRunningTest()) {
            String logMsg = '\n* Method DeviceStatusInfo Request Call Body:  '+req.getBody() +'\n';
            System.debug(LoggingLevel.DEBUG,logMsg);
            // Will exceed RTE field size with too many records. --> log.Execution_Details__c += logMsg;
        }

        Http http = new Http();
        HttpResponse res = http.send(req);

        if(mdt.Log_Callout_Response__c || Test.isRunningTest()) {
            String logMsg = '\n* Method DeviceStatusInfo Response Http Info:  '+res +'\n';
            System.debug(LoggingLevel.DEBUG,logMsg);
            log.Execution_Details__c += logMsg;
            logMsg = '\n* Method DeviceStatusInfo Response Body:  '+res.getBody() +'\n';
            System.debug(LoggingLevel.DEBUG,logMsg);
            // Will exceed RTE field size with too many records. -->  log.Execution_Details__c += logMsg;
        }
        if (res.getStatusCode() == HttpStatusCodes.OK) {
            String jsonResponse = res.getBody();
            infoResult  = GeoTabDeviceStatusInfoResult.parse(jsonResponse);
            infoResult.httpStatusCode = HttpStatusCodes.OK;
            infoResult.searchParams = search;
            if(infoResult.result == null) {
                infoResult.error = GeoTabError.parse(jsonResponse);
                String logMsg = '\n* Vendor Method Call ERROR! '+infoResult.error;
                log.Stack_Trace__c += logMsg;
                System.debug(LoggingLevel.ERROR,logMsg);
            }
        } else {
            infoResult.httpStatusCode = res.getStatusCode();
            String logMsg = '\n* Bad http status: '+res;
            log.Stack_Trace__c += logMsg;
            System.debug(LoggingLevel.ERROR,logMsg);
        }
        return infoResult;
    }

    /**
     * Find all Devices with (or without) given search parameters.
     *
     * @param id             An ID is used to uniquely reference entities in the API (client generated).
     * @param search         A GeoTabSearchParams instance.
     * @param resultsLimit   The max number of json rows.
     *
     * @return               A GeoTabDeviceResults instance.
     *
     * @see GeoTabDeviceResult
     */
    public static GeoTabDeviceResult getDevices(  String id, GeoTabSearchParams search,Integer resultsLimit) {
        GeoTabDeviceResult deviceResult  = new GeoTabDeviceResult();

        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex authRes = GeoTabSvc.requestAuth(req);
        if(authRes.error != null) {
            //  Auth Failure.. Short Circuit return.
            deviceResult.error = authRes.error;
            String logMsg = '\n* AUTH ERROR!: '+deviceResult.error;
            System.debug(LoggingLevel.ERROR,logMsg);
            return deviceResult;
        }

        GeoTabParams params = new GeoTabParams(authRes.result.credentials, DEVICE_TYPE, id, GET_METHOD,resultsLimit);
        if (search != null) {
            params.params.search = search;
        }

        req.setBody(JSON.serialize(params, SUPPRESS_JSON_NULLS));
        System.debug('---> getDeviceReqs req body:'+req.getBody());
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == HttpStatusCodes.OK) {
            String jsonResponse = res.getBody();
            System.debug('---> getDevices json resp='+jsonResponse);
            deviceResult  = GeoTabDeviceResult.parse(jsonResponse);
            if(deviceResult.result == null) {
                deviceResult.error = GeoTabError.parse(jsonResponse);
            }
        }
        return deviceResult;
    }

    /**
     * Find all Users with (or without) given search parameters.
     *
     * @param id             An ID is used to uniquely reference entities in the API (client generated).
     * @param search         A GeoTabSearchParams instance.
     * @param resultsLimit   The max number of json rows.
     *
     * @return               A GeoTabUserResult instance.
     *
     * @see GeoTabDeviceResult
     */
    public static GeoTabUserResult getUsers(  String id, GeoTabSearchParams search,Integer resultsLimit) {
        GeoTabUserResult userResult  = new GeoTabUserResult();

        HttpRequest req = new HttpRequest();
        GeoTabAuthJsonToApex authRes = GeoTabSvc.requestAuth(req);
        if(authRes.error != null) {
            //  Auth Failure.. Short Circuit return.
            userResult.error = authRes.error;
            String logMsg = '\n* AUTH ERROR!: '+userResult.error;
            System.debug(LoggingLevel.ERROR,logMsg);
            return userResult;
        }

        GeoTabParams params = new GeoTabParams(authRes.result.credentials, USER_TYPE, id, GET_METHOD,resultsLimit);
        if (search != null) {
            params.params.search = search;
        }

        req.setBody(JSON.serialize(params, SUPPRESS_JSON_NULLS));
        System.debug('---> getUsers req body:'+req.getBody());
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == HttpStatusCodes.OK) {
            String jsonResponse = res.getBody();
            System.debug('---> getUsers json resp='+jsonResponse);
            userResult  = GeoTabUserResult.parse(jsonResponse);
            if(userResult.result == null) {
                userResult.error = GeoTabError.parse(jsonResponse);
            }
        }
        return userResult;
    }

    /**
     * Performs an auth call using uName,pw,database name stored in custom mdt and returns object with session id.
     * Attempts to retrieve auth json response from Platform Cache. If exists.. returns without callout, if not
     * performs a callout, and stores in cache for retrieval for the next time.
     *
     * @param req       An HttpRequest object.
     * @return          An instance of GeoTabAuthJsonToApex containing sessionId.
     *
     * @see GeoTabAuthJsonToApex
     * @see API_Setting__mdt
     */
    public static GeoTabAuthJsonToApex requestAuth(HttpRequest req) {

        GeoTabAuthJsonToApex jsonObj;
        Http http = new Http();
        GeoTab_Setting__mdt mdt = queryForMetadata(MDT_DEV_NAME_AUTH);
        req = buildHttpRequest(req, GeoTabTransaction.AUTH);

        GeoTabAuthJsonToApex cachedJsonObj;
        Boolean cacheError = false;
        try {
            cachedJsonObj = GeoTabPlatformCacheSvc.getAuthResp();
        } catch (cache.Org.OrgCacheException ex) {
            System.debug(LoggingLevel.ERROR, '\n---> OrgCacheException: ' + ex + '\n');
            cacheError = true;
        }
        if(cachedJsonObj != null && !cacheError) {
            if (mdt.Log_Callout_Request__c) {
                System.debug(LoggingLevel.DEBUG, '\n---> Skipped callout returning cached auth resp json:'+cachedJsonObj + '\n');
            }
            return cachedJsonObj;
        }

        if (mdt.Log_Callout_Request__c) {
            System.debug(LoggingLevel.DEBUG, '\n---> Auth Call Body: ' + req.getBody() + '\n');
        }
        HttpResponse res;

        try {
            res = http.send(req);
            if (mdt.Log_Callout_Response__c) {
                System.debug(LoggingLevel.DEBUG, '\n---> Auth Call Response: ' + res + '\n');
                System.debug(LoggingLevel.DEBUG, '\n---> Auth Call Response Body: ' + res.getBody() + '\n');
            }
            if (res.getStatusCode() == HttpStatusCodes.OK) {
                String jsonResponse = res.getBody();
                jsonObj = GeoTabAuthJsonToApex.parse(jsonResponse);
                if(jsonObj.result == null) {
                    GeoTabError error = GeoTabError.parse(res.getBody());
                    jsonObj.error = error;
                } else {
                    if(!cacheError) {
                        GeoTabPlatformCacheSvc.putAuthResp(jsonObj);
                    } else {
                        System.debug(LoggingLevel.WARN, '\n---> Cache is corrupted. not using cache!');
                    }
                }
            }
        } catch (Exception ex) {
            jsonObj = new GeoTabAuthJsonToApex();
            jsonObj.ex = ex;
            System.debug(LoggingLevel.ERROR, ex);
        }
        return jsonObj;
    }

    /**
     * Build http request overload.
     *
     * @param req       An HttpRequest object.
     * @param trans     The eNum type of transaction i.e. AUTH.
     *
     * @return          An HttpRequest object.
     */
    public static HttpRequest buildHttpRequest(HttpRequest req, GeoTabTransaction trans) {
        return buildHttpRequest(req, trans, DEFAULT_API_SETTING_DEV_NAME);
    }

    /**
     * @param req               An HttpRequest object.
     * @param trans             The eNum type of transaction i.e. AUTH.
     * @param apiSettingName    The developer name of the custom mdt type.
     *
     * @return          An HttpRequest object.
     */
    public static HttpRequest buildHttpRequest(HttpRequest req, GeoTabTransaction trans, String apiSettingName) {
        switch on trans {
            when AUTH {
                req = buildAuthHttpRequest(req, apiSettingName);
            }
            when else {
                System.debug(LoggingLevel.ERROR, '---> Invalid GeoTab transaction requested:' + trans.name());
            }
        }
        return req;
    }

    /**
     * @param req               An HttpRequest object.
     * @param apiSettingName    The developer name of the custom mdt type.
     *
     * @return          An HttpRequest object.
     */
    public static HttpRequest buildAuthHttpRequest(HttpRequest req, String apiSettingName) {

        API_Setting__mdt mdt = ApiSvc.retrieveApiSetting(apiSettingName);

        if (mdt != null) {
            req.setHeader('Content-Type', mdt.Content_Type__c);
            req.setHeader('cache-control', mdt.cache_control__c);
            req.setEndpoint(mdt.Endpoint__c + '/' + mdt.API_Method__c);
            req.setMethod(mdt.Http_Method__c);

            GeoTabAuth auth = new GeoTabAuth(mdt.Database__c, mdt.Username__c, mdt.Password__c);

            if(FORCE_AUTH_ERROR) {  // unit test only
                auth.params.userName = 'bogus';
            }
            String authJson = JSON.serialize(auth);
            req.setBody(authJson);
        }
        return req;
    }

    /**
     * Query for ServiceResource sObjects that have GeoTabId__c != NULL and IsActive
     *
     * @param srIds     A Set of ServiceResource.Id values if we want to further filter the query on ServiceResource,
     *                  Otherwise null.
     * @return          A List of ServiceResource sObjects.
     *
     *
     */
    public Static List<ServiceResource> retrieveServiceResources(Set<Id> srIds) {
        List<ServiceResource> resources;
        String q = '';
        q += ' SELECT {0} ';
        q += ' FROM    ServiceResource ';
        q += ' WHERE   GeoTabId__c != NULL ';
        q += ' AND     IsActive = TRUE ';  //  Added isActive 10/27

        String filter = '';
        if(srIds != null) {
            filter += ' AND Id IN :srIds ';
        }
        if(String.isNotBlank(filter)) {
            q += filter;
        }

        String formattedQuery = String.format(q,getAllFields(ServiceResource.SObjectType));
        resources = Database.query(formattedQuery);
        return resources;
    }

    /**
     * Retrieves minimal amount of ServiceResource fields for update.
     *
     * @param geoTabIds A set of ServiceResource.GeoTabId__c values.
     * @return          A Map of ServiceResource.Id => ServiceResource
     */
    public static Map<Id, ServiceResource> retrieveServiceResourcesForUpdate(Set<String> geoTabIds) {

        Map<Id, ServiceResource> m = new Map<Id, ServiceResource>([
                SELECT Id, GeotabId__c, LastKnownLatitude, LastKnownLongitude, ActivityStatus__c
                FROM ServiceResource
                WHERE GeotabId__c IN :geoTabIds
                AND GeotabId__c != NULL
                AND IsActive = TRUE  //  Added isActive 10/27
        ]);
        return m;
    }

    public static Integer retrieveNumActiveServiceResources() {
        return [ SELECT Count() FROM ServiceResource WHERE IsActive = TRUE ];
    }

    public static Integer retrieveNumActiveServiceResourcesWithGeoTabId() {
        return [ SELECT Count() FROM ServiceResource WHERE IsActive = TRUE AND GeotabId__c != NULL ];
    }

    public static Integer retrieveNumActiveServiceResourcesWithoutGeoTabId() {
        return [ SELECT Count() FROM ServiceResource WHERE IsActive = TRUE AND GeotabId__c = NULL ];
    }

    /**
     * Select the Custom Metadata type by developername.
     *
     * @param developerName The developername of the custom metadata record.
     * @return              An instance of GeoTab_Setting__mdt if found, otherwise null.
     */
    public static GeoTab_Setting__mdt queryForMetadata(String developerName) {
        GeoTab_Setting__mdt mdt;

        SObject sObj = CustomMetadataSvc.retrieveCustomMetadata(GeoTab_Setting__mdt.getSobjectType(), developerName);
        if(sObj != null) {
            mdt = (GeoTab_Setting__mdt)sObj;
        }
        return mdt;
    }

    /**
     * @param sObjType  The type of sObject to field all the fields for.
     * @return          A List of all fields on the sObject Type.
     */
    public static List<String>  getAllFields(SObjectType sObjType) {
        Map<String, Schema.SObjectField> fieldsMap = sObjType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }










    // ====== FUTURE USE?? =======
    //    public Static List<CollectionVehicle__c> retrieveAllCollectionVehicles() {
//        List<CollectionVehicle__c> vehicles;
//        String q = '';
//        q += 'SELECT {0} ';
//        q += 'FROM   CollectionVehicle__c ';
//
//        String formattedQuery = String.format(q,getAllFields(CollectionVehicle__c.SObjectType));
//        vehicles = Database.query(formattedQuery);
//        return vehicles;
//    }
//
//    public Static List<ServiceTerritoryMember> retrieveAllServiceTerritoryMembers() {
//        List<ServiceTerritoryMember> stms;
//        String q = '';
//        q += 'SELECT {0} ';
//        q += 'FROM   ServiceTerritoryMember ';
//
//        String formattedQuery = String.format(q,getAllFields(ServiceTerritoryMember.SObjectType));
//        stms = Database.query(formattedQuery);
//        return stms;
//    }
}