trigger Accel_InventoryRequestLineItemTrigger on Inventory_Request_Line_Item__c (before insert) {

    if(Trigger.isInsert && Trigger.isBefore) {
        InventoryRequestLineItemTriggerHandler.updateLineItemNumber(Trigger.new);
    }
}