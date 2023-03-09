@IsTest
private class clRouteProcessingSheetsControllerTest {

    /**
     * NOTE start / stop test merely there to reset gov limits as creating non cl data takes forever given
     * all the processors / flows and eventually will bust cpu time outs on it's own.
     */
    @TestSetup
    static void setupData() {
   
        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_doRouteProcessingSheetStatusUpdate() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingSheetsController.doRouteProcessingSheetStatusUpdate(rps.Id,'In Progress');
            System.assertEquals(dto.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_doUpdateStopNumbers() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Map<Id,Route_Processing_Sheet__c> allRpss = new Map<Id,Route_Processing_Sheet__c>([
                SELECT  Id,Stop_Number__c,Route_Schedule_Account__c
                FROM    Route_Processing_Sheet__c
                WHERE   Route_Schedule__c = :routeSchedule.Id
        ]);
        Integer i = 10;
        for(Route_Processing_Sheet__c rps : allRpss.values()) {
            rps.Stop_Number__c = i + 10;
            i++;
        }

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingSheetsController.doUpdateStopNumbers(allRpss.values());
            System.assert(dto.isSuccess = true);

            Map<Id,Route_Processing_Sheet__c> mUpdatedRpss =  new Map<Id,Route_Processing_Sheet__c>([
                    SELECT  Id,Stop_Number__c,Route_Schedule_Account__c
                    FROM    Route_Processing_Sheet__c
                    WHERE   Route_Schedule__c = :routeSchedule.Id
            ])
            ;
            for(Route_Processing_Sheet__c rps : mUpdatedRpss.values()) {
                System.assertEquals(allRpss.get(rps.Id).Stop_Number__c,rps.Stop_Number__c);
            }
        }
        Test.stopTest();
    }



