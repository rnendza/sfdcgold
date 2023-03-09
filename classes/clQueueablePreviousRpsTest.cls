@IsTest
private class clQueueablePreviousRpsTest {

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
    static void test_prevRps_Single() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        //  Just add 1 RPS reading to fire the trigger / queueable again (after the ones initially created in the setup method)
        Route_Schedule_Account__c rsa = [SELECT Id,Account__c FROM Route_Schedule_Account__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];
        Route_Processing_Sheet__c rpsTmp = new Route_Processing_Sheet__c(
                Route_Schedule__c = routeSchedule.Id,
                Route_Schedule_Account__c = rsa.Id,
                Account__c = rsa.Account__c,
                Collection_Type__c = 'Regular - RT & VGT'
        );
        insert rpsTmp;

        Test.startTest();
        clQueueablePreviousRps q = new clQueueablePreviousRps(rpsTmp);
        System.enqueueJob(q);
        Test.stopTest();

        Route_Processing_Sheet__c updatedRps = [
                SELECT   Id, Previous_VGT_Collection__c
                FROM     Route_Processing_Sheet__c
                WHERE    Id = :rpsTmp.Id
        ];
        System.assert(updatedRps.Previous_VGT_Collection__c != null);
    }

}