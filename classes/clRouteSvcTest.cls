@IsTest
private class clRouteSvcTest {
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
    static void test_retrieveRouteProcessingSheet() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Date tomorrow = Date.today().addDays(1);
        Route__c route = [SELECT ID From Route__c LIMIT 1];
        Route_Schedule__c routeSchedule = [SELECT Id FROM Route_Schedule__c WHERE Route__c = :route.Id LIMIT 1];
        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Route_Schedule__c = :routeSchedule.Id LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Route_Processing_Sheet__c routeProcessingSheet = clRouteSvc.retrieveRouteProcessingSheet(rps.Id);
            System.assertEquals(rps.Id,routeProcessingSheet.Id);
        }

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveRoute() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c rte = [SELECT ID From Route__c LIMIT 1];

        Test.startTest();

        System.runAs(collector) {
            Route__c route = clRouteSvc.retrieveRoute(rte.Id);
            System.assertEquals(route.Id,rte.Id);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRoutes() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();

        System.runAs(collector) {
            List<Route__c> routes = clRouteSvc.retrieveRoutes(collector.Id);
            System.assertNotEquals(routes.isEmpty(),true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllRoutes() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();

        System.runAs(collector) {
            List<Route__c> routes = clRouteSvc.retrieveAllRoutes();
            System.assertNotEquals(routes.isEmpty(),true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllRoutesWithCollectionDates() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();

        System.runAs(collector) {
            List<Route__c> routes = clRouteSvc.retrieveAllRoutesWithRpsRecordsWithCollectionDates();
            System.assertNotEquals(routes.isEmpty(),true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllRouteRpsCollectionDates() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        //User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Route__c route = [SELECT Id FROM Route__c LIMIT 1];

        Test.startTest();

            Set<Date> collectionDates = clRouteSvc.retrieveAllRouteRpsCollectionDates(route.Id);
            System.assertNotEquals(collectionDates.isEmpty(),true);


        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsFillDataResults() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
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
        }
        update rpss;
        for(Route_Processing_Sheet__c rps : rpss) {
            System.debug('---> TEST RPS: '+rps);
        }

        Test.startTest();
        clRouteSvc.ProcessingFillSummary pfs = clRouteSvc.retrieveRpsFillDataResults(clTESTUTILS.DEFAULT_PROCESSING_LOC);
        Test.stopTest();
    }

    @IsTest
    static void test_tagRpsUtilizationDates() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        //User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id FROM Route_Processing_Sheet__c
        ]);
        Route_Processing_Sheet__c rps = mAllRps.values()[0];
        rps = clRouteSvc.retrieveRouteProcessingSheet(rps.Id);

        Test.startTest();

        //System.runAs(collector) {  @todo cross reference on entity error is this a real issue?

        rps = clRouteSvc.tagRpsUtilizationDates(rps,clRpsDateEnum.START_RT_REPLENISHMENT_DATE);
        System.assert(rps.Start_RT_Replenishment_Date__c.date() == Date.today());
        System.assert(rps.Start_RT_Replenishment_User__c == UserInfo.getUserId());

        rps = clRouteSvc.tagRpsUtilizationDates(rps,clRpsDateEnum.END_RT_REPLENISHMENT_DATE);
        System.assert(rps.End_RT_Replenishment_Date__c.date() == Date.today());
        System.assert(rps.End_RT_Replenishment_User__c == UserInfo.getUserId());

        rps = clRouteSvc.tagRpsUtilizationDates(rps,clRpsDateEnum.START_VGT_COLLECTION_DATE);
        System.assert(rps.Start_VGT_Collection_Date__c.date() == Date.today());
        System.assert(rps.Start_VGT_Collection_User__c == UserInfo.getUserId());

        rps = clRouteSvc.tagRpsUtilizationDates(rps,clRpsDateEnum.END_VGT_COLLECTION_DATE);
        System.assert(rps.End_VGT_Collection_Date__c.date() == Date.today());
        System.assert(rps.End_VGT_Collection_User__c == UserInfo.getUserId());

        Test.stopTest();
    }

    @IsTest
    private static void test_emailStuff() {

        Contact c = new Contact(LastName = 'dummy', Email='no-reply@accelentertainment.com');
        insert c;

        String testRegion = clTESTUTILS.DEFAULT_PROCESSING_LOC;

        Test.startTest();

        clRouteSvc.ProcessingFillSummary processingFillSummary = clRouteSvc.retrieveRpsFillDataResults(testRegion);
        List<clRouteSvc.EmailData> emailDatas = new clQueueableProcessFillSummaryEmail(testRegion).buildEmails(processingFillSummary,c.Id);
        List<Messaging.SendEmailResult> emailResults = clRouteSvc.sendEmailTemplates(emailDatas);

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
       // delete rsa;
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


        //  (5a) 2 RT assets Additional Fill RT1 update
        rsa.Redemption_Terminal__c = clRouteSvc.ASSET_SAS_RT_POSITION_1;
        update rsa;
        rsa = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds( new Set<Id> {rsa.Id})[0];
        System.assert(rsa.Redemption_Asset__c == rtAsset.Id);


        //  (6a) 2 RT assets Additional Fill RT1 update manual override
        rsa.Redemption_Terminal__c = clRouteSvc.ASSET_SAS_RT_POSITION_1;
        rsa.Redemption_Asset_Manual_Override__c = true;
        rsa.Redemption_Asset__c = rtAsset3.Id;
        update rsa;
        rsa = clRouteScheduleAccountSvc.retrieveRouteScheduleAccountsByIds( new Set<Id> {rsa.Id})[0];
        System.assert(rsa.Redemption_Asset__c == rtAsset3.Id);

        Test.stopTest();
    }
}