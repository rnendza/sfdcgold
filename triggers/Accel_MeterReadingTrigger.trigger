/**
 * All things Meter_Reading__c.
 *
 * @see MeterReadingTriggerHandler
 */
trigger Accel_MeterReadingTrigger on Meter_Reading__c (before update, after insert, before delete) {

    //  @todo store in trigger settings custom mdt to allow easy switch on / off
    Boolean runTrigger = true;

    if (runTrigger) {
        MeterReadingTriggerHandler.handleTriggerEvent(Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.operationType);
    }
}