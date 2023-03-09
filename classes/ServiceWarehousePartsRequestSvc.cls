public with sharing class ServiceWarehousePartsRequestSvc {

    public static final String LOC_TYPE_WAREHOUSE   =   'Warehouse';
    public static String BR_WAREHOUSE_NAME          =   'Burr Ridge Warehouse';
    public static String ACCEL_CENTRAL_HUB_WH_NAME  =   'Accel Central Hub';
    public static Set<String> ASSET_RTS             =   new Set<String>{'VGT','RT'};

    /**
     * Retrieves a list of Location sObjects that are tied to service territories that have a
     * Restock_Warehouse__c value != NULL.
     *
     * @return              A List of Schema.Location sObjects.
     *
     * @see ServiceWarehousePartsRequestSvc.retrieveLocations
     */
    public static List<Schema.Location> retrieveWarehouseLocations() {
        return retrieveLocations(new Set<String>{LOC_TYPE_WAREHOUSE});
    }

    /**
     * Retrieves a list of Location sObjects that are tied to service territories that have a
     * Restock_Warehouse__c value != NULL.
     *
     * @param locationTypes The Location.Type field value(s).
     * @return              A List of Schema.Location sObjects.
     *
     * @todo                This seems hacky! No service territories are linked to Burr Ridge Warehouse!
     */
    public static List<Schema.Location> retrieveLocations(Set<String> locationTypes) {

        List<Schema.Location> locations = [
                SELECT  Id,Name,LocationType,IsInventoryLocation,IsMobile
                FROM    Location
                WHERE   Name = :BR_WAREHOUSE_NAME
        ];
        locations.addAll([
                SELECT  Id,Name,LocationType,IsInventoryLocation,IsMobile
                FROM    Location
                WHERE   LocationType IN :locationTypes
                AND     Id IN (
                        SELECT Restock_Warehouse__c
                        FROM   ServiceTerritory
                        WHERE  Restock_Warehouse__c != NULL
                )
                AND     Name != :ACCEL_CENTRAL_HUB_WH_NAME
                ORDER  BY Name ASC
        ]);
        return locations;
    }

    /**
     * Retrieves a Map containing a Single Asset found for the supplied Asset.Name and Asset.AccountId.
     *
     * @param assetName  The Asset.Name value.
     * @param accountId  The Warehouse Account sObject Id (According to Mario)
     *
     * @return           A Map of Asset.Id => Asset sObject.
     */
    public static Map<Id,Asset> retrieveAsset(String assetName,Id accountId) {

        Map<Id, Asset> mAssets = new Map<Id, Asset>([
                SELECT Id,Name,Model__c,SAS__c,RecordType.DeveloperName, SerialNumber,AccountId
                FROM   Asset
                WHERE  Name = :assetName
                AND    RecordType.Name IN :ASSET_RTS
                AND    AccountId = :accountId
                ORDER  BY Name ASC
        ]);
        return mAssets;
    }

    /**
     * Retrieves All assets for the given account Id that are of VGT and RT Recordtypes.
     *
     * @param accountId The Asset.AccountId
     * @return A Map of Asset.Id => Asset sObject.
     */
    public static Map<Id,Asset> retrieveWarehouseAssets(Id accountId) {

        Map<Id, Asset> mAssets = new Map<Id, Asset>([
                SELECT Id,Name,Model__c,SAS__c,RecordType.DeveloperName, SerialNumber,AccountId
                FROM   Asset
                WHERE  RecordType.Name IN :ASSET_RTS
                AND    AccountId = :accountId
                ORDER  BY Name ASC
        ]);
        return mAssets;
    }

    /**
     * @param developerName     The ListView.DeveloperName.
     * @param sObjectApiName    The ListView.SobjectType.
     *
     * @return                  If found a ListView sObject, otherwise null.
     */
    public static ListView retrieveListView(String developerName, String sObjectApiName) {
        ListView lv;

        List<ListView> listViews = [
                SELECT  Id, Name, DeveloperName
                FROM    ListView
                WHERE   SobjectType   = :sObjectApiName
                AND     DeveloperName = :developerName
        ];
        if(!listViews.isEmpty()) {
            lv = listViews[0];
        }
        return lv;
    }
}