@isTest
private class TEST_AssetController {

    public static String UNAME = 'acceltest@accel.com';
    public static final Integer NUMBER_OF_PRODUCTS = 2;
    public static final Integer NUMBER_OF_PO_LINES = 10;

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        List<Product2> products = new List<Product2>();
        for(Integer i=0 ; i <NUMBER_OF_PRODUCTS; i++) {
            Product2 p = new Product2(name = 'UT Test Product '+i+1, family = 'ASSET', Description = 'Test Desc');
            products.add(p);
        }
        insert products;

        Purchase_Order__c purchaseOrder = new Purchase_Order__c();
        purchaseOrder.Name = 'TEST Po Name';
        purchaseOrder.Product__c = products[0].id; //  backward compatibility.
        purchaseOrder.Quantity__c = 10;
        purchaseOrder.Price__c = 12;
        insert purchaseOrder;

        List<Purchase_Order_Item__c> purchaseOrderItems = new List<Purchase_Order_Item__c>();
        for(Integer i=0; i<NUMBER_OF_PO_LINES; i++) {
            for(Integer x=0; x<NUMBER_OF_PRODUCTS; x++) {
                Purchase_Order_Item__c poItem = new Purchase_Order_Item__c();
                poItem.Item__c = i + 1;
                poItem.Product__c = products[x].Id;
                poItem.Quantity__c = 10;
                poItem.Purchase_Order__c = purchaseOrder.Id;
                purchaseOrderItems.add(poItem);
            }
        }
        insert purchaseOrderItems;

        Software_Assets_Config__c configPrefixSetting = Software_Assets_Config__c.getOrgDefaults();
        configPrefixSetting.Asset_Name_Prefix__c = 'SW-';
        configPrefixSetting.Latest_Serial_Number__c = 1;
        configPrefixSetting.Max_Single_Trans_Assets__c = 20;
        upsert configPrefixSetting  Software_Assets_Config__c.Id;
    }
    /**
     * Test the simple retrieval of a po record upon load of the lightning component as well as the existing of custom
     * setting.
     */
    @isTest static void testRetrievePo() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Purchase_Order__c po  = [SELECT Id from Purchase_Order__c limit 1];
            ResponseDto dto = AssetController.retrievePo(po.id);
            system.assert(dto.isSuccess && dto.sObj.Id == po.Id);
            Software_Assets_Config__c config = (Software_Assets_Config__c)dto.values.get(AssetController.MAP_KEY_SW_ASSET_CONFIG_SETTING);
            system.assert(config != null);

            Test.stopTest();
        }
    }
    /**
     * Test the simple retrieval of a po item records upon load of the lightning component as well as the existing of custom
     * setting.
     */
    @isTest static void testRetrievePoItems_positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            Purchase_Order__c po  = [SELECT Id from Purchase_Order__c limit 1];

            ResponseDto dto = AssetController.retrievePoItems(po.Id);
            Software_Assets_Config__c config = (Software_Assets_Config__c)dto.values.get(AssetController.MAP_KEY_SW_ASSET_CONFIG_SETTING);
            system.assert(config != null);

            List<Purchase_Order_Item__c> poItems = (List<Purchase_Order_Item__c>)dto.values.get(AssetController.MAP_KEY_PO_ITEMS);
            System.assert(dto.isSuccess);
            //@TODO asserts.
            Test.stopTest();
        }
    }
    /**
     * Test the actual launch of the headless flow.  Ensure the proper number of assets were created
     * and the custom setting to increment the serial number counter was properly incremented.
     */
    @isTest static void testLaunchPoFlow() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Software_Assets_Config__c configPrefixSetting = Software_Assets_Config__c.getOrgDefaults();
            Decimal latestSerialNumPriorToRun = (Decimal)configPrefixSetting.Latest_Serial_Number__c;

            Test.startTest();

            Purchase_Order__c po  = [SELECT Id,Name,Name__c,Quantity__c,Price__c,Product_Description__c  from Purchase_Order__c limit 1];
            ResponseDto dto = AssetController.retrievePo(po.id);
            po = (Purchase_Order__c)dto.sObj;
            Map<String, Object> params = new Map<String, Object>();
            params.put('varInputRecordId',po.id);
            params.put('varInputPo',po);
            params.put('varInputQuantity',po.Quantity__c);
            List<Integer> arrQty = new List<Integer>();
            for (Integer i=0; i<=po.Quantity__c; i++) {
                arrQty.add(i);
            }
            params.put('varQuantityCollection',arrQty);

            Flow.Interview.Create_Software_Assets_From_PO flow = new Flow.Interview.Create_Software_Assets_From_PO(params);
            flow.start();
            List<Asset> assets = [SELECT Id From Asset where PO_Number__c = :po.id];
            system.assert(assets.size() == po.Quantity__c);
            Decimal qtyAssetsCreated = (Decimal)flow.getVariableValue('varQtyAssetsCreated');
            system.assert(qtyAssetsCreated == po.Quantity__c);

            configPrefixSetting = Software_Assets_Config__c.getOrgDefaults();
            Decimal latestSerialNumAfterRun = (Decimal)configPrefixSetting.Latest_Serial_Number__c;
            system.assert(latestSerialNumAfterRun == (latestSerialNumPriorToRun + qtyAssetsCreated));

            Test.stopTest();
        }
    }
}