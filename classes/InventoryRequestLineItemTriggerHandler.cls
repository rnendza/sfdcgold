public with sharing class InventoryRequestLineItemTriggerHandler {

    /**
     * @param lineItems   The line items being inserted.
     * @return            a List of the implicity updated  Inventory_Line_Item__c
     */
    public static List<Inventory_Request_Line_Item__c> updateLineItemNumber(List<Inventory_Request_Line_Item__c> lineItems) {
        List<Inventory_Request_Line_Item__c> updatedItems = new List<Inventory_Request_Line_Item__c>();

        //   Simply query parent rollup summary field to get total number of lines.
        Set<Id> irIds = new Set<Id>();
        for(Inventory_Request_Line_Item__c irLi :lineItems) {
            irIds.add(irLi.Inventory_Request__c);
        }
        Map<Id,Inventory_Request__c>  inventoryRequestMap = new Map<Id,Inventory_Request__c> (
            [   SELECT  Number_of_Items__c
                FROM    Inventory_Request__c
                WHERE   Id IN:irIds ]
        );
        Map<Id,Integer> latestChild = new Map<Id,Integer>();
        //    Implicity update Inventory_Request_Line_Item.Item_Number__c
        for(Inventory_Request_Line_Item__c lineItem : lineItems) {
            if(latestChild.containsKey(lineItem.Inventory_Request__c)) {
                lineItem.Item_Number__c = latestChild.get(lineItem.Inventory_Request__c);
            }
            else {
                Inventory_Request__c inventoryRequest = inventoryRequestMap.get(lineItem.Inventory_Request__c);
                Decimal itemNumber = 0;
                if(inventoryRequest != null && inventoryRequest.Number_of_Items__c != null) {
                    itemNumber = inventoryRequest.Number_of_Items__c;
                }
                lineItem.Item_Number__c = itemNumber + 1;
                latestChild.put(lineItem.Inventory_Request__c, (Integer)lineItem.Item_Number__c);
            }
            updatedItems.add(lineItem);
        }
        return updatedItems;
    }
}