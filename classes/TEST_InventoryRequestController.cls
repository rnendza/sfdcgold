@IsTest
private class TEST_InventoryRequestController {

    public static String UNAME = 'acceltest@accel.com';
    public static final Integer NUMBER_OF_PRODUCTS = 2;
    public static final Integer NUMBER_OF_IR_LINES = 5;
    public static final Integer NUMBER_OF_MUNIS = 2;
    public static final Integer NUMBER_OF_ACCTS_PER_MUNI = 2;

    /**
     * Setup Munis,Accounts,Products,Assets,IR, and IR Lines.
     */
    @TestSetup static void setup() {

        List<Municipality__c> munis = TestUtils.createMunicipalities('UT MUNI', NUMBER_OF_MUNIS);
        List<Account> accounts = new List<Account>();
        List<Asset> assets = new List<Asset>();
        Integer z = 0;
        for (Municipality__c municipality : munis) {
            for (Integer i = 0; i < NUMBER_OF_ACCTS_PER_MUNI; i++) {
                Account account = TestUtils.buildAccount('accel test acct:' + z + 'a', municipality.id,
                        'Accel Account');
                account.ShippingState = 'IL';
                accounts.add(account);
                z++;
            }
        }
        insert accounts;

        String rtDevName = 'Software';
        for (Account account : accounts) {
            Asset asset = TestUtils.buildAsset('UT ' + account.Name + ' TEST ASSET', account.Id, rtDevName);
            assets.add(asset);
        }
        insert assets;

        List<Product2> products = new List<Product2>();
        Id softwareRtId  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Gaming Software').getRecordTypeId();
        for (Integer i = 0; i < NUMBER_OF_PRODUCTS; i++) {
            //@TODO RecordType? Family of Software?
            Product2 p = new Product2(name = 'UT Test Product ' + i + 1, family = 'ASSET', Description = 'Test Desc',
                    RecordTypeId = softwareRtId);
            products.add(p);
        }
        insert products;

        Id irSoftwareRtId = Schema.SObjectType.Inventory_Request__c.getRecordTypeInfosByName().get('Gaming Software')
                .getRecordTypeId();
        Inventory_Request__c inventoryRequest = new Inventory_Request__c();
        inventoryRequest.Name = 'TEST IR Name';
        inventoryRequest.RecordTypeId = irSoftwareRtId;
        inventoryRequest.Account__c = accounts[0].id;
        insert inventoryRequest;

        Account vendor = TestUtils.buildAccount('THIS IS A VENDOR',null);
        vendor.Vendor_Type__c = 'Software';
        Id vendorRtId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vendors').getRecordTypeId();
        vendor.RecordTypeId =vendorRtId;
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
        upsert configPrefixSetting Software_Assets_Config__c.Id;

    }
    /**
     *
     */
    @IsTest static void testRetrieveInventoryRequestLine() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Inventory_Request__c irDb = [SELECT Id, (SELECT Id FROM Inventory_Request_Line_Items__r) FROM Inventory_Request__c LIMIT 1];
            Inventory_Request_Line_Item__c irDbLi = irDb.Inventory_Request_Line_Items__r[0];

            ResponseDto dto = InventoryRequestController.retrieveInventoryRequestLineItem(irDbLi.Id);
            Inventory_Request_Line_Item__c irLineTest = (Inventory_Request_Line_Item__c) dto.sObj;

            System.assert(dto.isSuccess && irLineTest.Id == irDbLi.Id);

            Software_Assets_Config__c config = (Software_Assets_Config__c) dto.values.get(AssetController.MAP_KEY_SW_ASSET_CONFIG_SETTING);
            System.assert(config != null);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest static void testHitCreateAssetsButton_positive() {
        Inventory_Request_Line_Item__c irLineItemDb = [SELECT Id FROM Inventory_Request_Line_Item__c LIMIT 1];
        List<String> irLineItemIds = new List<String>{irLineItemDb.Id};

        List<FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult> createAssetsResults =
                FlowAction_CreateAssetsFromIRLineItems.createAssetsFromInventoryRequestLineItem(irLineItemIds);
        FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult createAssetsResult = createAssetsResults[0];
        System.assert(createAssetsResult.success);
        System.assert(InventoryRequestController.doesIrLineItemHaveAssets(irLineItemDb.Id));

    }

