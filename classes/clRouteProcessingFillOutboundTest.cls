@IsTest
private class clRouteProcessingFillOutboundTest {
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
    static void test_retrieveRpsWrapper() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Route_Fill_Date__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps.Route_Fill_Date__c = date.today();
        update rps;

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRouteProcessingFillOutbound.retrieveRpsWrapper(rps.Id);
            System.assertEquals(dto.isSuccess,true);

            dto = clRouteProcessingFillOutbound.retrieveRpsWrapperNoCache(rps.Id,Math.random());
            System.assertEquals(dto.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateRpsStatus() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Route_Fill_Date__c,Processing_Status__c,Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        rps.Route_Fill_Date__c = date.today();
        update rps;

        Test.startTest();

        System.runAs(collector) {
            rps.Processing_Status__c = 'COMPLETED FILL';
            ResponseDto dto = clRouteProcessingFillOutbound.updateRpsStatus(rps);
            System.assertEquals(dto.isSuccess,true);

            rps.Processing_Status__c = 'BOGUS STATUS';
            dto = clRouteProcessingFillOutbound.updateRpsStatus(rps);
            System.assertEquals(dto.isSuccess,false);
        }

        Test.stopTest();
    }

}