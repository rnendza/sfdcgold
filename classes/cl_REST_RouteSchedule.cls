@RestResource(urlMapping='/rs/collector/summary/*')
global with sharing class cl_REST_RouteSchedule {

    @TestVisible private static Boolean FORCE_GET_SERVER_ERROR  = false;
    @TestVisible private static Boolean FORCE_RESPONSE_ERROR    = false;
    public static Boolean DEBUG                                 = false;
    public static final String BASE_URI = '/rs/collector/summary/';

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
            clRouteScheduleInfo rsInfo = cleanseResponse(dto);
            //remove all the crap.
            res.statuscode = HttpStatusCodes.OK;
            res.responseBody = Blob.valueOf(JSON.serialize(rsInfo));
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


    private static clRouteScheduleInfo cleanseResponse(ResponseDto dto ) {

        clRouteScheduleInfo rsInfo;

        Route_Schedule__c routeSchedule = (Route_Schedule__c)dto.values.get(clRouteProcessingSheetsController.MAP_KEY_ROUTE_SCHEDULE_DATA);
        rsInfo = new clRouteScheduleInfo(routeSchedule);

        return rsInfo;
    }

    /**
     * @return ResponseDto containing route schedule and processing sheet information
     * @todo this is a mock for now.
     */
    private static ResponseDto doGet() {
        //  @todo pass params of collector id and collection date as opposed to mocking it here
        Route_Schedule__c routeSchedule = [
                SELECT Id,Name,Assigned_Driver__c,Route_Collection_Date__c,Collector_1__c
                FROM Route_Schedule__c
                WHERE Assigned_Driver__c != NULL
                AND Collector_1__c != NULL
                AND Total_Processing_Sheets__c > 0
                LIMIT 1
        ];

        if(FORCE_GET_SERVER_ERROR) { //  Unit Test Specific / 500 error
            routeSchedule.Id = '344344434'; // invalid id goes boom!
        }
        ResponseDto dto = clRouteProcessingSheetsController.retrieveRouteScheduleDataImperative(routeSchedule.Id);

        if(FORCE_RESPONSE_ERROR) { // Unit Test Specific
            dto.isSuccess = false; // 400 error no records found.
            dto.message = 'fake error.. no records founds for params';
            Warnings.checkResponseDto(dto);
        }
        return dto;
    }

}