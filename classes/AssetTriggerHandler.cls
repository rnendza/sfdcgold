public with sharing class AssetTriggerHandler {
    /**
     * Fired on before update but launches queueable (if needed to exit current ctx).
     *
     * Pseudo.
     * 1. Ensure we are not in recursion. ie. pbs / flow didn't force this trigger to run multiple times.
     * 2. If there is a VGT Asset being modified see if it's account changed.
     * 3. If so find the child software asset records (if any) of that VGT Asset.
     * 4. Modify the account of the child software asset records to that of their new parent vgt record accountid.
     * 5. Launch a queueable to do the actual update so we exit the current transaction context.
     *
     * If this fails. it will log the exception but.. They queueable may throw a gov limit exception but the UI will / cannot see that.
     *
     *
     * @param oldParentAssets a map of the Asset records before update.
     * @param newParentAssets a map of the Asset records after changes will be committed.
     *
     * @see   https://accel-entertainment.monday.com/boards/942883797/pulses/1404273791
     * @see   Test_AssetTrigger.testSwAssetParentAccountMod_Positive
     */
    public static void updateSoftwareAssetAccount(Map<Id,Asset> oldParentAssets, Map<Id,Asset> newParentAssets) {

        // avoid those nasty process builders recursively triggering this!
        if(RecursiveTriggerHandler.isFirstTime) {
            RecursiveTriggerHandler.isFirstTime = false;

            Map<String, RecordTypeInfo> mRts = Asset.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName();
            Id swRtId = mRts.get('Software')?.getRecordTypeId();
            Id vgtRtId = mRts.get('VGT')?.getRecordTypeId();

            Map<Id, Id> mParentAsset_newAccountId = new Map<Id, Id>();
            Set<Asset> childAssetsToUpdate = new Set<Asset>();

            System.debug('--> before update.. updateSoftwareAssetAcount.. newAssets=' + newParentAssets);

            for (Asset newParentAsset : newParentAssets.values()) {
                Asset oldParentAsset = oldParentAssets.get(newParentAsset.Id);

                //  If we have a VGT Being Modified and its account changes.
                if (newParentAsset.recordTypeId == vgtRtId) {
                    System.debug('vgt');
                    if (newParentAsset.accountId != oldParentAsset.accountId) {
                        System.debug('accountId mod');
                        mParentAsset_newAccountId.put(newParentAsset.Id, newParentAsset.AccountId);
                    }
                }
                //  We found some mods.. look for their child software records.
                if (!mParentAsset_newAccountId.isEmpty()) {
                    Map<Id, Asset> mChildAssets = new Map<Id, Asset>([
                            SELECT Id, AccountId,ParentId
                            FROM Asset
                            WHERE ParentId In :mParentAsset_newAccountId.keySet()
                            And Asset.RecordTypeId = :swRtId
                    ]);
                    // if we found child software records.. modify their account to that of the parent and save them for later.
                    if (!mChildAssets.isEmpty()) {
                        for (Asset childAsset : mChildAssets.values()) {
                            Id newAccountId = mParentAsset_newAccountId.get(childAsset.ParentId);
                            childAsset.accountId = newAccountId;
                            childAssetsToUpdate.add(childAsset);
                        }
                    }
                }
            }
            //  Fire a queueable so we get out of this before asset up ctx and have our own gov limits to reduce
            //  CPU timeout chances.
            if (!childAssetsToUpdate.isEmpty()) {
                System.debug('--> fire queueable to update asset account ids!');
                System.enqueueJob(new QueueableAssetAccountMods(childAssetsToUpdate));
            }
        }
    }
    /**
     * On AFTER UPDATE... If the assets accountId is updated and accountId previously had a value, finds any associated
     * meter readings that were created today  ( WHERE CreatedDate = TODAY AND CreatedDate <= :System.now() )
     *
     * Tags the current datetime on Meter_Reading__c.Asset_Moved_Date__c
     *
     * @param oldAssets A Map of Asset.Id => Asset indicating the state before the update.
     * @param newAssets A Map of Asset.Id => Asset indicating the state prior to the update.
     *
     * @return   A List of any Meter_Reading__c sObject updated, otherwise empty.
     *
     * @todo     Handle recursion caused by flows / process builders?
     * @see      TEST_AssetTrigger.test_Asset_AccountMove_Cl_sameday_Positive
     * @see      TEST_AssetTrigger.test_Asset_AccountMove_Cl_prevdays_Positive
     */
    public static List<Meter_Reading__c> updateTodaysExistingMeterReadings(Map<Id,Asset> oldAssets, Map<Id,Asset> newAssets) {

        List<Meter_Reading__c> meterReadingsUpdated = new List<Meter_Reading__c>();

        Set<Id> assetMovedIds = new Set<Id>();
        for (Asset newAsset : newAssets.values()) {
            Asset oldAsset = oldAssets.get(newAsset.Id);
            if(newAsset.accountId != null && oldAsset.AccountId != null && newAsset.AccountId != oldAsset.AccountId) {
                assetMovedIds.add(newAsset.Id);
            }
        }

        if(!assetMovedIds.isEmpty()) {
            List<Meter_Reading__c> meterReadings = [
                    SELECT Id,Asset__c,Asset_Moved_Date__c
                    FROM   Meter_Reading__c
                    WHERE  CreatedDate = TODAY
                    AND    CreatedDate <= :System.now()
                    AND    Asset__c IN :assetMovedIds
            ];
            if(!meterReadings.isEmpty()) {
                for(Meter_Reading__c mr : meterReadings) {
                    mr.Asset_Moved_Date__c = System.now();
                    meterReadingsUpdated.add(mr);
                }
            }
            if(!meterReadingsUpdated.isEmpty()) {
                update meterReadingsUpdated;
            }
        }
        return meterReadingsUpdated;
    }

    /**
     * Fire asset update in future so as not escape Process builder issues.
     */
    public class QueueableAssetAccountMods implements Queueable {
        Set<Asset> assetsToUpdate;

        public QueueableAssetAccountMods(Set<Asset> assetsToUpd) {
            this.assetsToUpdate = assetsToUpd;
        }
        public void execute(QueueableContext ctx){
            System.debug(LoggingLevel.DEBUG,'--->running queueable job'+ctx.getJobId());
            System.debug(LoggingLevel.DEBUG,'----> assetsToUpdate='+assetsToUpdate);
            performExecute();
        }

        //  @todo mod to Database dml
        public void performExecute() {
            try {
                if(assetsToUpdate != null && !assetsToUpdate.isEmpty()) {
                    System.debug('--> firing asset update!');
                    update new List<Asset>(assetsToUpdate);
                    System.debug('--> updated ' + assetsToUpdate.size()+' assets');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }
        }
    }
    /**
     * Call on BEFORE INSERT.. Takes new assets and appends a Asset.SerialNumber to them for Software
     * Assets that don't have a Asset.Request_Line_Item__c attached. this is done as we are already incrementing
     * the serial number on the create assets button which will associate that value. This method handles creating
     * software assets outside of the normal IR process.
     *
     * @param assets  A list of Asset sObjects.
     * @return a List of  Asset sObjects with Serial Number populated.
     */
    public static List<Asset> populateSerialNumber ( List<Asset> assets ) {
        List<Asset> updatedAssets = new List<Asset>();
        try {

            Id softwareRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('Software').getRecordTypeId();
            Software_Assets_Config__c configSettings = Software_Assets_Config__c.getOrgDefaults();
            Decimal serialNumber = configSettings.Latest_Serial_Number__c;
            Boolean anyUpdated = false;

            for ( Asset newAss : assets ) {
                if(newAss.RecordTypeId == softwareRecordTypeId) {
                    //---- skip imports
                    if(newAss.Legacy_SW_Serial__c == null) {
                        if (newAss.Inventory_Request_Line_Item__c == null || newAss.Created_by_VGT_Software_Transfer__c == true) {
                            anyUpdated = true;
                            serialNumber++;
                            //  IMPLICIT append of SerialNumber on IMPLICIT SEARCH
                            newAss.SerialNumber = configSettings.Asset_Name_Prefix__c + String.valueOf(serialNumber);
                            updatedAssets.add(newAss);
                        }
                    }
                }
            }
            if(anyUpdated) {
                configSettings.Latest_Serial_Number__c = serialNumber + 1;
                upsert configSettings; // increment saved counter in Custom Settings.
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
        }
        return updatedAssets;
    }

    /**
     * In case assets are deleted, ifthere is an Inventory_Request_Line_Item__c associated with it,
     * Go back to the line item and decrement the number of assets created value by 1.
     * @param oldAssetsByIds
     */
    public static void updateInventoryRequestLineOnDelete(Map<Id, Asset> oldAssetsByIds) {
        Map<Id, Integer> mIrLineId_NumToDecrement = new Map<Id, Integer>();

        for (Asset oldAsset : oldAssetsByIds.values()) {
            Id irLineId = oldAsset.Inventory_Request_Line_Item__c;
            if (irLineId != null) {
                if (!mIrLineId_NumToDecrement.containsKey(irLineId)) {
                    mIrLineId_NumToDecrement.put(irLineId, 1);
                } else {
                    Integer iNumToDecrement = mIrLineId_NumToDecrement.get(irLineId);
                    if (iNumToDecrement != null) {
                        iNumToDecrement++;
                        mIrLineId_NumToDecrement.put(irLineId,iNumToDecrement);
                    }
                }
            }
        }
        if(!mIrLineId_NumToDecrement.isEmpty()) {
            List<Inventory_Request_Line_Item__c> irLineItems = [
                    SELECT  Id, Number_of_Assets_Created__c
                    FROM    Inventory_Request_Line_Item__c
                    WHERE   Id IN :mIrLineId_NumToDecrement.keySet()
            ];
            if(!irLineItems.isEmpty()) {
                for(Inventory_Request_Line_Item__c irLi : irLineItems) {
                    if(irLi.Number_of_Assets_Created__c != null) {
                        Integer iNumToDecrement = mIrLineId_NumToDecrement.get(irLi.Id);
                        if(iNumToDecrement != null) {
                            irLi.Number_of_Assets_Created__c -= iNumToDecrement;
                        }
                    }
                }
                try {
                    update irLineItems;
                } catch (Exception e) {
                    System.debug(Logginglevel.ERROR,e);
                }
            }
        }
    }

    /**
      * Creates a blank entry in Hold per data totals sObject for purposes of future update in aggregation batch jobs.
      * Will also update asset records lookup ntrefs to HPD Totals with new values created in HPD Totals.
      * @param mAssetsByIds
      *
      * @TODO DML Ex handling.
      */
    public static void createHpdTotals(Map<Id, Asset> mAssetsByIds) {

        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        Map<Id, Asset> mAssetsByIdsProcessed = new Map<Id, Asset>();
        try {
            Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Machine').getRecordTypeId();
            Id assetRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('VGT').getRecordTypeId();
            for (Asset asset : mAssetsByIds.values()) {
                if (asset.recordtypeId == assetRtId) {
                    Hold_Per_Day_Total__c holdPerDayTotal = new Hold_Per_Day_Total__c();
                    holdPerDayTotal.frequency__c = 'Daily';
                    holdPerDayTotal.recordtypeid = rtId;
                    holdPerDayTotal.asset__c = asset.id;
                    holdPerDayTotals.add(holdPerDayTotal);
                    mAssetsByIdsProcessed.put(asset.id, asset);
                }
            }
        } catch (Exception e) {
            system.debug(e);
        }
        if (!holdPerDayTotals.isEmpty()) {
            try {
                insert holdPerDayTotals;
                updateAssetHpdTotalLookups(holdPerDayTotals,mAssetsByIdsProcessed);
            } catch (Exception e) {
                system.debug(logginglevel.error, e);
            }
        }
    } 
    /**
     * So now we take the hold per day totals that were inserted (daily and monthly) and must tag the lookup back on this asset record.
     * We must clone the current asset that we are processing to avoid read only errors.
     *
     * @param newHoldPerDayTotals
     * @param mAssetsByIds
     */
    public static void updateAssetHpdTotalLookups(List<Hold_Per_Day_Total__c> newHoldPerDayTotals, Map<Id,Asset> mAssetsByIds)  {
        Map<Id,List<Hold_Per_Day_Total__c>> mHoldPerDayTotalsByAssetIds = new Map<Id,List<Hold_Per_Day_Total__c>>();
        for(Hold_Per_Day_Total__c holdPerDayTotal : newHoldPerDayTotals) {
            if(!mHoldPerDayTotalsByAssetIds.containsKey(holdPerDayTotal.asset__c)) {
                mHoldPerDayTotalsByAssetIds.put(holdPerDayTotal.asset__c,new List<Hold_Per_Day_Total__c>{holdPerDayTotal});
            } else {
                List<Hold_Per_Day_Total__c> hpdts = mHoldPerDayTotalsByAssetIds.get(holdPerDayTotal.asset__c);
                hpdts.add(holdPerDayTotal);
            }
        }
        List<Asset> assetsToUpd = new List<Asset>();
        for(Id assetId : mHoldPerDayTotalsByAssetIds.keySet()) {
            Asset asset = mAssetsByIds.get(assetId);
            if(asset != null) {
                Asset assetClone = asset.clone(true,true);
                List<Hold_Per_Day_Total__c> holdPerDayTotals = mHoldPerDayTotalsByAssetIds.get(assetClone.id);
                for(Hold_Per_Day_Total__c hpdTotal: holdPerDayTotals) {
                    assetClone.hold_per_day_total__c = hpdTotal.id;
                }
                assetsToUpd.add(assetClone);
            }
        }
        if (!assetsToUpd.isEmpty()) {
            update assetsToUpd;
        }
    }
}