/**
 * @see OppTriggerHandler
 */
trigger Accel_OpportunityTrigger on Opportunity (after insert, after update) {

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OppTriggerHandler.updateLocationUnder21(null, Trigger.newMap);
        } else if (Trigger.isUpdate) {
            OppTriggerHandler.updateLocationUnder21(Trigger.oldMap, Trigger.newMap);
        }
    }
}