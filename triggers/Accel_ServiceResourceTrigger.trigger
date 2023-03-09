/**
 *  Trigger on FSL Object ServiceResource.
 *  @see ServiceResourceTriggerHandler for implemented logic.
 */
trigger Accel_ServiceResourceTrigger on ServiceResource ( before insert, before update ) {

    if ( Trigger.isBefore ) {
        if ( Trigger.isUpdate ) {
            ServiceResourceTriggerHandler.updateName( Trigger.oldMap,Trigger.newMap );
        } else if ( Trigger.isInsert ) {
            ServiceResourceTriggerHandler.updateName( Trigger.new );
        }
    }
}