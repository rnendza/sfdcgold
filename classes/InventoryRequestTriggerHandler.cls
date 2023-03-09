public with sharing class InventoryRequestTriggerHandler {

    public static final String      PO_FULFILLED_STATUS = 'PO Fulfilled';
    public static final String      PO_PARTIALLY_FULFILLED_STATUS = 'PO Partially Fulfilled';
    public static final String      PO_SUBMITTED_STATUS = 'PO Submitted';
    public static final Set<String> NOT_APPROVED_STATUSES = new Set<String>{ 'Open', PO_SUBMITTED_STATUS } ;

    /**
     * IMPLICIT!
     *
     * @param mOldIrs
     * @param mNewIrs
     *
     * @return
     */
    public static List<Inventory_Request__c> updateIrStatus ( Map<Id,Inventory_Request__c> mOldIrs,
                                                             Map<Id,Inventory_Request__c> mNewIrs ) {

        List<Inventory_Request__c> irsUpdated = new List<Inventory_Request__c>();

        for ( Inventory_Request__c newIr : mNewIrs.values() ) {
            Inventory_Request__c oldIr  = mOldIrs.get(newIr.Id);

            if( newIr.Total_Nbr_of_Assets_Created__c != oldIr.Total_Nbr_of_Assets_Created__c ) {
                if( newIr.Total_Nbr_of_Assets_Created__c == newIr.Total_Qty_Requested__c ) {
                    newIr.Status__c = PO_FULFILLED_STATUS;
                } else if ( newIr.Total_Nbr_of_Assets_Created__c > 0 ) {
                    newIr.Status__c = PO_PARTIALLY_FULFILLED_STATUS;
                } else  {
                    if(newIr.PO_Submitted_Date__c != null && newIr.Status__c != PO_SUBMITTED_STATUS) {
                        newIr.Status__c = PO_SUBMITTED_STATUS;
                    }
                }
                irsUpdated.add(newIr);
            }
        }
        return irsUpdated;
    }

    public static List<Inventory_Request__c> updateFinalApprovedIndicator ( Map<Id,Inventory_Request__c> mOldIrs,
            Map<Id,Inventory_Request__c> mNewIrs ) {

        List<Inventory_Request__c> irsUpdated = new List<Inventory_Request__c>();

        for ( Inventory_Request__c newIr : mNewIrs.values() ) {
            Inventory_Request__c oldIr  = mOldIrs.get(newIr.Id);
            if( newIr.Status__c != oldIr.Status__c ) {
                irsUpdated.add(newIr);
            }
        }
        return irsUpdated;
    }
}