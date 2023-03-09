/**
 * @see AssetTriggerHandler
 */
trigger Accel_AssetTrigger on Asset (before insert, after insert, before delete,before update, after update ) {

    if(Trigger.isBefore) {
        if (Trigger.isInsert) {
            AssetTriggerHandler.populateSerialNumber(Trigger.new);
        }
        //  IF this asset being deleted is associated with an IR Line Item, decrement the assets created on that by 1
        if (Trigger.isDelete) {
            AssetTriggerHandler.updateInventoryRequestLineOnDelete(Trigger.oldMap);
        }
        if (Trigger.isUpdate) {
            AssetTriggerHandler.updateSoftwareAssetAccount(Trigger.oldMap, Trigger.newMap);
        }
    }

    if(Trigger.isAfter && Trigger.isInsert) {
        //  Create blank role in hold_per_day_totals so we only need to update upon aggregation.
        if(Trigger.isInsert) {
            AssetTriggerHandler.createHpdTotals(Trigger.newMap);
        }
    }

    if(Trigger.isAfter && Trigger.isUpdate) {
        List<Meter_Reading__c> meterReadingsUpdated = AssetTriggerHandler.updateTodaysExistingMeterReadings(Trigger.oldMap ,
                                                                                                            Trigger.newMap);
        if(!meterReadingsUpdated.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, '--> todays update meter readings' + meterReadingsUpdated);
        }
    }
}