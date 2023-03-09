@IsTest
private class TEST_InventoryRequestTrigger {
    public static final String USERNAME_ADMIN             = 'acceltestadmin@accelentertainment.com';
    public static final Integer NUM_LINE_ITEMS            = 3;
    /**
     * Obviously.. initiate UT data.
     */
    @TestSetup
    static void setup() {
        List<Schema.RecordTypeInfo> recordTypeInfos =  Inventory_Request__c.SObjectType.getDescribe().getRecordTypeInfos();
        List<Inventory_Request__c> inventoryRequests = new List<Inventory_Request__c>();

        for(Schema.RecordTypeInfo recordTypeInfo : recordTypeInfos) {
            if(recordTypeInfo.getDeveloperName() != 'Master' && recordTypeInfo.active && recordTypeInfo.developerName == 'Gaming_Software') {
                System.debug('---------- RT Info ='+recordTypeInfo.getDeveloperName());
                Inventory_Request__c inventoryRequest = new Inventory_Request__c();
                inventoryRequest.RecordTypeId = recordTypeInfo.getRecordTypeId();
                inventoryRequest.Name = 'UT IR Name for RT ' + recordTypeInfo.developerName;
                Inventory_Request__c irClone = inventoryRequest.clone(false,true);
                inventoryRequests.add(inventoryRequest);
                inventoryRequests.add(irClone);
            }
        }
        insert inventoryRequests;
        System.debug(LoggingLevel.DEBUG,'----> Number of IR created:'+inventoryRequests.size());
    }

    @IsTest
    static void test_insertInventoryRequestUpdateIrStatus_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Map<Id,Inventory_Request__c> inventoryRequestMap = new Map<Id,Inventory_Request__c>( [
                    SELECT  Id, Number_of_Items__c
                    FROM    Inventory_Request__c
            ]);
            List<Inventory_Request_Line_Item__c> lineItems = new List<Inventory_Request_Line_Item__c>();
            for(Id irId : inventoryRequestMap.keySet()) {
                Inventory_Request__c inventoryRequest = inventoryRequestMap.get(irId);
                for(Integer i = 0; i< NUM_LINE_ITEMS; i++) {
                    Inventory_Request_Line_Item__c lineItem = new Inventory_Request_Line_Item__c();
                    lineItem.Inventory_Request__c = inventoryRequest.Id;
                    lineItem.Quantity__c = i + 1;
                    lineItem.Received_Quantity__c = lineItem.Quantity__c;
                    lineItem.Received_Date__c = Date.today();
                    lineItems.add(lineItem);
                }
            }
            insert lineItems;

            List<Inventory_Request__c> inventoryRequests = [SELECT Id,PO_Submitted_Date__c,PO_Number__c,Status__c FROM Inventory_Request__c];
            for(Inventory_Request__c inventoryRequest : inventoryRequests ) {
                inventoryRequest.Final_Approved_Indicator__c = true;
                inventoryRequest.IR_Approved_Date__c = Date.today();
                inventoryRequest.Submitted_Date__c = Date.today();
                inventoryRequest.Status__c = 'Approved for PO';
            }
            update inventoryRequests;

            for(Inventory_Request__c inventoryRequest : inventoryRequests) {
                inventoryRequest.PO_Number__c = '23434';
                inventoryRequest.PO_Submitted_Date__c = Date.today();
            }
            update inventoryRequests;

            List<String> irLineItemIds = new List<String>();
            List<Inventory_Request_Line_Item__c> inventoryRequestLineItems = [SELECT Id, Quantity__c, Received_Quantity__c, Number_of_Assets_Created__c FROM Inventory_Request_Line_Item__c];
            //@TODO Make proccess “Inventory Request Processor bulk safe!
            for(Inventory_Request_Line_Item__c inventoryRequestLineItem : inventoryRequestLineItems) {
                irLineItemIds.add(inventoryRequestLineItem.Id);
            }
            irLineItemIds.add(inventoryRequestLineItems[0].Id);

            Test.startTest();

            //create assets.
            List<FlowAction_CreateAssetsFromIRLineItems.CreateAssetsResult> createAssetsResults =
                    FlowAction_CreateAssetsFromIRLineItems.createAssetsFromInventoryRequestLineItem(irLineItemIds);

            for(Inventory_Request_Line_Item__c irLineItem : inventoryRequestLineItems) {
                irLineItem.Number_of_Assets_Created__c = 0;
                irLineItem.Quantity__c = 10;
                irLineItem.Received_Quantity__c = 1;
            }
            update inventoryRequestLineItems; //

            for(Inventory_Request_Line_Item__c irLineItem : inventoryRequestLineItems) {
                irLineItem.Number_of_Assets_Created__c = 1;
                irLineItem.Received_Quantity__c = 9;
            }
            update inventoryRequestLineItems; // force Rollup summary. fire.

            Test.stopTest();
        }
    }
}