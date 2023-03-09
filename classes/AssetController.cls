public with sharing class AssetController {

    public final static String MAP_KEY_SW_ASSET_CONFIG_SETTING = 'SW_ASSET_CONFIG';
    public final static String MAP_KEY_PO_ITEMS = 'MAP_KEY_PO_ITEMS';
    /**
     * @param poId
     * @return a dto containing the Purchase_Order__c {dto.sObj}
     */
    @AuraEnabled
    public static ResponseDto retrievePo( Id poId ) {
        ResponseDto dto = new ResponseDto();
        Purchase_Order__c purchaseOrder = PoSvc.retrievePo(poId);
        Software_Assets_Config__c configSettings = CustomSettingsSvc.getSoftwareAssetsConfigSettings(UserInfo.getUserId());
        if(purchaseOrder != null) {
            dto.sObj = purchaseOrder;
            dto.values.put(MAP_KEY_SW_ASSET_CONFIG_SETTING,configSettings);
            dto.isSuccess = true;
        }
        return dto;
    }
    /**
     *
     * Retrieves all the po items for a parent purchase order id.
     * @param poId The parent Purchase Order SFDC Id.
     * @return a dto containing the custom setting info and po items
     */
    @AuraEnabled
    public static ResponseDto retrievePoItems( Id poId ) {
        ResponseDto dto = new ResponseDto();
        List<Purchase_Order_Item__c> purchaseOrderItems = PoSvc.retrievePoItems(poId);
        Software_Assets_Config__c configSettings = CustomSettingsSvc.getSoftwareAssetsConfigSettings(UserInfo.getUserId());
        if(!purchaseOrderItems.isEmpty()) {
            dto.values.put(MAP_KEY_PO_ITEMS,purchaseOrderItems);
            dto.values.put(MAP_KEY_SW_ASSET_CONFIG_SETTING,configSettings);
            dto.isSuccess = true;
        }
        return dto;
    }
}