    /**
     * @TODO Deprecate.
     */
    @IsTest static void testRetrieveInventoryRequestAndLineItems() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Inventory_Request__c irDb = [SELECT Id, (SELECT Id FROM Inventory_Request_Line_Items__r) FROM Inventory_Request__c LIMIT 1];
            ResponseDto dto = InventoryRequestController.retrieveInventoryRequestAndLineItems(irDb.Id);

            Inventory_Request__c irTest = (Inventory_Request__c) dto.sObj;
            List<Inventory_Request_Line_Item__c> irLineItemsTest =
                    (List<Inventory_Request_Line_Item__c>) dto.values.get(InventoryRequestController.MAP_KEY_IR_LINES);

            System.assert(dto.isSuccess && irTest.Id == irDb.Id);
            System.assert(!irTest.Inventory_Request_Line_Items__r.isEmpty());
            System.assertEquals(irTest.Inventory_Request_Line_Items__r.size(), NUMBER_OF_IR_LINES * NUMBER_OF_PRODUCTS);
            System.assertEquals(irLineItemsTest.size(), NUMBER_OF_IR_LINES * NUMBER_OF_PRODUCTS);

            Software_Assets_Config__c config = (Software_Assets_Config__c) dto.values.get(AssetController.MAP_KEY_SW_ASSET_CONFIG_SETTING);
            System.assert(config != null);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void testRetrieveUserProfile() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            u = [SELECT Id, ProfileId FROM User WHERE Id = :u.Id];
            Test.startTest();

            Profile profile = InventoryRequestController.retrieveUserProfile();
            System.assertEquals(profile.Id, u.ProfileId, 'Profile Ids do not match');

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void testDoesUserHavePermisson_negative() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            u = [SELECT Id, ProfileId FROM User WHERE Id = :u.Id];
            Test.startTest();

            Boolean hasIt = InventoryRequestController.doesUserHavePermission('blah_bogus');
            System.assert(hasIt == false);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void testDeleteIrLineItemAssets_negative() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Inventory_Request__c irDb = [SELECT Id, (SELECT Id FROM Inventory_Request_Line_Items__r) FROM Inventory_Request__c LIMIT 1];
            Inventory_Request_Line_Item__c irLineItemDb = irDb.Inventory_Request_Line_Items__r[0];
            ResponseDto dto = InventoryRequestController.deleteIrLineItemAssets(irLineItemDb.Id);
            System.assert(!dto.isSuccess);
            System.assert(dto.technicalMsg.contains('No Assets'));

