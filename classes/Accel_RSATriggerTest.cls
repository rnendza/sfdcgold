@IsTest
private class Accel_RSATriggerTest {

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
    static void test_deleteRsas() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT  Id,Processor_RT_Status__c  FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        Map<Id,Route_Schedule_Account__c> mRsas = new Map<Id,Route_Schedule_Account__c>([
                SELECT  Id
                FROM    Route_Schedule_Account__c
                WHERE   Route_Schedule__c = :routeSchedule.Id
        ]);

        Test.startTest();

        try {
            delete mRsas.values();
            rpss = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule_Account__c  IN :mRsas.keySet()];
            System.assert(rpss.size() == 0);
        } catch (Exception e) {
            System.debug(e);
        }

        Test.stopTest();
    }
    /**
     * Tests the following use case.
     * - Route schedule has Location A as a Route Schedule Account.
     * - Additional Fill Route Schedule Account also created for Location A.
     * - Additional Fill Route Schedule Account is Deleted.
     *
     *  1. Regression - Ensure RPS for Additional Fill RSA is Deleted.
     *  2. Fix Test   - Ensure RPS for Non Deleted RSA is NOT deleted.
     *
     * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4000610475
     */
    @IsTest
    static void test_deleteRsa() {

        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id,Route_Collection_Date__c,Processing_Location__c FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Schedule_Account__c existingRsa = [SELECT Id, Account__c,Stop_Number__c FROM Route_Schedule_Account__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        //  Clear out existing test records that may muddy the waters.
        delete [SELECT Id FROM Route_Processing_Sheet__c WHERE Account__c = :existingRsa.Account__c AND Route_Schedule_Account__c != :existingRsa.Id];
        delete [SELECT Id FROM Route_Schedule_Account__c WHERE Account__c = :existingRsa.Account__c AND Id != :existingRsa.Id];

        List<String> additionalFillCollectionTypes = new List<String>();
        additionalFillCollectionTypes.addAll(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES);

        //  Create a new Additional Fill Route Schedule Account.
        Route_Schedule_Account__c newRsa   = new Route_Schedule_Account__c();
        newRsa.Route_Schedule__c           = routeSchedule.Id;
        newRsa.Account__c                  = existingRsa.Account__c;
        newRsa.Collection_Type__c          = additionalFillCollectionTypes[0];
        newRsa.Stop_Number__c              = existingRsa.Stop_Number__c;
        insert newRsa;

        //  We don't need to Create a new Additional Fill Route Processing Sheet as the trigger automatically does this.
        List<Route_Processing_Sheet__c> tmpRpss = [
                SELECT Id
                FROM   Route_Processing_Sheet__c
                WHERE  Route_Schedule_Account__c = :newRsa.Id
                AND    Collection_Type__c = :additionalFillCollectionTypes[0]
        ];
        System.assertEquals(1, tmpRpss.size());


        Test.startTest();


        // Note try catch is in case we turn on logic that prevents any and all deletes in the org.
        try {
            Id deletedRsaId = existingRsa.Id;
            //  (1) Delete RSA and Ensure it's direct child was deleted. (Regression Test)
            delete existingRsa;

            List<Route_Processing_Sheet__c> existingRpssDeleted = [
                    SELECT Id
                    FROM   Route_Processing_Sheet__c
                    WHERE  Route_Schedule_Account__c = :deletedRsaId
                    AND    Route_Schedule__c = :routeSchedule.Id
            ];
            System.assert(existingRpssDeleted.isEmpty());

        } catch (Exception e) {
            System.debug(e);
        }

        Test.stopTest();


        //  (2) Ensure new RPS tied to Same Account as deleted RSA (But different RSA Parent Record) WAS NOT Deleted. (Fix)
        List<Route_Processing_Sheet__c> newRpssForNewRsa = [
                SELECT Id
                FROM   Route_Processing_Sheet__c
                WHERE  Route_Schedule_Account__c = :newRsa.Id
                AND    Route_Schedule__c = :routeSchedule.Id

        ];
        System.assertEquals(newRpssForNewRsa.size(),1);
    }


    @IsTest
    static void test_updateStopNumberRsas() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        List<Route_Processing_Sheet__c> rpss = [SELECT  Id,Stop_Number__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        List<Route_Schedule_Account__c> rsas = [SELECT ID,Stop_Number__c FROM Route_Schedule_Account__c WHERE Route_Schedule__c = :routeSchedule.Id];

        Test.startTest();

        System.assertEquals(rpss.size(),rsas.size());
        for(Route_Schedule_Account__c rsa : rsas) {
            rsa.Stop_Number__c = rsa.Stop_Number__c + 1;
        }
        update rsas;

        rpss =  [SELECT  Id,Stop_Number__c,Route_Schedule_Account__r.Stop_Number__c FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id];
        for(Route_Processing_Sheet__c rps : rpss) {
            System.assertEquals(rps.Stop_Number__c,rps.Route_Schedule_Account__r.Stop_Number__c);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_createAdditionalFill() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Account account1 = [SELECT Id FROM Account LIMIT 1];
        Account account2 = [SELECT Id FROM Account WHERE Id != :account1.Id LIMIT 1];
        Test.startTest();

        Route_Schedule_Account__c routeScheduleAccount1 = new Route_Schedule_Account__c();
        routeScheduleAccount1.Route_Schedule__c = routeSchedule.Id;
        routeScheduleAccount1.Account__c = account1.Id;
        routeScheduleAccount1.Collection_Type__c = new List<String>(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES)[0];

        Route_Schedule_Account__c routeScheduleAccount2 = new Route_Schedule_Account__c();
        routeScheduleAccount2.Route_Schedule__c = routeSchedule.Id;
        routeScheduleAccount2.Account__c = account2.Id;
        routeScheduleAccount2.Collection_Type__c = new List<String>(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES)[0];

        List<Route_Schedule_Account__c> rsasNew = new List<Route_Schedule_Account__c>{routeScheduleAccount1,routeScheduleAccount2};

        insert rsasNew;

        List<Route_Processing_Sheet__c> rpssNew = [
                SELECT Id, Stop_Number__c
                FROM Route_Processing_Sheet__c
                WHERE Route_Schedule_Account__c IN  :rsasNew
        ];
        List<Route_Processing_Sheet__c> allRpss = [
                SELECT Id,Stop_Number__c
                FROM   Route_Processing_Sheet__c
                WHERE  Route_Schedule__c = :routeSchedule.Id
                ORDER  By Stop_Number__c ASC
        ];
        for(Route_Processing_Sheet__c rps1 : allRpss) {
            System.debug('---> stop number test:'+rps1.Stop_Number__c);
        }
       // System.assertEquals(allRpss.size(), Integer.valueOf(rps.Stop_Number__c));



        Test.stopTest();
    }

    @IsTest
    static void test_fire_pe_changeevt() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];

        List<Route_Processing_Sheet__c> rpss = [
                SELECT Id,Account__c
                FROM   Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id
        ];

        Test.startTest();
        RouteScheduleAccountTriggerHandler.fireChangePlatformEvent(rpss);
        Test.stopTest();
    }

    @IsTest
    static void test_create_tasks() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];

        List<Route_Processing_Sheet__c> rpss = [
                SELECT Id,Account__c,Route_Schedule__c,Account__r.Name,
                        Name,Route_Schedule__r.Name
                FROM   Route_Processing_Sheet__c
                WHERE  Route_Schedule__c = :routeSchedule.Id
        ];

        Test.startTest();
        RouteScheduleAccountTriggerHandler.createTasks(rpss);
        Test.stopTest();
    }

    @IsTest
    private static void test_tagRedemptionAssets() {

        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c LIMIT 1];
        routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeSchedule.Id);

        Account account = new Account( Name='Test UT ACCOUNT', ShippingState = 'IL');
        insert account;

        Asset rtAsset =   TestUtils.buildAsset('Sample RT Asset1', account.Id, AssetSvc.ASSET_RT_REDEMPTION);
        rtAsset.GP_Manufacturer__c = 'NRT';
        rtAsset.SAS__c = 'RT1';
        insert rtAsset;

        Test.startTest();

        //  (1)  Test insert. 1 RT ASset.  Regular 2nd Collection Type
        Route_Schedule_Account__c rsa = new Route_Schedule_Account__c(
                Route_Schedule__c = routeSchedule.Id,
                Account__c = account.Id,
                Collection_Type__c = clFillSvc.REGULAR_2ND_RT_COLLECTION_TYPE
        );
        insert rsa;
        rsa = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds( new Set<Id> {rsa.Id})[0];
        System.assert(rsa.Redemption_Asset__c == rtAsset.Id);

        //  (2)  Test insert. 1 RT Asset.  Any of the Additional Fill Collection Types
        String additionalFillCollectionType;
        List<String> types = new List<String>();
        types.addAll(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES);
        additionalFillCollectionType = types[0];
        rsa = new Route_Schedule_Account__c(
                Route_Schedule__c = routeSchedule.Id,
                Account__c = account.Id,
                Collection_Type__c = additionalFillCollectionType
        );
        insert rsa;
        rsa = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds( new Set<Id> {rsa.Id})[0];
        System.assert(rsa.Redemption_Asset__c == rtAsset.Id);


        //  (3) 2 RT assets Regular Second.
        Asset rtAsset2 =   TestUtils.buildAsset('Sample RT Asset2', account.Id, AssetSvc.ASSET_RT_REDEMPTION);
        rtAsset2.GP_Manufacturer__c = 'M3T';
        rtAsset2.SAS__c = 'RT2';
        insert rtAsset2;
        rsa = new Route_Schedule_Account__c(
                Route_Schedule__c = routeSchedule.Id,
                Account__c = account.Id,
                Collection_Type__c = clFillSvc.REGULAR_2ND_RT_COLLECTION_TYPE,
                Redemption_Terminal__c = clRouteSvc.ASSET_SAS_RT_POSITION_2
        );
        insert rsa;
        rsa = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds( new Set<Id> {rsa.Id})[0];
        System.assert(rsa.Redemption_Asset__c == rtAsset2.Id);


        //  (4) 2 RT assets Additional Fill RT2
        delete rtAsset2;
        //delete rsa;
        Asset rtAsset3 =   TestUtils.buildAsset('Sample RT Asset2', account.Id, AssetSvc.ASSET_RT_REDEMPTION);
        rtAsset3.GP_Manufacturer__c = 'M3T';
        rtAsset3.SAS__c = 'RT2';
        insert rtAsset3;
        rsa = new Route_Schedule_Account__c(
                Route_Schedule__c = routeSchedule.Id,
                Account__c = account.Id,
                Collection_Type__c = additionalFillCollectionType,
                Redemption_Terminal__c = clRouteSvc.ASSET_SAS_RT_POSITION_2
        );
        insert rsa;
        rsa = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds( new Set<Id> {rsa.Id})[0];
        System.assert(rsa.Redemption_Asset__c == rtAsset3.Id);


        //  (5) 2 RT assets Additional Fill RT1 update
        rsa.Redemption_Terminal__c = clRouteSvc.ASSET_SAS_RT_POSITION_1;
        update rsa;
        rsa = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds( new Set<Id> {rsa.Id})[0];
        System.assert(rsa.Redemption_Asset__c == rtAsset.Id);


        Test.stopTest();
    }

}