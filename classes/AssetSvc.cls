public with sharing class AssetSvc {

    public final static String ASSET_RT_REDEMPTION = 'Redemption';

    public static List<Asset> retrieveAccountVgts(Id accountId) {
        return retrieveAccountMachines(accountId, new Set<String>{'VGT'});
    }

    public static List<Asset> retrieveAccountRts(Id accountId) {
        return retrieveAccountMachines(accountId, new Set<String>{'Redemption'});
    }
    /**
     * Find all VGT and Redemption Assets for the provided Account.Id.
     *
     * @param accountId  The Account.Id value to find machines for.
     * @return           A List of Asset sObjects that are wither VGT or Redemption Assets.
     */
    public static List<Asset> retrieveAccountMachines(Id accountId) {
        return retrieveAccountMachines(accountId, new Set<String>{'VGT','Redemption'});
    }
    /**
     * @param accountId     The Account.Id value to find assets for.
     * @param rtDevNames    The record type developer name of the Asset sObject.
     *
     * @return              A List of Asset sObjects for the account.
     */
    public static List<Asset> retrieveAccountMachines(Id accountId, Set<String> rtDevNames) {
        List<Asset> assets = new List<Asset>();
        Map<Id,Asset> m = retrieveAccountMachines(new Set<Id>{accountId},rtDevNames);
        if(!m.isEmpty()){
            assets = m.values();
        }
        return assets;
    }
    /**
     * Return assets for the provided account ids and record type developer names.
     *
     * @param accountIds A Set of AccountIds.
     * @param rtDevNames A Set of record type developer names.
     *
     * @return           A Map Asset.Id => Asset sObject
     */
    public static Map<Id,Asset> retrieveAccountMachines(Set<Id> accountIds, Set<String> rtDevNames) {

        Map<Id,Asset> assets = new Map<Id,Asset>([
                SELECt   Id, Name, SAS__c,Model__c,SerialNumber,RecordType.DeveloperName,RecordType.Name,AccountId,
                         BV_Type__c,Current_Info__c
                FROM     Asset
                WHERE    AccountId IN :accountIds
                AND      RecordType.DeveloperName IN :rtDevNames
                ORDER BY SAS__c ASC
        ]);
        return assets;
    }
   /**
    * Return redemption assets for the provided account ids.
    *
    * @param accountIds  A Set of Account.Id values.
    * @return            A Map of Account ID => List of Redemption Assets for the account id.
    */
    public static Map<Id, List<Asset>> retrieveAccountsRedemptionAssets(Set<Id> accountIds) {

        Map<Id, List<Asset>> mAcctId_Assets = new Map<Id, List<Asset>>();

        //  1. Give me all Assets of Type 'Redemption' for the set of account Ids.
        Map<Id, Asset> mAssets = new Map<Id, Asset>([
                SELECt   Id, Name, SAS__c,Model__c,SerialNumber,RecordType.DeveloperName,RecordType.Name,AccountId,
                         GP_Manufacturer__c
                FROM     Asset
                WHERE    AccountId IN :accountIds
                AND      RecordType.DeveloperName = :ASSET_RT_REDEMPTION
                ORDER BY SAS__c ASC
        ]);

        //  2. Restructure data to Give me 0 => m Redemption Assets for the account.
        if (!mAssets.isEmpty()) {
            for (Asset asset : mAssets.values()) {
                if (!mAcctId_Assets.containsKey(asset.AccountId)) {
                    mAcctId_Assets.put(asset.AccountId, new List<Asset>{asset});
                } else {
                    List<Asset> accountAssets = mAcctId_Assets.get(asset.AccountId);
                    accountAssets.add(asset);
                }
            }
        }
        return mAcctId_Assets;
    }
}