public with sharing class PoSvc {

    /**
     * Retrieves a Purchase Order for a given po Id.
     *
     * @param poId
     * @return a Purchase_Order__c sObject
     */
    public static Purchase_Order__c retrievePo( Id poId ) {
        Purchase_Order__c po;
        List<Purchase_Order__c> pos = [ SELECT  Id, Quantity__c,Cost__c,Description__c,Name__c,Price__c,Product__c,
                                                Product_Description__c,Purchase_Order__c,Name,Quantity_of_Software_Created__c,
                                                Status__c
                                        FROM    Purchase_Order__c
                                        WHERE   Id = :poId ];
        if(!pos.isEmpty()) {
            po = pos[0];
        }
        return po;
    }
    /**
     * Retrieve all child line items for a given purchase order.
     * @param poId  The Parent Purchase_Order__c Id.
     * @return a list of PO Item for the parent Id.
     */
    public static List<Purchase_Order_Item__c> retrievePoItems( Id poId ) {
        List<Purchase_Order_Item__c> poItems = [
                SELECT Id, Name, Item__c, Quantity__c, Product__c
                FROM Purchase_Order_Item__c
                WHERE Purchase_Order__c = :poId
        ];
        return poItems;
    }
}