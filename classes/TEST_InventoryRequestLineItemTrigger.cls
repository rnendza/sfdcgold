@IsTest
private class TEST_InventoryRequestLineItemTrigger {

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
            if(recordTypeInfo.getDeveloperName() != 'Master' && recordTypeInfo.active) {
                Inventory_Request__c inventoryRequest = new Inventory_Request__c();
                inventoryRequest.RecordTypeId = recordTypeInfo.getRecordTypeId();
                inventoryRequest.Name = 'UT IR Name for RT ' + recordTypeInfo.developerName;
                inventoryRequests.add(inventoryRequest);
            }
        }
        insert inventoryRequests;
    }

    @IsTest
    static void test_insertInventoryRequestLineItem_Positive() {
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
                    lineItems.add(lineItem);
                }
            }
            Test.startTest();

            insert lineItems;
            lineItems = [
              SELECT Id, Inventory_Request__c, Item_Number__c
              FROM   Inventory_Request_Line_Item__c
            ];

            Test.stopTest();
        }
    }
}