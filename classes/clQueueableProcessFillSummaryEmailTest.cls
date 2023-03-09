@IsTest
private class clQueueableProcessFillSummaryEmailTest {

    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();
        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }


    @IsTest
    static void test_fireQueueable_with_region() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [
                SELECT Id,Notes__c,Processing_Location__c,Route_Fill_Date__c
                FROM Route_Processing_Sheet__c
                WHERE Route_Schedule__c = :routeSchedule.Id
        ];
        for(Route_Processing_Sheet__c rps : rpss) {
            rps.Route_Fill_Date__c = Date.today();
            rps.Cassette_1_Note_Count_Outbound__c = 1;
            rps.Cassette_5_Note_Count_Outbound__c = 5;
            rps.Cassette_20_Note_Count_Outbound__c = 20;
            rps.Cassette_50_Note_Count_Outbound__c = 50;
            rps.Cassette_100_Note_Count_Outbound__c = 100;
            //rps.Outbound_Total__c = 100;
        }
        update rpss;
        for(Route_Processing_Sheet__c rps : rpss) {
            System.debug('---> TEST RPS: '+rps);
        }

        Test.startTest();

        System.runAs(processor) {
            clQueueableProcessFillSummaryEmail q = new clQueueableProcessFillSummaryEmail(clTESTUTILS.DEFAULT_PROCESSING_LOC);
            Id jobId = System.enqueueJob(q);
        }
        Test.stopTest();
        // @todo asserts here...
    }
}