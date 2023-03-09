trigger Accel_ContentVersionTrigger on ContentVersion (after insert /*,after delete*/ ) {
    Boolean runTrigger = true;

    if (runTrigger) {
        clContentVersionTriggerHandler.handleTriggerEvent(Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.operationType);
    }
}