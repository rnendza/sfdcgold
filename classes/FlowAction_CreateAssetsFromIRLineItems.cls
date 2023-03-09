public with sharing class FlowAction_CreateAssetsFromIRLineItems {

    /**
     *
     * @param irLineItemIds
     * @return
     */
    @InvocableMethod
    (       Label='Create Assets from Inventory Request Line Item'
            Description='Returns a CreateAssetResult object containing a variety of result data.')
    public static List<CreateAssetsResult> createAssetsFromInventoryRequestLineItem(List<String> irLineItemIds) {
        String rtName = 'Software';
        String irLineItemId;  //  There will only be 1 line item.
        CreateAssetsResult createAssetsResult = new CreateAssetsResult();
        List<CreateAssetsResult> createAssetsResults = new List<CreateAssetsResult>();
        createAssetsResult.techMsg += 'irLineItemIds param passed='+irLineItemIds;
        if(!irLineItemIds.isEmpty()) {
            irLineItemId = irLineItemIds[0];
            Inventory_Request_Line_Item__c irLineItem = InventoryRequestSvc.retrieveInventoryRequestLineItem(irLineItemId);
            if(irLineItem != null) {
                List<Asset> assetsInserted;
                try {
                    assetsInserted = InventoryRequestSvc.insertAssetsFromIrLineItem(irLineItem, rtName);
                    System.debug('----> Assets inserted= '+assetsInserted.size());
                    createAssetsResult = checkIfWeShouldLockIr(assetsInserted,createAssetsResult,irLineItem.Inventory_Request__c);
                    System.debug('----> Assets inserted= '+assetsInserted.size());
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, e);
                    createAssetsResult.errorMsg = e.getMessage();
                    System.debug('----> Exception on create assetsAssets  '+e);
                }
                if (assetsInserted != null) {
                    createAssetsResult.iNumAssetsCreated = assetsInserted.size();
                    createAssetsResult.techMsg = 'asset rt='+rtName+'..irLineItemCopied='+irLineItem;
                    irLineItem.Received_Quantity__c = 0;
                    if(irLineItem.Number_of_Assets_Created__c == null) {
                        irLineItem.Number_of_Assets_Created__c = createAssetsResult.iNumAssetsCreated;
                    } else {
                        irLineItem.Number_of_Assets_Created__c += createAssetsResult.iNumAssetsCreated;
                    }
                    update irLineItem;
                    createAssetsResult.success = true;
                }
            } else {
                createAssetsResult.errorMsg = 'There was an issue finding the inventory request line item for parameter irLineItemId='+irLineItemId;
                createAssetsResult.techMsg = 'could not find inventory request line item record for passed param irLineItemsIds:'+irLineItemIds;
            }
            createAssetsResults.add(createAssetsResult);
        } else {
            createAssetsResult.errorMsg = 'Invalid irLineItemIds parameter passed: '+irLineItemIds;
            createAssetsResults.add(createAssetsResult);
        }
        return createAssetsResults;
    }
    /**
     *
     *
     * @param assetsInserted
     * @param createAssetsResult
     * @param irId
     *
     * @return
     */
    public static CreateAssetsResult checkIfWeShouldLockIr( List<Asset> assetsInserted,
                                                            CreateAssetsResult createAssetsResult,
                                                            Id irId) {
        if(assetsInserted != null && assetsInserted.size() > 0) {
            Inventory_Request__c ir = InventoryRequestSvc.retrieveInventoryRequestAndLineItems(irId);
            if(ir.Status__c == 'PO Fulfilled') {
                List<Database.Error> errors = InventoryRequestSvc.lockInventoryRequest(ir.Id);
                if(errors != null && !errors.isEmpty()) {
                    createAssetsResult.errorMsg += 'There was a problem Locking the request: ';
//                    for(Database.Error error : errors) {
//                        createAssetsResult.errorMsg += error.getMessage();
//                        createAssetsResult.errorMsg += '.. fields affected: ' + error.getFields();
//                    }
                }
            }
        }
        return createAssetsResult;
    }
    /**
     * Wrapper class to return a number of different variables to teh invoking process.
     */
    public class CreateAssetsResult {
        @InvocableVariable  public Boolean success = false;
        @InvocableVariable  public String  errorMsg = '';
        @InvocableVariable  public String  techMsg = '';
        @InvocableVariable  public Integer iNumAssetsCreated = 0;
        @InvocableVariable  public String  irLineItemId = '';
    }
}