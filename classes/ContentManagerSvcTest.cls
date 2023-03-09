@IsTest
private class ContentManagerSvcTest {

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
        List<Route_Processing_Sheet__c> routeProcessingSheets = (List<Route_Processing_Sheet__c>) mClData.get(clTESTUTILS.SFDCRPS);
        Id singleRpsID = routeProcessingSheets[0].Id;
        List<Meter_Reading__c> meterReadings = (List<Meter_Reading__c>) mClData.get(clTESTUTILS.SFDCMETERREADINGS);
        List<Route_Import__c> routeImports = clTESTUTILS.createClRouteImportRecords();
        List<ContentVersion> contentVersions1 = clTESTUTILS.createRouteImportFiles(routeImports);
        System.assertEquals(contentVersions1.size(),routeImports.size());


        List<Meter_Reading__c> rpsMeterReadings = new List<Meter_Reading__c>();
        for(Meter_Reading__c meterReading : meterReadings) {
            if(meterReading.Route_Processing_Sheet__c == singleRpsID) {
                System.debug('meter reading name='+meterReading.Name);
                rpsMeterReadings.add(meterReading);
            }
        }

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        System.runAs(collector) {
            List<ContentVersion> contentVersions = clTESTUTILS.createFiles(rpsMeterReadings);
        }
    }

    @IsTest
    static void test_retrieveContentDocLinks() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT Id, Name
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rpsWrapper.rpsId
        ]);

        Test.startTest();
        System.runAs(collector) {
            Map<Id,ContentVersion> m = ContentManagerSvc.retrieveContentVersions(mMeterReadings.keySet(),'Meter_Reading__c');
            System.assert(!m.isEmpty());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_deleteDoc() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();
        System.runAs(collector) {
            List<ContentDocument> docs = [SELECT Id FROM ContentDocument LIMIT 1];
            ContentDocument deletedDoc = ContentManagerSvc.deleteDocument(docs[0].Id);
            System.assert(deletedDoc != null);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveContentVersions() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,ContentDocument> m = new Map<Id,ContentDocument>([ SELECT Id FROM ContentDocument LIMIT 10]);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT Id, Name
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rpsWrapper.rpsId
        ]);

        Test.startTest();
        System.runAs(collector) {
            Map<Id,ContentVersion> mVersions = ContentManagerSvc.retrieveContentVersions(mMeterReadings.keySet(),'Meter_Reading__c');
            System.assert(!mVersions.isEmpty());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveContentVersionNoVersionData() {

        ContentDocument doc = [SELECT Id FROM ContentDocument LIMIT 1];
        Test.startTest();

        ContentVersion cv  = ContentManagerSvc.retrieveContentVersionNoVersionData(doc.Id);

        System.assert(cv != null);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveContentVersionsByIds() {

        Map<Id,ContentVersion> mCvs = new Map<Id,ContentVersion>([SELECT Id FROM ContentVersion]);
        Test.startTest();

        mCvs  = ContentManagerSvc.retrieveContentVersionsByIds(mCvs.keySet());

        System.assert(!mCvs.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveContentDistributions() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,ContentDocument> m = new Map<Id,ContentDocument>([ SELECT Id FROM ContentDocument LIMIT 10]);
        //  Just get a single RPS
        ResponseDto dtoRps = clRouteProcessingSheetsController.retrieveRouteProcessingSheets(collector.Id,Date.today().addDays(1),0);
        List<clRouteProcessingSheetsController.RpsWrapper> rpss = (List<clRouteProcessingSheetsController.RpsWrapper>)
                dtoRps.values.get(clRouteProcessingSheetsController.MAP_KEY_RPS_DATA);
        clRouteProcessingSheetsController.RpsWrapper rpsWrapper = rpss[0];

        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT Id, Name
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rpsWrapper.rpsId
        ]);

        Map<Id,ContentVersion> mVersions = ContentManagerSvc.retrieveContentVersions(mMeterReadings.keySet(),'Meter_Reading__c');

        Test.startTest();
        System.runAs(collector) {
            Map<Id,ContentDistribution> mDistributions = ContentManagerSvc.retrieveContentDistributions(mVersions.keySet());
            System.assert(!mDistributions.isEmpty());
        }
        Test.stopTest();
    }

    @IsTest
    static void test_formatBytes() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        Test.startTest();

        System.runAs(collector) {
            System.assertEquals(ContentManagerSvc.formatBytes(0,null),'0 Bytes');
            System.assertEquals(ContentManagerSvc.formatBytes(2,null),'2.0 Bytes');
            System.assert(ContentManagerSvc.formatBytes(1025,2).contains('Kb'));
            System.assert(ContentManagerSvc.formatBytes(1024*1024 + 2,2).contains('Mb'));
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveContentVersionByTitle() {

        ContentVersion cv = new ContentVersion(    //  SDFC Black magic.. inserts contentDocument as well.
        Title = clTESTUTILS.DEFAULT_IMPORTER_HELP_FILE_TITLE,
        PathOnClient = clTESTUTILS.DEFAULT_IMPORTER_HELP_FILE_TITLE + '_test_help_file.jpg',
        Cash_Logistics_Upload_Type_fileupload__c = 'Accel File',
        Description = clTESTUTILS.DEFAULT_IMPORTER_HELP_FILE_TITLE + ' test importer help file ',
        VersionData = Blob.valueOf('help file shit'),
        IsMajorVersion = true
        );
        insert cv;

        Test.startTest();
        Map<Id,ContentVersion>  m = ContentManagerSvc.retrieveContentVersionsByTitle(clTESTUTILS.DEFAULT_IMPORTER_HELP_FILE_TITLE);
        System.assert(!m.isEmpty());

        Test.stopTest();
    }


}