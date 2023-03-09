public with sharing class ProductSvc {
    /**
     * @return List<Product2> that have asset model names.
     */
    public static List<Product2> retrieveAllMachineAverages() {
        List<Product2> products;
        String productFamily = 'ASSET';
        products = [
                SELECT  id, name, asset_model_name__c,
                        Thirty_Day_Location_Share_Avg__c,Thirty_Day_Revenue_Avg__c,
                        Thirty_Day_Location_Share_Total__c,Thirty_Day_Revenue_Total__c
                FROM    Product2
                WHERE   Family  =   :productFamily
                and     asset_model_name__c != null
                order by name asc
        ];
        return products;
    }
}