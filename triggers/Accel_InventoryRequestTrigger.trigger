trigger Accel_InventoryRequestTrigger on Inventory_Request__c (before update) {

    if(Trigger.isUpdate) {
        if(Trigger.isBefore) {
            InventoryRequestTriggerHandler.updateIrStatus( Trigger.oldMap ,Trigger.newMap);
        }
        if(Trigger.isBefore) {
            InventoryRequestTriggerHandler.updateFinalApprovedIndicator( Trigger.oldMap , Trigger.newMap );
        }
    }
}