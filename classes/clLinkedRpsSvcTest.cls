@IsTest
private class clLinkedRpsSvcTest {

    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();
        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_retrieveRpsAdvancedSearch() {

        Route_Processing_Sheet__c rps = [SELECT Id,Account__c FROM Route_Processing_Sheet__c LIMIT 1];

        Test.startTest();

        List<Route_Processing_Sheet__c> rpss = clLinkedRpsSvc.retrieveRpsAdvancedSearch(
                10,rps.Id,rps.Account__c,null,null,90
        );
        System.assert(!rpss.isEmpty());

        rpss = clLinkedRpsSvc.retrieveRpsAdvancedSearch(
                10,rps.Id,rps.Account__c,false,false,null
        );
        System.assert(!rpss.isEmpty());

        rpss = clLinkedRpsSvc.retrieveRpsAdvancedSearch(
                10,rps.Id,rps.Account__c,true,false,null
        );
        System.assert(rpss.isEmpty());

        rpss = clLinkedRpsSvc.retrieveRpsAdvancedSearch(
                10,rps.Id,rps.Account__c,false,true,null
        );
        System.assert(rpss.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsAdvancedSearchTotalRecords() {

        Route_Processing_Sheet__c rps = [SELECT Id,Account__c FROM Route_Processing_Sheet__c LIMIT 1];

        Test.startTest();

        Integer iTotalRecs;

        iTotalRecs = clLinkedRpsSvc.retrieveRpsAdvancedSearchTotalRecords(
                rps.Id,rps.Account__c,null,null,90
        );
        System.assert(iTotalRecs != 0);

        iTotalRecs  = clLinkedRpsSvc.retrieveRpsAdvancedSearchTotalRecords(
                rps.Id,rps.Account__c,false,false,null
        );
        System.assert(iTotalRecs != 0);

        iTotalRecs  = clLinkedRpsSvc.retrieveRpsAdvancedSearchTotalRecords(
                rps.Id,rps.Account__c,true,false,null
        );
        System.assert(iTotalRecs == 0);

        iTotalRecs  = clLinkedRpsSvc.retrieveRpsAdvancedSearchTotalRecords(
                rps.Id,rps.Account__c,false,true,null
        );
        System.assert(iTotalRecs == 0);

        Test.stopTest();
    }

}