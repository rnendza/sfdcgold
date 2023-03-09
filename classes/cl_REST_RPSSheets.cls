@RestResource(urlMapping='/rps/collector/sheets/*')
global with sharing class cl_REST_RPSSheets {

    @TestVisible private static Boolean FORCE_GET_SERVER_ERROR  = false;
    @TestVisible private static Boolean FORCE_RESPONSE_ERROR    = false;
    public static Boolean DEBUG                                 = false;
    public static final String BASE_URI = '/rps/collector/sheets/';

    /**
     * Primary HTTP_GET entry point.
     */
    @HttpGet
    global static void get() {
        RestResponse res = RestContext.response;
        Map<String,String> paramsMap = RestContext.request.params;
        if(DEBUG) {
            System.debug(LoggingLevel.DEBUG, 'Parameters = ' + paramsMap);
        }

        ResponseDto dto;
        try {
            dto = doGet();
            List<clRpsSheet> rpsSheets = cleanseResponse(dto);
            res.statuscode = HttpStatusCodes.OK;
            //  Serialize a list of clRpsSheet objects
            res.responseBody = Blob.valueOf(JSON.serialize(rpsSheets));
            res.addHeader('Content-Type', 'application/json');
        } catch (Warnings.EndUserMessageException msgEx) {
            res.responseBody = Blob.valueOf(msgEx.getMessage());
            res.statusCode = HttpStatusCodes.BAD_REQUEST;
            System.debug(LoggingLevel.WARN,'Get request warning: '+msgEx);
        } catch(Exception e) {
            res.responseBody = Blob.valueOf(String.valueOf(e) + '\n\n' + e.getStackTraceString());
            res.statusCode = HttpStatusCodes.INTERNAL_SERVER_ERROR;
            System.debug(LoggingLevel.ERROR,'Get request error: '+e);
        }
    }

    /**
     * Primary HTTP_POST entry point.
     * @todo error handling.
     */
    @HttpPost
    global static void post() {
        RestResponse res = RestContext.response;
        String jsonString = RestContext.request.requestBody.toString();
        if(DEBUG) {
            System.debug(LoggingLevel.DEBUG, 'json request body posted = ' + jsonString);
        }
        ResponseDto dto;
        dto = doPost();
        res.statuscode = HttpStatusCodes.OK;
        res.responseBody = Blob.valueOf(JSON.serialize(dto));
        res.addHeader('Content-Type', 'application/json');

    }
    /**
     * Takes the response from the current controller and strips it down to only info needed
     * to serialize to JSON and be recieved by the client.
     *
     * @param dto ResponseDto
     * @return A List of clRpsSheet objects to be serialized
     *
     * @todo change to user svc logic and trim queries?
     */
    private static List<clRpsSheet> cleanseResponse(ResponseDto dto ) {

        List<clRpsSheet> rpsSheets = new List<clRpsSheet>();

        List<clRouteProcessingSheetsController.RpsWrapper> rpsWrappers =
                (List<clRouteProcessingSheetsController.RpsWrapper>)dto.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);

        for(clRouteProcessingSheetsController.RpsWrapper rpsWrap : rpsWrappers) {
            //  constructor strips out info as needed.
            clRpsSheet rpsSheet = new clRpsSheet(rpsWrap);
            rpsSheets.add(rpsSheet);
        }
        return rpsSheets;
    }

    /**
     * @return ResponseDto containing route schedule and processing sheet information
     * @todo this is a mock for now.
     */
    private static ResponseDto doGet() {
        //  @todo pass params of collector id and collection date as opposed to mocking it here
        Route_Schedule__c routeSchedule = [
                SELECT Id,Assigned_Driver__c,Route_Collection_Date__c,Collector_1__c
                FROM Route_Schedule__c
                WHERE Assigned_Driver__c != NULL
                AND Collector_1__c != NULL
                AND Total_Processing_Sheets__c > 0
                LIMIT 1
        ];

        if(FORCE_GET_SERVER_ERROR) { //  Unit Test Specific / 500 error
            routeSchedule.Collector_1__c = '344344434'; // invalid id goes boom!
        }
        ResponseDto dto = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(  routeSchedule.Collector_1__c,
                                                                                            routeSchedule.Route_Collection_Date__c,
                                                                                            Math.random());
        if(FORCE_RESPONSE_ERROR) { // Unit Test Specific
            dto.isSuccess = false; // 400 error no records found.
            dto.message = 'fake error.. no records founds for params';
            Warnings.checkResponseDto(dto);
        }
        return dto;
    }

    /**
     * @return xxx
     * @todo a mock for now.
     */
    private static ResponseDto doPost() {
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        return dto;
    }
}