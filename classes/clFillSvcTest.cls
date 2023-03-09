@IsTest
private class clFillSvcTest {
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
    static void remove2ndRtTypeFromMetersCreation_test() {

        Account account = new Account( Name='Test UT ACCOUNT', ShippingState = 'IL');
        insert account;

        Asset rtAsset =   TestUtils.buildAsset('Sample RT Asset', account.Id, AssetSvc.ASSET_RT_REDEMPTION);
        rtAsset.GP_Manufacturer__c = 'NRT';
        rtAsset.SAS__c = 'RT1';
        insert rtAsset;

        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        Map<Id, Route_Schedule_Account__c> mRsas = new Map<Id, Route_Schedule_Account__c>([
                SELECT Id,Account__c
                FROM Route_Schedule_Account__c
                WHERE Route_Schedule__c = :routeSchedule.Id
                LIMIT 2
        ]);
        Set<Id> existingAccountIds = new Set<Id>();
        for(Route_Schedule_Account__c rsa : mRsas.values()) {
            existingAccountIds.add(rsa.Account__c);
        }

        Account newAccount = [SELECT Id FROM Account WHERE Id NOT IN :existingAccountIds LIMIT 1];
        String testAddtFillRtOnlyColType = new List<String>(clBatchRouteProcessingSheetCreation.COL_TYPES_NO_METER_CREATION).get(0);
        String testRegular2ndRtColType = clFillSvc.REGULAR_2ND_RT_COLLECTION_TYPE;

        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            //  Fires RSA Trigger / which creates child RPS / Meter Records.
            Route_Schedule_Account__c rsa1 = new Route_Schedule_Account__c(
                    Route_Schedule__c = routeSchedule.Id,
                    Account__c = newAccount.Id,
                    Collection_Type__c = testAddtFillRtOnlyColType
            );
            Route_Schedule_Account__c rsa2 = new Route_Schedule_Account__c(
                    Route_Schedule__c = routeSchedule.Id,
                    Account__c = newAccount.Id,
                    Collection_Type__c = testRegular2ndRtColType
            );
            List<Route_Schedule_Account__c> rsasInserted = new List<Route_Schedule_Account__c>{rsa1,rsa2};
            insert rsasInserted;

            Route_Processing_Sheet__c rps = [
                    SELECT Id,Route_Schedule__c,Account__c,Redemption_Asset__c
                    FROM   Route_Processing_Sheet__c
                    WHERE  Route_Schedule__c = :routeSchedule.Id
                    AND    Route_Schedule_Account__c IN :rsasInserted
            ];
            List<Meter_Reading__c> newMeterReadings = [
                    SELECT Id
                    FROM   Meter_Reading__c
                    WHERE  Route_Processing_Sheet__c = :rps.Id
            ];
            System.assert(newMeterReadings.isEmpty());
        }
        Test.stopTest();
    }

    @IsTest
    static void retrieve_RouteScheduleAccounts_test() {

        Account account = new Account( Name='Test UT ACCOUNT', ShippingState = 'IL');
        insert account;

        Asset rtAsset =   TestUtils.buildAsset('Sample RT Asset', account.Id, AssetSvc.ASSET_RT_REDEMPTION);
        rtAsset.GP_Manufacturer__c = 'NRT';
        rtAsset.SAS__c = 'RT1';
        insert rtAsset;

        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        Map<Id, Route_Schedule_Account__c> mRsas = new Map<Id, Route_Schedule_Account__c>([
                SELECT Id,Account__c
                FROM Route_Schedule_Account__c
                WHERE Route_Schedule__c = :routeSchedule.Id
                LIMIT 2
        ]);
        System.debug('---> UNIT TEST RSAS ='+mRsas);
        Set<Id> existingAccountIds = new Set<Id>();
        for(Route_Schedule_Account__c rsa : mRsas.values()) {
            existingAccountIds.add(rsa.Account__c);
        }
        System.debug('---> UNIT TEST existingAccountIds ='+existingAccountIds);

        System.debug('---> UNIT TEST ALL ACCOUNTS='+[SELECT ID, NAME FROM Account]);

        Account newAccount = [SELECT Id FROM Account WHERE Id NOT IN :existingAccountIds LIMIT 1];
        String testAddFillCollectionType =new List<String>(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES).get(0);

        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            //  Fires RSA Trigger / which creates child RPS / Meter Records.
            Route_Schedule_Account__c rsa = new Route_Schedule_Account__c(
                    Route_Schedule__c = routeSchedule.Id,
                    Account__c = newAccount.Id,
                    Collection_Type__c = testAddFillCollectionType
            );
            insert rsa;
            Route_Processing_Sheet__c rps = [
                    SELECT Id,Route_Schedule__c,Account__c,Redemption_Asset__c
                    FROM   Route_Processing_Sheet__c
                    WHERE  Route_Schedule__c = :routeSchedule.Id
                    AND    Route_Schedule_Account__c = :rsa.Id
            ];
            List<Meter_Reading__c> newMeterReadings = [
                    SELECT Id
                    FROM   Meter_Reading__c
                    WHERE  Route_Processing_Sheet__c = :rps.Id
            ];
            System.assert(rps.Redemption_Asset__c == rtAsset.Id);
        }
        Test.stopTest();
    }

    @IsTest
    static void check_Rps_Collection_Date_test() {

        Account account = new Account( Name='Test UT ACCOUNT', ShippingState = 'IL');
        insert account;

        Asset rtAsset =   TestUtils.buildAsset('Sample RT Asset', account.Id, AssetSvc.ASSET_RT_REDEMPTION);
        rtAsset.GP_Manufacturer__c = 'NRT';
        rtAsset.SAS__c = 'RT1';
        insert rtAsset;

        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        Map<Id, Route_Schedule_Account__c> mRsas = new Map<Id, Route_Schedule_Account__c>([
                SELECT Id,Account__c
                FROM Route_Schedule_Account__c
                WHERE Route_Schedule__c = :routeSchedule.Id
                LIMIT 2
        ]);
        System.debug('---> UNIT TEST RSAS ='+mRsas);
        Set<Id> existingAccountIds = new Set<Id>();
        for(Route_Schedule_Account__c rsa : mRsas.values()) {
            existingAccountIds.add(rsa.Account__c);
        }
        System.debug('---> UNIT TEST existingAccountIds ='+existingAccountIds);

        System.debug('---> UNIT TEST ALL ACCOUNTS='+[SELECT ID, NAME FROM Account]);

        Account newAccount = [SELECT Id FROM Account WHERE Id NOT IN :existingAccountIds LIMIT 1];
        String testAddFillCollectionType =new List<String>(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES).get(0);

        Test.startTest();

        System.runAs(new User(Id = UserInfo.getUserId())) {
            //  Fires RSA Trigger / which creates child RPS / Meter Records.
            Route_Schedule_Account__c rsa = new Route_Schedule_Account__c(
                    Route_Schedule__c = routeSchedule.Id,
                    Account__c = newAccount.Id,
                    Collection_Type__c = testAddFillCollectionType
            );
            insert rsa;
            Route_Processing_Sheet__c rps = [
                    SELECT Id,Route_Schedule__c,Account__c,Redemption_Asset__c,Collection_Date__c,
                            Route_Schedule__r.Route_Collection_Date__c
                    FROM Route_Processing_Sheet__c
                    WHERE Route_Schedule__c = :routeSchedule.Id
                    AND Route_Schedule_Account__c = :rsa.Id
            ];
            System.assertEquals(
                    rps.Collection_Date__c,
                    rps.Route_Schedule__r.Route_Collection_Date__c,
                    ' RPS Collection Date must be equal to Route Schedule Collection Date');
        }
        Test.stopTest();
    }
}