            Test.stopTest();
        }
    }
    /**
 *
 */
    @IsTest
    static void testDeleteIrLineItemAssets_negative1() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Inventory_Request__c irDb   = [SELECT Id, (SELECT Id FROM Inventory_Request_Line_Items__r) FROM Inventory_Request__c LIMIT 1];
            Inventory_Request_Line_Item__c irLineItemDb = irDb.Inventory_Request_Line_Items__r[0];
            ResponseDto dto = InventoryRequestController.deleteIrLineItemAssets(irLineItemDb.Id);
            System.assert(!dto.isSuccess);
            System.assert(dto.technicalMsg.contains('No Assets'));

            Test.stopTest();
        }
    }

    /**
 *
 */
    @IsTest
    static void testRetrieveRecordTypeViaId() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            u = [SELECT Id, ProfileId FROM User WHERE Id = :u.Id];
            Test.startTest();

            Id irSoftwareRtId = Schema.SObjectType.Inventory_Request__c.getRecordTypeInfosByName().get('Gaming Software')
                    .getRecordTypeId();
            ResponseDto dto  = InventoryRequestController.retrieveRecordTypeViaId(irSoftwareRtId);

            Test.stopTest();
        }
    }
    @IsTest
    static void testRetrieveRecordTypeViaId_negative() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            u = [SELECT Id, ProfileId FROM User WHERE Id = :u.Id];
            Test.startTest();

            Id accountId = [SELECT Id From Account LIMIT 1 ].Id;
            ResponseDto dto  = InventoryRequestController.retrieveRecordTypeViaId(accountId);
            System.assert(dto.technicalMsg.contains('No RT'));

            Test.stopTest();
        }
    }

    @IsTest
    static void testMakeIRLineEligibleToCreateAssets() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();

            Inventory_Request_Line_Item__c irLine = [SELECT Id from Inventory_Request_Line_Item__c LIMIT 1];
            ResponseDto dto = InventoryRequestController.makeIrLineEligibleToCreateAssets(irLine.Id);
            System.assert(dto.isSuccess);

            Test.stopTest();
        }
    }

    @IsTest
    static void testMakeIRLineInEligibleToCreateAssets() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();

            Inventory_Request_Line_Item__c irLine = [SELECT Id from Inventory_Request_Line_Item__c LIMIT 1];
            ResponseDto dto = InventoryRequestController.makeIrLineInEligibleToCreateAssets(irLine.Id);
            System.debug('---------------> dto='+dto);
            System.assert(dto.isSuccess);

            Test.stopTest();
        }
    }

    @IsTest
    static void testRetrieveAccountsForIrSelection() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Id warehouseId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Warehouse').getRecordTypeId();

            Account a = new Account();
            a.Name = 'TEST Warehouse Account';
            a.RecordTypeId = warehouseId;
            insert a;

            Test.startTest();

            String whereCriteria = '';

            //--- Good test
            whereCriteria = 'RecordType.Developername = \'Warehouse\'';
            ResponseDto dto = InventoryRequestController.retrieveAccountsForIrSelection(whereCriteria);
            System.assert(dto.isSuccess);

            //--- Bad criteria ie exception caught.
            whereCriteria = 'Warehouse';
            dto = InventoryRequestController.retrieveAccountsForIrSelection(whereCriteria);
            System.assert(!dto.isSuccess);


            //--- Bad criteria no record found
            whereCriteria = 'RecordType.Developername = \'Bogus\'';
            dto = InventoryRequestController.retrieveAccountsForIrSelection(whereCriteria);
            System.assert(!dto.isSuccess);


            Test.stopTest();
        }
    }

    @IsTest
    static void testRetrieveParentAssetForIrSelection() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Asset asset = new Asset();
            asset.Name = 'TEST PARENT ASSET';
            asset.Software_Type__c = 'Parent Asset';
            insert asset;

            Test.startTest();

            String whereCriteria = '';

            //--- Good test
            whereCriteria = 'Software_Type__c = \'Parent Asset\'';
            ResponseDto dto = InventoryRequestController.retrieveParentAssetsForIrSelection(whereCriteria);
            System.assert(dto.isSuccess);

            //--- Bad criteria ie exception caught.
            whereCriteria = 'Parent Asset';
            dto = InventoryRequestController.retrieveParentAssetsForIrSelection(whereCriteria);


            //--- Bad criteria no record found
            whereCriteria = 'Software_Type__c = \'Bogus\'';
            dto = InventoryRequestController.retrieveParentAssetsForIrSelection(whereCriteria);



            Test.stopTest();
        }
    }
    /**
 *
 */
    @IsTest static void testRetrieveIfProgressIndicators() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();

            Inventory_Request_Line_Item__c irLineItem = [SELECT Id from Inventory_Request_Line_Item__c LIMIT 1];
            InventoryRequestController.retrieveIrProgressIndicators(irLineItem.Id);

            Test.stopTest();
        }
    }
}