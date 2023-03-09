trigger Accel_RPSTrigger on Route_Processing_Sheet__c (before update, after insert, before delete) {

    //  @todo store in trigger settings custom mdt to allow easy switch on / off
    //  @todo store in trigger settings custom mdt to allow easy switch on / off
    Boolean runTrigger = true;

    if (runTrigger) {
        clRPSTriggerHandler.handleTriggerEvent(Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.operationType);
    }
}