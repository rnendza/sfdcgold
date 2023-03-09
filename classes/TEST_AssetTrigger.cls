@IsTest
private class TEST_AssetTrigger {

    public static String UNAME = 'acceltest@accel.com';
    public static final Integer NUMBER_OF_PRODUCTS = 2;
    public static final Integer NUMBER_OF_IR_LINES = 5;
    public static final Integer NUMBER_OF_MUNIS = 2;
    public static final Integer NUMBER_OF_ACCTS_PER_MUNI = 2;

    @TestSetup
    static void setup() {

        List<Municipality__c> munis = TestUtils.createMunicipalities('UT MUNI', NUMBER_OF_MUNIS);
        List<Account> accounts = new List<Account>();
        List<Asset> assets = new List<Asset>();
        Integer z = 0;
        for (Municipality__c municipality : munis) {
            for (Integer i = 0; i < NUMBER_OF_ACCTS_PER_MUNI; i++) {
                Account account = TestUtils.buildAccount('accel test acct:' + z + 'a', municipality.Id,
                        'Accel Account');
                account.ShippingState = 'IL';
                accounts.add(account);
                z++;
            }
        }
        insert accounts;

        //create 'parent' account..
        Account parentInventoryAccount = TestUtils.buildAccount('Accel Entertainment - HQ', munis[0].Id,
                'Accel Account');
        insert parentInventoryAccount;

        String rtDevName = 'Software';
        for (Account account : accounts) {
            Asset asset = TestUtils.buildAsset('UT ' + account.Name + ' TEST ASSET', account.Id, rtDevName);
            assets.add(asset);
        }
        insert assets;

        List<Product2> products = new List<Product2>();
        Id softwareRtId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Gaming Software').getRecordTypeId();
        for (Integer i = 0; i < NUMBER_OF_PRODUCTS; i++) {
            //@TODO RecordType? Family of Software?
            Product2 p = new Product2(Name = 'UT Test Product ' + i + 1, Family = 'ASSET', Description = 'Test Desc',
                    RecordTypeId = softwareRtId);
            products.add(p);
        }
        insert products;

        Id irSoftwareRtId = Schema.SObjectType.Inventory_Request__c.getRecordTypeInfosByName().get('Gaming Software')
                .getRecordTypeId();
        Inventory_Request__c inventoryRequest = new Inventory_Request__c();
        inventoryRequest.Name = 'TEST IR Name';
        inventoryRequest.RecordTypeId = irSoftwareRtId;
        inventoryRequest.Account__c = accounts[0].Id;
        insert inventoryRequest;

        //--- @TODO this should bne moved to TESTutils but given the additional overhead on then the necessity
        //--- to run all test when moving test utils.. why bother no one else cares about them.
        Account vendor = TestUtils.buildAccount('THIS IS A VENDOR', null);
        vendor.Vendor_Type__c = 'Software';
        Id vendorRtId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vendors').getRecordTypeId();
        vendor.RecordTypeId = vendorRtId;
        insert vendor;

        List<Inventory_Request_Line_Item__c> inventoryRequestLineItems = new List<Inventory_Request_Line_Item__c>();
        for (Integer i = 0; i < NUMBER_OF_IR_LINES; i++) {
            for (Integer x = 0; x < NUMBER_OF_PRODUCTS; x++) {
                Inventory_Request_Line_Item__c inventoryRequestLineItem = new Inventory_Request_Line_Item__c();
                inventoryRequestLineItem.Product__c = products[x].Id;
                inventoryRequestLineItem.Quantity__c = 10;
                inventoryRequestLineItem.Received_Quantity__c = 10;
                inventoryRequestLineItem.Received_Date__c = Date.today();
                inventoryRequestLineItem.Inventory_Request__c = inventoryRequest.Id;
                inventoryRequestLineItem.Vendor__c = vendor.Id;
                inventoryRequestLineItems.add(inventoryRequestLineItem);
            }
        }
        insert inventoryRequestLineItems;

        Software_Assets_Config__c configPrefixSetting = Software_Assets_Config__c.getOrgDefaults();
        configPrefixSetting.Asset_Name_Prefix__c = 'SW-';
        configPrefixSetting.Latest_Serial_Number__c = 1;
        configPrefixSetting.Max_Single_Trans_Assets__c = 20;
        insert configPrefixSetting;
        configPrefixSetting = CustomSettingsSvc.getSoftwareAssetsConfigSettings(UserInfo.getUserId());
        System.assert(configPrefixSetting.Latest_Serial_Number__c != null);

        Software_Assets_Config__c configPrefixSetting2 = new Software_Assets_Config__c();
        configPrefixSetting2.Asset_Name_Prefix__c = 'SW-';
        configPrefixSetting2.Latest_Serial_Number__c = 1;
        configPrefixSetting2.Max_Single_Trans_Assets__c = 20;
        configPrefixSetting2.SetupOwnerId = UserInfo.getUserId();
        insert configPrefixSetting2;

    }

