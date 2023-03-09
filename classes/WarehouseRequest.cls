public with sharing class WarehouseRequest {
    
    @AuraEnabled (cacheable=true)
    public static List<Account> getWarehouseList(){
        List<String> warehouseNames = new List<String>{'Burr Ridge Warehouse','Champaign Warehouse','Collinsville Warehouse','Peoria Warehouse','Rockford Warehouse','Springfield Warehouse','Tinley Park Warehouse'};

        return [SELECT Id, Name, Type FROM Account WHERE Name IN :warehouseNames WITH SECURITY_ENFORCED];

    }

    @AuraEnabled
    public static List<Asset> getAssetList(Id whId){

        System.debug(whId);
        List<Asset> assetList = new List<Asset>();

        assetList = [SELECT Id, Name, LocationId, AccountId, Device_Type__c, RecordTypeId, Record_Type_Name__c FROM Asset WHERE AccountId =:whId AND Record_Type_Name__c IN ('VGT','Redemption') WITH SECURITY_ENFORCED];

        return assetList;
    }

    @AuraEnabled
    public static string getListView(String recordTypeName, String sObjectApiName){
        
        ListView listView = [SELECT Id FROM ListView WHERE SobjectType =:sObjectApiName AND DeveloperName =:recordTypeName WITH SECURITY_ENFORCED];
        return listView.Id;
    }

    /*@AuraEnabled
    public static List<ProductRequest> getProductReqList(List<String> recordIds){
        try {
            return [SELECT Id, Asset__c FROM ProductRequest WHERE Asset__c IN :recordIds WITH SECURITY_ENFORCED];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/
}