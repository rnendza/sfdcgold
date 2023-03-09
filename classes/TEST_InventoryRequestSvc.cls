@isTest
private class TEST_InventoryRequestSvc {

    public static String UNAME = 'acceltest@accel.com';
    public static final Integer NUMBER_OF_PRODUCTS = 2;
    public static final Integer NUMBER_OF_IR_LINES = 5;

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        List<Product2> products = new List<Product2>();
        Id softwareRtId  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Gaming Software').getRecordTypeId();
        for(Integer i=0 ; i <NUMBER_OF_PRODUCTS; i++) {
            //@TODO RecordType? Family of Software?
            Product2 p = new Product2(name = 'UT Test Product '+i+1, family = 'ASSET', Description = 'Test Desc', RecordTypeId = softwareRtId);
            products.add(p);
        }
        insert products;

        Id irSoftwareRtId = Schema.SObjectType.Inventory_Request__c.getRecordTypeInfosByName().get('Gaming Software').getRecordTypeId();
        Inventory_Request__c inventoryRequest = new Inventory_Request__c();
        inventoryRequest.Name = 'TEST IR Name';
        inventoryRequest.RecordTypeId = irSoftwareRtId;
        insert inventoryRequest;

        List<Inventory_Request_Line_Item__c> inventoryRequestLineItems = new List<Inventory_Request_Line_Item__c>();
        for(Integer i=0; i<NUMBER_OF_IR_LINES; i++) {
            for(Integer x=0; x<NUMBER_OF_PRODUCTS; x++) {
                Inventory_Request_Line_Item__c inventoryRequestLineItem = new Inventory_Request_Line_Item__c();
                inventoryRequestLineItem.Product__c = products[x].Id;
                inventoryRequestLineItem.Quantity__c = 10;
                inventoryRequestLineItem.Received_Quantity__c = 10;
                inventoryRequestLineItem.Inventory_Request__c = inventoryRequest.Id;
                inventoryRequestLineItems.add(inventoryRequestLineItem);
            }
        }
        insert inventoryRequestLineItems;

        Software_Assets_Config__c configPrefixSetting = Software_Assets_Config__c.getOrgDefaults();
        configPrefixSetting.Asset_Name_Prefix__c = 'SW-';
        configPrefixSetting.Latest_Serial_Number__c = 1;
        configPrefixSetting.Max_Single_Trans_Assets__c = 20;
        upsert configPrefixSetting  configPrefixSetting.Id;
    }


    /**
     * Tests the raw insert of assets created from an IR Line Item.
     *
     * (1) Make sure the number of assets created equals IR Line Item.Qty_Of_Assets_To_Create__c.
     * (2) Test that the created Asset.Item_Content__c field matches the selected product2.Description value.
     */
    @IsTest
    static void testInsertAssetsFromIrLine() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Inventory_Request_Line_Item__c irLineItem = [SELECT Id FROM Inventory_Request_Line_Item__c LIMIT 1];
            irLineItem = InventoryRequestSvc.retrieveInventoryRequestLineItem(irLineItem.Id);
            String assetRtName = 'Software';
            List<Asset> assets = InventoryRequestSvc.insertAssetsFromIrLineItem(irLineItem,assetRtName);
            //  -(1)- Test the the number of assets created = The number that the user chose to create on the IR Line.
            System.assertEquals(irLineItem.Qty_of_assets_to_create__c,assets.size());
            for(Asset asset : assets) {
                //  -(2)- TEST That asset.Item_Content__c field Equals the description from the product added to the IR Line.
                System.assertEquals(asset.Item_Content__c, irLineItem.Product__r.Description);
            }

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest static void testRetrieveInventoryRequestAndLineItems() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Inventory_Request__c irDb   = [SELECT Id, (SELECT Id FROM Inventory_Request_Line_Items__r) FROM Inventory_Request__c LIMIT 1];
            Inventory_Request__c inventoryRequest = InventoryRequestSvc.retrieveInventoryRequestAndLineItems(irDb.Id);
            System.assertEquals(inventoryRequest.Id, irDb.Id);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest static void testRetrieveProgressStatusIndicators() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Schema.DescribeFieldResult fieldResult = Inventory_Request__c.Status__c.getDescribe();
            List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
            Set<String> statusApiValues = new Set<String>();
            for( Schema.PicklistEntry v : values) {
                if(v.active) {
                    statusApiValues.add(v.getValue());
                }
            }

            Test.startTest();
            // --(1) Test that all metadata value__c fields (api name have a match to the picklist value of the status on the IR
            List<Inventory_Request_Progress_Indicators__mdt> metadatas =
                    InventoryRequestSvc.retrieveInventoryRequestProgressSettingsMeta(null);

            for(Inventory_Request_Progress_Indicators__mdt metadata : metadatas) {
                statusApiValues.contains(metadata.value__c);
            }

            Test.stopTest();
        }
    }

    /**
     *
     */
    @IsTest static void testLockInventoryRequests() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {


            Inventory_Request__c ir = [SELECT Id, Status__c FROM  Inventory_Request__c LIMIT 1];
            ir.Status__c = 'PO Fulfilled';
            update ir;

            Test.startTest();

            List<DataBase.Error> errors = InventoryRequestSvc.lockInventoryRequest(ir.Id);
            System.assert(errors.isEmpty());
            System.assert(InventoryRequestSvc.checkIfIrIsLocked(ir.Id));

            Test.stopTest();
        }
    }
}