    @IsTest
    static void testNewAssetCreationAndHpdTotalCreation() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Id assetRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('VGT').getRecordTypeId();
            Asset a = new Asset(Name='asset trigger unit test asset',RecordTypeId=assetRtId);

            Test.startTest();
            insert a;
            Hold_Per_Day_Total__c holdPerDayTotal = [SELECT Id, Asset__c FROM Hold_Per_Day_Total__c WHERE Asset__c = :a.Id];
            System.assert(holdPerDayTotal != null);
            Asset asset = [SELECT Id, Hold_Per_Day_Total__c FROM Asset WHERE Hold_Per_Day_Total__c = :holdPerDayTotal.Id];
            System.assert(asset != null);
            Test.stopTest();
        }
    }

    @IsTest
    static void updateInventoryRequestLineOnDelete() {
        User u = TestUtils.getUserForTest(UNAME);
        //create assets...
        Id irId = [SELECT Id FROM Inventory_Request__c LIMIT 1].Id;
        List<Inventory_Request_Line_Item__c> irLineItemDbs   =  [
                SELECT  Id, Quantity__c,Inventory_Request__c,Product__c, Product__r.Name
                FROM    Inventory_Request_Line_Item__c
                WHERE   Inventory_Request__c = :irId
                AND     Item_Number__c = 1
        ];
        Inventory_Request_Line_Item__c irLineItemDb = irLineItemDbs[0];
        irLineItemDb.Quantity__c = 50;
        irLineItemDb.Received_Quantity__c = 50;
        irLineItemDb.Received_Date__c = Date.today();

        update irLineItemDb;
        List<String> irLineItemIds = new List<String>{irLineItemDb.Id};

        List<FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult> createAssetsResults =
                FlowAction_CreateAssetsFromIRLineItems.createAssetsFromInventoryRequestLineItem(irLineItemIds);
        FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult createAssetsResult = createAssetsResults[0];
        System.assertEquals(createAssetsResult.iNumAssetsCreated,irLineItemDb.Quantity__c);

        System.runAs(u) {

            Test.startTest();

            List<Asset> assets = [SELECT Id FROM Asset];
            delete assets;

            Test.stopTest();
        }
    }

    @IsTest
    static void testPopulateSerialNumber_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        Id softwareRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Software').getRecordTypeId();

        System.runAs(u) {


            Test.startTest();

            Asset ass = new Asset(Name = 'TEST SW MAN Inserted Asset', RecordTypeId = softwareRecordTypeId);
            insert ass;
            ass = [ SELECT Id, SerialNumber FROM Asset WHERE Id = :ass.Id ];
            System.assert(ass.SerialNumber != null);

            Test.stopTest();
        }
    }

    @IsTest
    static void testPopulateSerialNumber_VGT_Negative() {
        User u = TestUtils.getUserForTest(UNAME);
        Id vgtRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('VGT').getRecordTypeId();

        System.runAs(u) {

            Test.startTest();

            Asset ass = new Asset(Name = 'TEST VGT MAN Inserted Asset', RecordTypeId = vgtRecordTypeId);
            insert ass;
            ass = [ SELECT Id, SerialNumber FROM Asset WHERE Id = :ass.Id ];
            System.assert(ass.SerialNumber == null);

            Test.stopTest();
        }
    }

    @IsTest
    static void testPopulateSerialNumber_InventoryRequest_Negative() {
        User u = TestUtils.getUserForTest(UNAME);
        Id softwareRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Software').getRecordTypeId();

        System.runAs(u) {
            List<Inventory_Request_Line_Item__c> inventoryRequestLineItems = [SELECT Id FROM Inventory_Request_Line_Item__c];
            Id irLineItemId = inventoryRequestLineItems[0].Id;
            Test.startTest();

            Asset ass = new Asset(  Name = 'TEST VGT MAN IR Insert', Inventory_Request_Line_Item__c = irLineItemId,
                                    RecordTypeId = softwareRecordTypeId);
            insert ass;
            ass = [ SELECT Id, SerialNumber FROM Asset WHERE Id = :ass.Id ];
            System.assert(ass.SerialNumber == null); // generally will be done via create assets button.

            Test.stopTest();
        }
    }

    @IsTest
    static void testSwAssetParentAccountMod_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        Id softwareRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Software').getRecordTypeId();
        ID vgtRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('VGT').getRecordTypeId();

        List<Account> accounts = [SELECT Id FROM Account];

        // Create some VGT Parent assets.
        List<Asset> vgts = new List<Asset>();
        Integer x = 0;
        for(Account account : accounts) {
            Asset asset = new Asset();
            asset.recordtypeId = vgtRecordTypeId;
            asset.Name = 'vgt-'+account.Id;
            asset.AccountId = account.Id;
            asset.SAS__c = '1';
            asset.model__c = 'model'+x;
            x++;
            vgts.add(asset);
        }
        insert vgts;

        // build some sw assets;
        List<ASset> swAssets = new List<Asset>();
        Integer i = 0;
        for(Asset parentVgt : vgts) {
            Asset swAsset = TestUtils.buildAsset('test ' +i, parentVgt.AccountId, 'Software');
            swAsset.recordtypeId = softwareRecordTypeId;
            swAsset.parentId = parentVgt.Id;
            swAssets.add(swAsset);
            i++;
        }
        insert swAssets;

        Municipality__c municipality = [SELECT Id FROM  Municipality__c LIMIT 1];

        Account newAccount = TestUtils.buildAccount('accel test acct:', municipality.Id,
                'Accel Account');
        newAccount.ShippingState = 'IL';
        insert newAccount;

        Test.startTest();
        System.runAs(u) {
            for(Asset parentAsset: vgts) {
                parentASset.AccountId = newAccount.Id;
            }
            update vgts;
        }
        Test.stopTest();
        List<Asset> childAssets = [ SELECT Id,AccountId,ParentId,Parent.AccountId FROM Asset where ID in :swAssets];
        System.debug('---> childAssets:'+childAssets);
        for(Asset childAsset : childAssets) {
           // System.assert(childAsset.AccountId == newAccount.Id);
        }

    }

    @IsTest
    static void test_Asset_AccountMove_Cl_sameday_Positive() {

        User u = TestUtils.getUserForTest(UNAME);

        //  Create CL Specific Stuff all tied to Route / Route Schedule
        Map<String,Object> mBaseData         = clTESTUTILS.createAllNonClData();
        Map<String,Object> mClData           =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
        List<Meter_Reading__c> meterReadings = (List<Meter_Reading__c>)mClData.get(clTESTUTILS.SFDCMETERREADINGS);

        //  Create non CL Stuff so we have new accounts
        List<Municipality__c> munis = new List<Municipality__c>{clTESTUTILS.createMuni()};
        List<Account> newAccounts = clTESTUTILS.createAccounts(munis);
        Account newAccount = newAccounts[0];

        // Find all Assets associated with Meter_Reading__c sObjects.
        Set<Id> allMeterAssetIds = new Set<Id>();
        for(Meter_Reading__c mr : meterReadings) {
            allMeterAssetIds.add(mr.Asset__c);
        }
        Map<Id,Asset> mAssets =  new Map<Id,Asset>([
                SELECT Id,AccountId
                FROM   Asset
                WHERE  Id IN :allMeterAssetIds
        ]);


        System.runAs(u) {
            Test.startTest();

            // (1) Ensure That Meter_Reading__c.Asset_Moved_Date__c was set set via any other inserts / updated.
            Map<Id, Meter_Reading__c> mMeterReadings = new Map<Id, Meter_Reading__c>([
                    SELECT Id,Asset_Moved_Date__c
                    FROM Meter_Reading__c
                    WHERE Asset__c IN :mAssets.keySet()
            ]);
            for (Meter_Reading__c mr : mMeterReadings.values()) {
                System.assert(mr.Asset_Moved_Date__c == null);
            }

            // (2) Change the account id of assets associated with all meters and ensure Meter_Reading__c.Asset_Moved_Date__c was set.

            for (Asset asset : mAssets.values()) {
                asset.AccountId = newAccount.Id;
            }
            update mAssets.values();

            mMeterReadings = new Map<Id, Meter_Reading__c>([
                    SELECT Id,Asset_Moved_Date__c
                    FROM Meter_Reading__c
                    WHERE Asset__c IN :mAssets.keySet()
            ]);

            for (Meter_Reading__c mr : mMeterReadings.values()) {
                System.assert(mr.Asset_Moved_Date__c.date() == Date.today());
            }

            Test.stopTest();
        }
    }


    @IsTest
    static void test_Asset_AccountMove_Cl_prevdays_Positive() {

        User u = TestUtils.getUserForTest(UNAME);

        //  Create CL Specific Stuff all tied to Route / Route Schedule
        Map<String,Object> mBaseData         = clTESTUTILS.createAllNonClData();
        Map<String,Object> mClData           =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
        List<Meter_Reading__c> meterReadings = (List<Meter_Reading__c>)mClData.get(clTESTUTILS.SFDCMETERREADINGS);

        //  Create non CL Stuff so we have new accounts
        List<Municipality__c> munis = new List<Municipality__c>{clTESTUTILS.createMuni()};
        List<Account> newAccounts = clTESTUTILS.createAccounts(munis);
        Account newAccount = newAccounts[0];

        // Find all Assets associated with Meter_Reading__c sObjects.
        Set<Id> allMeterAssetIds = new Set<Id>();
        for(Meter_Reading__c mr : meterReadings) {
            Test.setCreatedDate(mr.Id,System.now().addDays(-2));
            allMeterAssetIds.add(mr.Asset__c);
        }
        Map<Id,Asset> mAssets =  new Map<Id,Asset>([
                SELECT Id,AccountId
                FROM   Asset
                WHERE  Id IN :allMeterAssetIds
        ]);


        Map<Id, Meter_Reading__c> mMeterReadings = new Map<Id, Meter_Reading__c>([
                SELECT Id,Asset_Moved_Date__c
                FROM Meter_Reading__c
                WHERE Asset__c IN :mAssets.keySet()
        ]);

        System.runAs(u) {
            Test.startTest();


            // (1) Change the account id of assets associated with all meters and ensure Meter_Reading__c.Asset_Moved_Date__c was NOT SET
            for (Asset asset : mAssets.values()) {
                asset.AccountId = newAccount.Id;
            }
            update mAssets.values();

            mMeterReadings = new Map<Id, Meter_Reading__c>([
                    SELECT Id,Asset_Moved_Date__c
                    FROM Meter_Reading__c
                    WHERE Asset__c IN :mAssets.keySet()
            ]);

            for (Meter_Reading__c mr : mMeterReadings.values()) {
                System.assert(mr.Asset_Moved_Date__c == null);
            }

            Test.stopTest();
        }
    }
}