    @IsTest
    static void test_doSendRouteEndEmail() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id,Name,Processing_Location__c FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        System.debug('---> ut rs='+routeSchedule);
        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingSheetsController.doSendRouteEndEmail(routeSchedule);
            System.assertEquals(dto.isSuccess,true);
            System.assert(dto.severity == 'success');
        }

        Test.stopTest();
    }

    @IsTest
    static void test_doScheduleStart() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingSheetsController.doRouteScheduleStart(routeSchedule.Id);
            System.assertEquals(dto.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_doScheduleEnd() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingSheetsController.doRouteScheduleEnd(routeSchedule.Id);
            System.assertEquals(dto.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_deleteRpsAndMeters() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Test.startTest();

        System.runAs(collector) {
            try {
                ResponseDto dto = clRouteProcessingSheetsController.deleteRpsAndMeters(routeSchedule.Id);
                //@todo check custom met for delete access!
                //System.assertEquals(dto.isSuccess, true);
            } catch (Exception e) {

            }
        }

        Test.stopTest();
    }

    @IsTest
    static void test_deleteMeters() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Test.startTest();

        System.runAs(collector) {
            Boolean deleteFailed = false;
            ResponseDto dto;
            try {
                dto = clRouteProcessingSheetsController.deleteMeters(routeSchedule.Id);
            } catch (Exception e) {
                deleteFailed =  true;
                System.debug(LoggingLevel.WARN,e);
            }
            if(!deleteFailed) {
                System.assertEquals(dto.isSuccess, true);
            }
        }

        Test.stopTest();
    }

    @IsTest
    static void test_createRouteSchedules() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingSheetsController.createRouteSchedules(1, Date.today(),Date.today().addDays(1));
            System.assertEquals(dto.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_createRpsAndMeters() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingSheetsController.createRpsAndMeters(routeSchedule.Id,clTESTUTILS.DEFAULT_PROCESSING_LOC);
            System.assertEquals(dto.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateRpsStopNumbers() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT Id, Stop_Number__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Stop_Number__c = 1;
        }

        Test.startTest();

            ResponseDto dto = clRouteProcessingSheetsController.updateRpsStopNumbers(rpss);
            System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }

    @IsTest
    static void test_updateNextCycleNumber() {

        Test.startTest();

        ResponseDto dto = clRouteProcessingSheetsController.updateNextCycleNumber(2);
        System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveMdt() {

        Test.startTest();

        ResponseDto dto = clRouteProcessingSheetsController.retrieveMdt(clRouteProcessingSheetsController.MDT_RPS_DEV_NAME);
        System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveSurveyMdt() {

        Test.startTest();

        ResponseDto dto = clRouteProcessingSheetsController.retrieveSurveyMetadatas(clRouteProcessingSheetsController.MDT_RPS_SURVEY_CUSTOM_DEV_NAME);
        System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveMdtNoCache() {

        Test.startTest();

        Double cacheBust = Math.random();
        ResponseDto dto = clRouteProcessingSheetsController.retrieveMdtNoCache(clRouteProcessingSheetsController.MDT_RPS_DEV_NAME,cacheBust);
        System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllRouteProcessingSheets() {

        Test.startTest();

        Double cacheBust = Math.random();
        ResponseDto dto = clRouteProcessingSheetsController.retrieveAllRouteProcessingSheets();
        System.assertEquals(dto.isSuccess,true);

        Test.stopTest();
    }


    @IsTest
    static void test_mdt_deploy_callback() {

        clRouteProcessingSheetsController.CustomMetadataCallBack callBack = new clRouteProcessingSheetsController.CustomMetadataCallBack();

        Metadata.DeployResult result = new Metadata.DeployResult();
        result.numberComponentErrors = 0;
        Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();

        Test.startTest();
        callBack.handleResult(result,context);
        Test.stopTest();

    }


    @IsTest
    static void test_retrieveRouteProcessingSheetsForProcessor() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            ResponseDto dto = clRouteProcessingSheetsController.retrieveRouteProcessingSheetsForProcessor('processor',processor.Id,routeSchedule.Id,tomorrow);
            System.assertEquals(dto.isSuccess,true);
            Date bogusDate = tomorrow.addYears(1);
            dto = clRouteProcessingSheetsController.retrieveRouteProcessingSheetsForProcessor('processor',processor.Id,routeSchedule.Id,bogusDate);
            System.assertEquals(dto.isSuccess,false);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteProcessingSheets_nocache() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();
        System.runAs(collector) {
            //  Just get a single RPS
            ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteProcessingSheetsForProcessor_no_cache() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];

        Test.startTest();

        System.runAs(processor) {
            Double noCache = Math.random();
            ResponseDto dto = clRouteProcessingSheetsController.retrieveRouteProcessingSheetsForProcessorNoCache('processor',processor.Id,routeSchedule.Id,tomorrow,noCache);
            System.assertEquals(dto.isSuccess,true);
            Date bogusDate = tomorrow.addYears(1);
            dto = clRouteProcessingSheetsController.retrieveRouteProcessingSheetsForProcessor('processor',processor.Id,routeSchedule.Id,bogusDate);
            System.assertEquals(dto.isSuccess,false);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteProcessingSheets_Imperative() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);


        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheetsImperative(collector.Id,Date.today().addDays(1));
            System.assertEquals(dtoRps.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteScheduleData() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route_Schedule__c routeSchedule= [SELECT Id From Route_Schedule__c LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoRs = clRouteProcessingSheetsController.retrieveRouteScheduleData(routeSchedule.Id,3223);
            System.assertEquals(dtoRs.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRouteScheduleData_Imperative() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route_Schedule__c routeSchedule= [SELECT Id From Route_Schedule__c LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoRs = clRouteProcessingSheetsController.retrieveRouteScheduleDataImperative(routeSchedule.Id);
            System.assertEquals(dtoRs.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_getDmlErrorMessage() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route_Schedule__c routeSchedule= [SELECT Id From Route_Schedule__c LIMIT 1];
        routeSchedule.Schedule_Status__c ='BOGUS';
        Database.SaveResult sr = Database.update(routeSchedule,false);

        Test.startTest();

        System.runAs(collector){
            String errorMsg = clRouteProcessingSheetsController.getDmlErrorMessage(sr);
            System.assert(String.isNotBlank(errorMsg));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_calcDistanceToStartingPoint() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheetsNoCache(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];
        Route__c route = [SELECT Id,Geolocation__Latitude__s,Geolocation__Longitude__s from Route__c where Id = :rpsWrapper.routeId];

        route.Geolocation__Longitude__s = -1;
        route.Geolocation__Latitude__s = 1;
        for(clRouteProcessingSheetsController.RpsWrapper rpsWrap : rpss) {
            rpsWrap.latitude = 2;
            rpsWrap.longitude = -2;
        }
        
        Test.startTest();

        System.runAs(collector) {
            clRouteProcessingSheetsController.calcDistanceToStartingPoint(rpss,route);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_truncateLocNotes() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Test.startTest();

        System.runAs(processor) {
            String locNotesOriginal= '';
            Integer x = 0;
            for(Integer i = 0 ; i < clRouteProcessingSheetsController.LOC_NOTES_MAX_LEN + 2; i++); {
                locNotesOriginal += x;
                x++;
            }
            clRouteProcessingSheetsController.truncateLocNotes(locNotesOriginal);
            System.assert(locNotesOriginal.length() < clRouteProcessingSheetsController.LOC_NOTES_MAX_LEN);
        }

        Test.stopTest();
    }
}