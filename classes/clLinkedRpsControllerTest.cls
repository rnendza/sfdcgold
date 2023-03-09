@IsTest
private class clLinkedRpsControllerTest {

    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();
        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    public static void test_retrieveLinkedRps() {

        Id rpsId = [SELECT Id FROM Route_Processing_Sheet__c LIMIT 1].Id;
        clLinkedRpsController.RpsSearchParams params = new clLinkedRpsController.RpsSearchParams();

        Test.startTest();

        ResponseDto dto = clLinkedRpsController.retrieveLinkedRps(rpsId,params);

        List<clLinkedRpsController.RpsWrapper> wraps =
                (List<clLinkedRpsController.RpsWrapper>)dto.values.get(clLinkedRpsController.MAP_KEY_RPS_WRAPPERS);
        System.assert(dto.isSuccess);
        System.assert(!wraps.isEmpty());

        for(clLinkedRpsController.RpsWrapper wrap : wraps) {
            Boolean hasVgtVariance = wrap.hasVgtVariance;
            Boolean hasRtVariance = wrap.hasRtVariance;
        }

        Test.stopTest();
    }

    @IsTest
    public static void test_retrieveLinkedRpsTotalRecords() {

        Id rpsId = [SELECT Id FROM Route_Processing_Sheet__c LIMIT 1].Id;
        clLinkedRpsController.RpsSearchParams params = new clLinkedRpsController.RpsSearchParams();

        Test.startTest();

        ResponseDto dto = clLinkedRpsController.retrieveLinkedRpsTotalRecords(rpsId,params);

        Integer iTotal = (Integer)dto.values.get(clLinkedRpsController.MAP_KEY_RPS_TOTAL_CNT);
        System.assert(dto.isSuccess);
        System.assert(iTotal != 0);


        Test.stopTest();
    }

}