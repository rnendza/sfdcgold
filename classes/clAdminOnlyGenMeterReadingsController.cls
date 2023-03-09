public with sharing class clAdminOnlyGenMeterReadingsController {

    public static final String MAP_KEY_METERS   = 'MAP_KEY_METERS';
    public static final String MAP_KEY_RPS      = 'MAP_KEY_RPS';

    /**
     * Simulates clBatchMeterReadingsCreation
     *
     * @param rpsId The Route_Processing_Sheet.Id value.
     * @return      A ResponseDto object with a List of Meter_Reading__c sObjects in the values Map.
     */
    @AuraEnabled
    public static ResponseDto doCreateMeterReadings(Id rpsId) {
        ResponseDto dto = new ResponseDto();

        Route_Processing_Sheet__c rps =  [
                SELECT  Id,Account__c,Route_Schedule__c,Processing_Location__c
                FROM    Route_Processing_Sheet__c
                WHERE   Id = :rpsId
        ];
        Set<String> rtDevNames = new Set<String>{'VGT'};
        Map<Id,Asset> accountMachines = AssetSvc.retrieveAccountMachines(new Set<Id>{rps.Account__c}, rtDevNames);
        List<Meter_Reading__c> meterReadingsIns = new List<Meter_Reading__c>();

        Map<Id,List<Asset>> mAccountId_Assets = new Map<Id,List<Asset>>();
        for(Asset asset : accountMachines.values()) {
            if(!mAccountId_Assets.containsKey(asset.AccountID)) {
                mAccountId_Assets.put(asset.AccountId,new List<Asset>{asset});
            } else {
                List<Asset> currAccountAssets = mAccountId_Assets.get(asset.AccountId);
                currAccountAssets.add(asset);
            }
        }
        List<Asset> rpsAssets = mAccountId_Assets.get(rps.Account__c);

        if(rpsAssets != null && !rpsAssets.isEmpty()) {
            for (Asset rpsAsset : rpsAssets) {
                Meter_Reading__c reading = new Meter_Reading__c();
                reading.Asset__c = rpsAsset.Id;
                reading.BV_Type__c = rpsAsset.BV_Type__c;
                reading.Route_Processing_Sheet__c = rps.Id;
                reading.Reading_Status__c = 'New';
                meterReadingsIns.add(reading);
            }
        }
        insert  meterReadingsIns;

        Map<Id,Meter_Reading__c> mMeters = clMeterSvc.retrieveRpsMeterReadings(rpsId);
        dto.values.put(MAP_KEY_METERS,mMeters.values());
        dto.isSuccess = mMeters != null && !mMeters.isEmpty();

        return dto;
    }

    /**
     * @param rpsId The Route_Processing_Sheet.Id value.
     * @return      A ResponseDto object with a Route_Processing_Sheet__c sObjects in the values Map.
     */
    @AuraEnabled
    public static ResponseDto doRetrieveRps(Id rpsId) {

        Route_Processing_Sheet__c rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rpsId);
        ResponseDto dto = new ResponseDto();

        dto.values.put(MAP_KEY_RPS,rps);
        dto.isSuccess = rps != null;

        return dto;
    }
}