trigger Accel_MunicipalityTrigger on Municipality__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert) {
        MunicipalityTriggerHandler.createHpdTotals(Trigger.newMap);
    }
}