@IsTest
private class clRelatedFilesTest {

    private static String MAP_KEY_ROUTE_IMPORT_DATA = 'ROUTE_IMPORT_DATAS';
    private static String MAP_KEY_DOCID             = 'DOC_ID';
    private static String MAP_KEY_ROUTE_IMPORT_ID   = 'ROUTE_IMPORT_ID';

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
        List<Route_Import__c> routeImports = clTESTUTILS.createClRouteImportRecords();
        List<ContentVersion> contentVersions = clTESTUTILS.createRouteImportFiles(routeImports);
        System.assertEquals(contentVersions.size(),routeImports.size());
    }

    @IsTest
    static void test_retrieveRelatedFiles_found() {

        Route_Import__c routeImport = [SELECT Id FROM Route_Import__c LIMIT 1];

        Test.startTest();

        ResponseDto dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        List<clRelatedFiles.FileWrapper> fileWrappers =
                (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);

        System.assert(dto.isSuccess);
        System.assert(!fileWrappers.isEmpty());

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRelatedFiles_not_found() {

        Route_Import__c routeImport = [SELECT Id FROM Route_Import__c LIMIT 1];
        ResponseDto dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        List<clRelatedFiles.FileWrapper> fileWrappers =
                (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);
        Set<Id> docIds = new Set<Id>();
        for(clRelatedFiles.FileWrapper fileWrapper : fileWrappers) {
            docIds.add(fileWrapper.contentDocumentId);
        }
        ContentManagerSvc.deleteDocuments(docIds);

        Test.startTest();

        dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        fileWrappers = (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);

        System.assert(fileWrappers.isEmpty());
        System.assert(!dto.isSuccess);

        Test.stopTest();
    }



    @IsTest
    static void test_retrieveRouteImport() {

        Route_Import__c routeImport = [SELECT Id FROM Route_Import__c LIMIT 1];

        Test.startTest();

        // success
        ResponseDto dto = clRelatedFiles.retrieveRouteImport(routeImport.Id);
        System.assert(dto.isSuccess);
        // fail
        Id deletedRouteImportId = routeImport.Id;
        delete routeImport;
        dto = clRelatedFiles.retrieveRouteImport(deletedRouteImportId);
        System.assert(!dto.isSuccess);


        Test.stopTest();
    }


    @IsTest
    static void test_retrieveImporterHelpContentVersion() {

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

        ResponseDto dto = clRelatedFiles.retrieveImporterHelpContentVersion(clTESTUTILS.DEFAULT_IMPORTER_HELP_FILE_TITLE);
        System.assert(dto.isSuccess);

        Test.stopTest();
    }

    @IsTest
    static void test_deleteRelatedFile() {

        Route_Import__c routeImport = [SELECT Id FROM Route_Import__c LIMIT 1];
        ResponseDto dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        List<clRelatedFiles.FileWrapper> fileWrappers =
                (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);

        Id docId = fileWrappers[0].contentDocumentId;

        Test.startTest();

        ResponseDto deleteDto = clRelatedFiles.deleteRelatedFile(docId);
        System.assert(deleteDto.isSuccess);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveContentVersion() {

        Route_Import__c routeImport = [SELECT Id FROM Route_Import__c LIMIT 1];
        ResponseDto dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        List<clRelatedFiles.FileWrapper> fileWrappers =
                (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);

        Id docId = fileWrappers[0].contentDocumentId;

        Test.startTest();

        ResponseDto cvDto = clRelatedFiles.retrieveContentVersion(docId);
        System.assert(cvDto.isSuccess);

        Test.stopTest();
    }

    @IsTest
    static void test_buildRouteAccountSuccessCsv() {
        Route_Import__c routeImport = [SELECT Id FROM Route_Import__c LIMIT 1];
        ResponseDto dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        List<clRelatedFiles.FileWrapper> fileWrappers =
                (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);

        fileWrappers.sort();

        Id docId = fileWrappers[0].contentDocumentId;

        List<Route_Account__c> routeAccounts = [
                SELECT Id,Name,Route__c,X1_Fill_Level__c,X50_Fill_Level__c,X20_Fill_Level__c,X100_Fill_Level__c,
                        X5_Fill_Level__c,Route__r.Name,CreatedDate,CreatedById,CreatedBy.Username,
                        Account__r.NAme,Collection_Type__c,Replenishment_Type__c,Stop_Number__c
                FROM Route_Account__c
                WHERE Id = :routeImport.Id
        ];

        Test.startTest();
        clRelatedFiles.FileWrapper fileWrapper =
                clRelatedFiles.buildRouteAccountSuccessCsv(docId, routeImport.Id, routeAccounts);
        // @todo asserts

        Test.stopTest();
    }

    /**
     * @todo why does not SFDC Cover this normally?
     */
    @IsTest
    static void test_buildRouteImportRecordsCompareTo() {
        Route_Import__c routeImport = [SELECT Id FROM Route_Import__c LIMIT 1];
        ResponseDto dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        List<clRelatedFiles.FileWrapper> fileWrappers =
                (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);

       // fileWrappers.sort();E

        Test.startTest();

        clRelatedFiles.FileWrapper fileWrapper1 = new clRelatedFiles.FileWrapper();
        clRelatedFiles.FileWrapper fileWrapper2 = new clRelatedFiles.FileWrapper();
        fileWrapper1.lastModifiedDate = System.now();
        fileWrapper2.lastModifiedDate = fileWrapper1.lastModifiedDate;
        Integer i1 = fileWrapper1.compareTo(fileWrapper2);

        fileWrapper2.lastModifiedDate = System.now().addDays(1);
        Integer i2 = fileWrapper2.compareTo(fileWrapper1);


        Test.stopTest();
    }

    @IsTest
    static void test_retrievePermissions() {
        List<clRelatedFiles.Permission> perms = new List<clRelatedFiles.Permission>();

        // these won't be found so they are not enabled.
        clRelatedFiles.Permission perm = new clRelatedFiles.Permission();
        perm.action = 'testaction';
        perm.name = 'testname';
        perms.add(perm);


        Test.startTest();
        ResponseDto dto = clRelatedFiles.retrievePermissions(perms);
        perms = (List<clRelatedFiles.Permission>)dto.values.get(clRelatedFiles.MAP_KEY_PERMISSIONS);
        for(clRelatedFiles.Permission perm1 : perms) {
            System.assert(!perm1.enabled);
        }
        Test.stopTest();
    }

    @IsTest
    static void test_doModifyRoutes_success() {

        Map<String,Object> mTestData = buildModifyRouteTestData();
        Id docId = (Id)mTestData.get(MAP_KEY_DOCID);
        Id routeImportId = (Id)mTestData.get(MAP_KEY_ROUTE_IMPORT_ID);
        List<clRelatedFiles.RouteImportData> routeImportDatas = (List<clRelatedFiles.RouteImportData>)mTestData.get(MAP_KEY_ROUTE_IMPORT_DATA);

        System.debug('---> number of routeImporData rows = '+routeImportDatas.size());

        Test.startTest();
        //  success
        ResponseDto importDto = clRelatedFiles.doModifyRoutes(routeImportDatas,docId,routeImportId);
        System.assert(importDto.isSuccess);
        System.assert(importDto.message.contains(clRelatedFiles.IMPORT_SUCCESS_MSG));

        Test.stopTest();
    }

    @IsTest
    static void test_doModifyRoutes_failed_bad_docid() {

        Map<String,Object> mTestData = buildModifyRouteTestData();
        Id docId = (Id)mTestData.get(MAP_KEY_DOCID);
        Id routeImportId = (Id)mTestData.get(MAP_KEY_ROUTE_IMPORT_ID);
        List<clRelatedFiles.RouteImportData> routeImportDatas = (List<clRelatedFiles.RouteImportData>)mTestData.get(MAP_KEY_ROUTE_IMPORT_DATA);
        System.debug('---> number of routeImporData rows = '+routeImportDatas.size());

        Test.startTest();

        //  force exception with bad docId
        docId = [SELECT Id FROM Account LIMIT 1].Id;
        ResponseDto importDto = clRelatedFiles.doModifyRoutes(routeImportDatas,docId,routeImportId);
        System.assert(!importDto.isSuccess);
        System.assert(importDto.message.contains(clRelatedFiles.IMPORT_FAILED_MSG));

        Test.stopTest();
    }

    @IsTest
    static void test_doModifyRoutes_failed_bad_routeimportid() {

        Map<String,Object> mTestData = buildModifyRouteTestData();
        Id docId = (Id)mTestData.get(MAP_KEY_DOCID);
        Id routeImportId = (Id)mTestData.get(MAP_KEY_ROUTE_IMPORT_ID);
        List<clRelatedFiles.RouteImportData> routeImportDatas = (List<clRelatedFiles.RouteImportData>)mTestData.get(MAP_KEY_ROUTE_IMPORT_DATA);
        System.debug('---> number of routeImporData rows = '+routeImportDatas.size());

        Test.startTest();

        //  bad Route_Import__c.Id
        routeImportId = null;

        ResponseDto importDto = clRelatedFiles.doModifyRoutes(routeImportDatas,docId,routeImportId);
        System.assert(!importDto.isSuccess);
        System.assert(importDto.message.contains(clRelatedFiles.IMPORT_FAILED_MSG));

        Test.stopTest();
    }
    @IsTest
    static void test_doModifyRoutes_failed_null_stopnumber() {

        Map<String,Object> mTestData = buildModifyRouteTestData();
        Id docId = (Id)mTestData.get(MAP_KEY_DOCID);
        Id routeImportId = (Id)mTestData.get(MAP_KEY_ROUTE_IMPORT_ID);
        List<clRelatedFiles.RouteImportData> routeImportDatas = (List<clRelatedFiles.RouteImportData>)mTestData.get(MAP_KEY_ROUTE_IMPORT_DATA);
        System.debug('---> number of routeImporData rows = '+routeImportDatas.size());

        for(clRelatedFiles.RouteImportData rid : routeImportDatas) {
            rid.stopNumber = null; // null stop number
        }

        Test.startTest();

        ResponseDto importDto = clRelatedFiles.doModifyRoutes(routeImportDatas,docId,routeImportId);
        System.assert(importDto.isSuccess); // bus use case says still allow as it will be zero. client should have validated

        Test.stopTest();
    }

    @IsTest
    static  void test_plOption_Equivalency_Check() {
        clRelatedFiles.PlOption plOption1 = new clRelatedFiles.PlOption('value1','label1',false);
        clRelatedFiles.PlOption plOption2 = new clRelatedFiles.PlOption('value2','label2',false);

        Test.startTest();
        System.assertNotEquals(plOption1,plOption2);
        Test.stopTest();
    }

    static Map<String,Object> buildModifyRouteTestData() {
        Map<String,Object> mResults = new Map<String,Object>();

        Route_Import__c routeImport = [SELECT Id,Name FROM Route_Import__c LIMIT 1];
        Route__c route = [SELECT Id,Name FROM Route__c LIMIT 1];
        ResponseDto dto = clRelatedFiles.retrieveRelatedFiles(routeImport.id,'Route Import');
        List<clRelatedFiles.FileWrapper> fileWrappers =
                (List<clRelatedFiles.FileWrapper>)dto.values.get(clRelatedFiles.MAP_KEY_RELATED_FILES);
        clRelatedFiles.FileWrapper fileWrapper = fileWrappers[0];

        Id routeImportId = routeImport.Id;
        mResults.put(MAP_KEY_ROUTE_IMPORT_ID,routeImportId);

        Id docId = fileWrapper.contentDocumentId;
        mResults.put(MAP_KEY_DOCID,docId);

        String routeName = route.Name;

        List<Account> accounts = [
                SELECT Id,Name
                FROM   Account
                LIMIT 5
        ];
        List<clRelatedFiles.RouteImportData> routeImportDatas = new List<clRelatedFiles.RouteImportData>();
        Integer i = 0;
        for (Account account : accounts) {
            clRelatedFiles.RouteImportData routeImportData = new clRelatedFiles.RouteImportData();
            routeImportData.accountId = account.Id;
            routeImportData.collectionType = clQueueablePreviousRps.COLLECTION_TYPES_VGT.iterator().next();
            routeImportData.routeName = routeName;
            routeImportData.rowNumber = i + 1;
            routeImportData.stopNumber = i + 1;
            routeImportData.x1FillLevel = 1;
            routeImportData.x5FillLevel = 5;
            routeImportData.x20FillLevel = 20;
            routeImportData.x50FillLevel = 50;
            routeImportData.x100FillLevel = 100;
            routeImportData.replenishmentType = 'Full Audit';
            routeImportData.valid = true;
            routeImportDatas.add(routeImportData);
            i++;
        }
        mResults.put(MAP_KEY_ROUTE_IMPORT_DATA,routeImportDatas);

        return mResults;
    }

}