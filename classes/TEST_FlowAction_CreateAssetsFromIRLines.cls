@isTest
private class TEST_FlowAction_CreateAssetsFromIRLines {

    public static String UNAME = 'acceltest@accel.com';
    public static final Integer NUMBER_OF_PRODUCTS = 2;
    public static final Integer NUMBER_OF_IR_LINES = 5;

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        List<Product2> products = new List<Product2>();
        Id productSoftwareRtId  = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Gaming Software').getRecordTypeId();

        for(Integer i=0 ; i <NUMBER_OF_PRODUCTS; i++) {
            //@TODO RecordType? Family of Software?
            Product2 p = new Product2(name = 'UT Test Product '+i+1, family = 'ASSET', Description = 'Test Desc', RecordTypeId = productSoftwareRtId);
            products.add(p);
        }
        insert products;

        Id irSoftwareRtId = Schema.SObjectType.Inventory_Request__c.getRecordTypeInfosByName().get('Gaming Software').getRecordTypeId();
        Inventory_Request__c inventoryRequest = new Inventory_Request__c();
        inventoryRequest.Name = 'TEST IR Name';
        inventoryRequest.RecordTypeId = irSoftwareRtId;
        insert inventoryRequest;

        Account vendor = TestUtils.buildAccount('THIS IS A VENDOR',null);
        Id vendorRtId =   Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Vendors').getRecordTypeId();
        vendor.Vendor_Type__c = 'Software';
        vendor.RecordTypeId =vendorRtId;
        insert vendor;


        List<Inventory_Request_Line_Item__c> inventoryRequestLineItems = new List<Inventory_Request_Line_Item__c>();
        for(Integer i=0; i<NUMBER_OF_IR_LINES; i++) {
            for(Integer x=0; x<NUMBER_OF_PRODUCTS; x++) {
                Inventory_Request_Line_Item__c inventoryRequestLineItem = new Inventory_Request_Line_Item__c();
                inventoryRequestLineItem.Product__c = products[x].Id;
                inventoryRequestLineItem.Quantity__c = 10;
                inventoryRequestLineItem.Received_Quantity__c = 10;
                inventoryRequestLineItem.Vendor__c = vendor.Id;
                inventoryRequestLineItem.Inventory_Request__c = inventoryRequest.Id;
                inventoryRequestLineItems.add(inventoryRequestLineItem);
            }
        }
        insert inventoryRequestLineItems;

    }
    /**
     * Tests a Quantity of 500;
     */
    @IsTest static void testCreateAssetsFromInventoryRequestLineItem_Positive() {
        User u = TestUtils.getUserForTest(UNAME);

        Software_Assets_Config__c setting = Software_Assets_Config__c.getOrgDefaults();
        setting.Name  = 'Software_Assets_Config__c. ' + UserInfo.getOrganizationId();
        setting.Latest_Serial_Number__c = 1;
        setting.Asset_Name_Prefix__c = 'SW -';
        upsert setting Software_Assets_Config__c.Id;

        System.runAs(u) {

            Test.startTest();
            Inventory_Request__c inventoryRequest = [SELECT Id,PO_Submitted_Date__c,PO_Number__c,Status__c FROM Inventory_Request__c LIMIT 1];
            inventoryRequest.Final_Approved_Indicator__c = true;
            inventoryRequest.IR_Approved_Date__c = Date.today();
            inventoryRequest.Submitted_Date__c = Date.today();
            inventoryRequest.Status__c = 'Approved for PO';
            update inventoryRequest;

            inventoryRequest.PO_Number__c = '23434';
            inventoryRequest.PO_Submitted_Date__c = Date.today();
            update inventoryRequest;
            Id irId = inventoryRequest.Id;

            List<Inventory_Request_Line_Item__c> irLineItemDbs   =  [
                    SELECT  Id, Quantity__c,Inventory_Request__c,Product__c, Product__r.Name
                    FROM    Inventory_Request_Line_Item__c
                    WHERE   Inventory_Request__c = :irId
                    AND     Item_Number__c = 1
            ];
            Inventory_Request_Line_Item__c irLineItemDb = irLineItemDbs[0];
            irLineItemDb.Quantity__c = 500;
            irLineItemDb.Received_Quantity__c = 500;
            irLineItemDb.Received_Date__c = Date.today();

            update irLineItemDb;
            List<String> irLineItemIds = new List<String>{irLineItemDb.Id};

            List<FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult> createAssetsResults =
                    FlowAction_CreateAssetsFromIRLineItems.createAssetsFromInventoryRequestLineItem(irLineItemIds);
            FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult createAssetsResult = createAssetsResults[0];
            System.assertEquals(createAssetsResult.iNumAssetsCreated,irLineItemDb.Quantity__c);

            Inventory_Request__c ir = [SELECT Id, Status__c from Inventory_Request__c WHERE Id = :inventoryRequest.Id];
            //@TODO what isn't status PO Fulfilled this point force it for now..
            ir.Status__c = 'PO Fulfilled';
            update ir;

            List<Asset> assetsInserted = [SELECT Id from Asset];

            FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult car =
                    FlowAction_CreateAssetsFromIRLineItems.checkIfWeShouldLockIr(assetsInserted,createAssetsResult,ir.Id);

            Test.stopTest();
        }
    }

    /**
     *
     */
    @IsTest static void testCreateAssetsFromInventoryRequestLineItem_Negative() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            LIST<sObject> sObjs = new LIST<sObject>();
            String settingName = 'Software_Assets_Config__c. ' + UserInfo.getProfileId();
            sObjs.add(new Software_Assets_Config__c(Name = settingName, SetupOwnerId = userInfo.getProfileId(),
                    Latest_Serial_Number__c = 1, Asset_Name_Prefix__c = 'SW - '));
            insert sObjs;

            Test.startTest();
            //------------------
            List<String> irLineItemIds = new List<String>{};
            List<FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult> createAssetsResults =
                    FlowAction_CreateAssetsFromIRLineItems.createAssetsFromInventoryRequestLineItem(irLineItemIds);
            FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult createAssetsResult = createAssetsResults[0];
            System.assert(createAssetsResult.errorMsg.contains('Invalid'));


            irLineItemIds = new List<String>{null};
            createAssetsResults =
                    FlowAction_CreateAssetsFromIRLineItems.createAssetsFromInventoryRequestLineItem(irLineItemIds);
            createAssetsResult = createAssetsResults[0];
            //System.assert(createAssetsResult.errorMsg.contains('Invalid'));

            Test.stopTest();
        }
    }

}