/**
 * @see AccountTriggerHandler
 */
trigger Accel_AccountTrigger on Account (before insert, after insert, after update, before update, before delete) {

    if(Trigger.isBefore && Trigger.isDelete) {
        AccountTriggerHandler.checkDeleteSecurity(Trigger.oldMap);
    }
    

    //  Create blank row in hold_per_day_totals so we only need to update upon aggregation.
    if(Trigger.isAfter && Trigger.isInsert) {
        AccountTriggerHandler.createHpdTotals(Trigger.newMap);

    }

    /*
     *   If the account type was changed from something we weren't creating hold per day totals for.
     *   ie Prospect.. to something we are creating hold per day totals for... then see if a row exists
     *   in hold_per_day_total__c.. if not create one.
     */
    if(Trigger.isAfter && Trigger.isUpdate) {
        System.debug('----> Acct trigger after update');
        AccountTriggerHandler.potentiallyCreateHpdTotals(Trigger.oldMap,Trigger.newMap);

        AccountTriggerHandler.assignMuniLookup(Trigger.oldMap,Trigger.newMap);
        // note. county / region is not spawed from the muni queuable.
        //AccountTriggerHandler.assignCountyLookup(Trigger.oldMap,Trigger.newMap);

    }

    //  If we update a location / accel account to have a accel vgt live date.. then create a location assessment.
    if(Trigger.isBefore && Trigger.isUpdate) {
        AccountTriggerHandler.potentiallyCreateLocationAssessment(Trigger.oldMap, Trigger.newMap);
        // if shipping address changed. set Account.County_Auto_Updated__c to FALSE so that the queueable job
        // can pick it up and check the FCC site for County info
        AccountTriggerHandler.checkShippingAddressUpdates(Trigger.oldMap,Trigger.newMap);

        try {
            Set<Id> accountIdsForMuniUpdate = new Set<Id>();
            for (Account newAccount : Trigger.newMap.values()) {
                Account oldAccount = Trigger.oldMap.get(newAccount.id);
                if (
                        (newAccount.ShippingState != oldAccount.ShippingState && newAccount.ShippingState != null)
                        && (newAccount.MunicipalityLookup__c == oldAccount.MunicipalityLookup__c)
                   ) {
                    System.debug('---------> setting muni null');
                    newAccount.MunicipalityLookup__c = null;
                    // bypass muni val rules of muni in same state as we have an order of execution issue here
                    // since data.com executes async and we won't get the new muni till after val rules fire.
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e);
        }




        //  If County__c was updated (via queueable) then run the below to update County_LU__c and Covid_Region_LU__C,
        //  and Covid_Region_AutoUpdate__c = TRUE
        //@todo deprecated in favor of real time trigger (after update and queuable .assignMuniLookup)
//        try {
//            AccountTriggerHandler.tagCountyLuAndRegionLu(Trigger.oldMap,Trigger.newMap);
//        } catch (Exception e) {
//            System.debug(LoggingLevel.ERROR,e);
//        }
    }

    //  Initially placed here for Lead conversion
    if(Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.copyBillingToShipping(Trigger.new);
    }

}