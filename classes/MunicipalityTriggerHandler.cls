public with sharing class MunicipalityTriggerHandler {

    /**
     * Creates a blank entry in Hold per data totals sObject for purposes of future update in aggregation batch jobs.
     * Will also update municipality records lookup refs with new values created in HPD.
     * @param mMunicipalitiesByIds
     */
    public static void createHpdTotals(Map<Id,Municipality__c> mMunicipalitiesByIds) {

        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        Map<Id,Municipality__c> mMunicipalitiesByIdsProcessed = new Map<Id,Municipality__c>();

        try {
            Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe()
                    .getRecordTypeInfosByDeveloperName().get('Municipality').getRecordTypeId();
            for (Municipality__c municipality : mMunicipalitiesByIds.values()) {
                    Hold_Per_Day_Total__c holdPerDayTotal = new Hold_Per_Day_Total__c();
                    holdPerDayTotal.frequency__c = 'Monthly';
                    holdPerDayTotal.recordtypeid = rtId;
                    holdPerDayTotal.Municipality__c = municipality.id;
                    holdPerDayTotals.add(holdPerDayTotal);
                    mMunicipalitiesByIdsProcessed.put(municipality.id,municipality);
            } 
        } catch (Exception e) {
            system.debug(logginglevel.error,e);//@TODO send error email.
        }
        if(!holdPerDayTotals.isEmpty()) {
            try {
                insert holdPerDayTotals;
                updateMuniHpdTotalLookups(holdPerDayTotals,mMunicipalitiesByIdsProcessed);
            } catch (Exception e) {
                system.debug(logginglevel.error, e);
            }
        }
    }
    /**
    * So now we take the hold per day totals that were inserted (daily and monthly) and must tag the lookup back on the muni record.
    * We must clone the current muni so that we are processing to avoid read only errors.
    *
    * @param newHoldPerDayTotals
    * @param mMunicipalitiesByIds
    */
    public static void updateMuniHpdTotalLookups(List<Hold_Per_Day_Total__c> newHoldPerDayTotals, Map<Id,Municipality__c> mMunicipalitiesByIds)  {
        Map<Id,List<Hold_Per_Day_Total__c>> mHoldPerDayTotalsByMuniIds = new Map<Id,List<Hold_Per_Day_Total__c>>();
        for(Hold_Per_Day_Total__c holdPerDayTotal : newHoldPerDayTotals) {
            if(!mHoldPerDayTotalsByMuniIds.containsKey(holdPerDayTotal.Municipality__c)) {
                mHoldPerDayTotalsByMuniIds.put(holdPerDayTotal.municipality__c,new List<Hold_Per_Day_Total__c>{holdPerDayTotal});
            } else {
                List<Hold_Per_Day_Total__c> hpdts = mHoldPerDayTotalsByMuniIds.get(holdPerDayTotal.municipality__c);
                hpdts.add(holdPerDayTotal);
            }
        }
        List<Municipality__c> munisToUpd = new List<Municipality__c>();
        for(Id muniId : mHoldPerDayTotalsByMuniIds.keySet()) {
            Municipality__c muni = mMunicipalitiesByIds.get(muniId);
            if(muni != null) {
                Municipality__c muniClone = muni.clone(true,true);
                List<Hold_Per_Day_Total__c> holdPerDayTotals = mHoldPerDayTotalsByMuniIds.get(muniClone.id);
                for(Hold_Per_Day_Total__c hpdTotal: holdPerDayTotals) {
                    if(hpdTotal.frequency__c == 'Monthly') {
                        muniClone.hold_per_day_total__c = hpdTotal.id;
                    } else if (hpdTotal.frequency__c == 'Daily') {
                        muniClone.hold_per_day_total_daily__c = hpdTotal.id;
                    }
                }
                munisToUpd.add(muniClone);
            }
        }
        if (!munisToUpd.isEmpty()) {
            update munisToUpd;
            system.debug('------ updated ' +munisToUpd.size() + ' muni recs');
        }
    }
}