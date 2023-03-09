/**
 *  Handle Route Schedule Account Deletes, Creates (Possible updates?) and then modify
 *  any related Route Processing Sheets / Fire Platform Event to inform the UI (user when they take this action
 *  in backend crm) of what changed on the RPS Record / RPS Records that were deleted / added.
 */
trigger Accel_RouteScheduleAccountTrigger on Route_Schedule_Account__c (    before insert,
                                                                            after insert,
                                                                            before update,
                                                                            after update,
                                                                            before delete,
                                                                            after delete) {
    //  @todo store in trigger settings custom mdt to allow easy switch on / off
    Boolean runTrigger = true;

    if (runTrigger) {
        RouteScheduleAccountTriggerHandler.handleTriggerEvent(Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.operationType);
    }
}