@IsTest
private class AssetSvcTest {

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
    static void test_retrieveAccountVgts() {

        Route_Account__c  routeAccount = [SELECT Id, Account__c FROM Route_Account__c LIMIT 1];

        Test.startTest();

        List<Asset> assets = AssetSvc.retrieveAccountVgts(routeAccount.Account__c);
        System.assert(!assets.isEmpty());

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveAccountMachines() {

        Route_Account__c  routeAccount = [SELECT Id, Account__c FROM Route_Account__c LIMIT 1];

        Test.startTest();

        List<Asset> assets = AssetSvc.retrieveAccountMachines(routeAccount.Account__c);
        System.assert(!assets.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAccountRts() {

        Route_Account__c  routeAccount = [SELECT Id, Account__c FROM Route_Account__c LIMIT 1];

        Test.startTest();

        List<Asset> assets = AssetSvc.retrieveAccountRts(routeAccount.Account__c);
        //System.assert(!assets.isEmpty());

        Test.stopTest();
    }
}