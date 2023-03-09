/**
  * All General operations on Inventory_Request__c and associated Inventory_Request_Line_Item__c should go here.
 */
public with sharing class InventoryRequestSvc {

    /**
     * Retrieves and Inventory Request and it's associated line items.
     *
     * @param irId   The Inventory_Request__c Id.
     * @return       an Inventory_Request__c sObject and it's Inventory_Request_Line_Item__c sObjects if found,
     *               otherwise null.
     */
    public static Inventory_Request__c retrieveInventoryRequestAndLineItems( Id irId ) {
        Inventory_Request__c inventoryRequest;

        List<Inventory_Request__c> inventoryRequests = [
                SELECT  Id,Name,Number_of_Items__c,Status__c,Account__c,Parent_Asset__c,
                        PO_Number__c,IR_Approved_Date__c,PO_Submitted_Date__c,Submitted_Date__c,
                        ByPass_Validation_Rules__c,Final_Approved_Indicator__c,
                        (   SELECT  Id,Name,Item_Number__c,Product__c,Product__r.Name,Product__r.Vendor_ID__c,
                                    Quantity__c,Received_Date__c,Qty_of_assets_to_create__c, Received_Quantity__c,
                                    All_Line_Assets_Created__c,Number_of_Assets_Created__c,Vendor__c,
                                    Vendor__r.Name , Manufacturer__c, Product__r.Manufacturer__r.Name,
                                    Product__r.Description
                            FROM    Inventory_Request_Line_Items__r )
                FROM    Inventory_Request__c
                WHERE   Id = :irId
        ];
        if(!inventoryRequests.isEmpty()) {
            inventoryRequest = inventoryRequests[0];
        }
        return inventoryRequest;
    }
    /**
     * Retrieves a single Inventory_Request_Line_Item__c sObject
     *
     * @param irLineId The Inventory_Request_Line_Item.Id
     * @return a fully populated Inventory_Request_Line_Item__c sObject along with a number of parent fields.
     */
    public static Inventory_Request_Line_Item__c retrieveInventoryRequestLineItem(Id irLineId) {
        Inventory_Request_Line_Item__c inventoryRequestLineItem;

        List<Inventory_Request_Line_Item__c> inventoryRequestLineItems = [
                SELECT  Id,Name,Item_Number__c,Product__c,Product__r.Name,Product__r.Vendor_ID__c,Product__r.Description,
                        Quantity__c,Received_Date__c,Number_of_Assets_Created__c,Eligible_to_Create_Assets__c,
                        All_Line_Assets_Created__c,Qty_of_assets_to_create__c,Vendor__c,Vendor__r.Name,
                        Manufacturer__c, Product__r.Manufacturer__r.Name,Received_Quantity__c,
                        Inventory_Request__c,Inventory_Request__r.Parent_Asset__c,Inventory_Request__r.Account__c,
                        Inventory_Request__r.Account__r.Name,Inventory_Request__r.PO_Number__c,
                        Inventory_Request__r.IR_Approved_Date__c,Inventory_Request__r.PO_Submitted_Date__c,
                        Inventory_Request__r.Submitted_Date__c,Inventory_Request__r.Status__c,
                        Inventory_Request__r.ByPass_Validation_Rules__c,Inventory_Request__r.Final_Approved_Indicator__c
                FROM    Inventory_Request_Line_Item__c
                WHERE   Id = :irLineId
        ];
        if(!inventoryRequestLineItems.isEmpty()) {
            inventoryRequestLineItem = inventoryRequestLineItems[0];
        }
        return inventoryRequestLineItem;
    }

    /**
     * Inserts a list of assets based on Inventory_Request_Line_Item.Qty_of_assets_to_create__c.
     * Will also attempt to lock the Parent IR if all assets have been created for all line items.
     * Finally will attempt to update the unique serial number counter to the latest (stored in a custom setting).
     *
     * @param irLineItemId  The Inventory_Request_Line_Item__c Id.
     * @return A List of Created Asset sObjects
     */
    public static List<Asset> insertAssetsFromIrLineItem(   Inventory_Request_Line_Item__c irLineItem,
                                                            String recordTypeName) {
        List<Asset> assetsInserted = new List<Asset>();
        if(irLineItem != null) {
            Id assetSoftwareRtId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
            //Software_Assets_Config__c configSettings = CustomSettingsSvc.getSoftwareAssetsConfigSettings(UserInfo.getUserId());
            Software_Assets_Config__c configSettings = Software_Assets_Config__c.getOrgDefaults();
            Decimal serialNumber = configSettings.Latest_Serial_Number__c;
            for(Integer i = 0; i < irLineItem.Qty_of_assets_to_create__c; i++) {
                serialNumber += 1;
                Asset asset = new Asset( RecordTypeId = assetSoftwareRtId);
                asset.Name = irLineItem.Product__r.Name;/* + ' '  configSettings.Asset_Name_Prefix__c + serialNumber ;*/
               //------> asset.Description = irLineItem.Product__r.Description;
                asset.Item_Content__c = irLineItem.Product__r.Description;
                asset.SerialNumber = configSettings.Asset_Name_Prefix__c + String.valueOf(serialNumber);
                asset.Product2Id = irLineItem.Product__c;
                asset.Product2Id = irLineItem.Product__c;
                asset.Vendor__c = irLineItem.Vendor__c;
                asset.Quantity = 1;
                asset.ParentId = irLineItem.Inventory_Request__r.Parent_Asset__c;
                asset.AccountId = irLineItem.Inventory_Request__r.Account__c;
                asset.DBA_Text__c = irLineItem.Inventory_Request__r.Account__r.Name;
                asset.InstallDate = irLineItem.Received_Date__c;
                asset.Date_Delivered__c = irLineItem.Received_Date__c;
                asset.Purchase_Order_Number__c = irLineItem.Inventory_Request__r.PO_Number__c;
                asset.Inventory_Request__c = irLineItem.Inventory_Request__c;
                asset.Inventory_Request_Line_Item__c = irLineItem.Id;
               //---- asset.Software_Upgraded_Date__c = Date.today();
                asset.Status = 'Available';
                assetsInserted.add(asset);
            }
            insert assetsInserted;
            if(shouldIrBeLocked(irLineItem)) {
                List<Database.Error> errors = lockInventoryRequest(irLineItem.Inventory_Request__c);
            }
            configSettings.Latest_Serial_Number__c = serialNumber;
            //@TODO double check this auto incrementer
            //configSettings = [SELECT Id,Name,Latest_Serial_Number__c  FROM Software_Assets_Config__c WHERE SetupOwnerId = :UserInfo.getUserId()];
            upsert configSettings;
        }
        return assetsInserted;
    }
    /**
     * Gets the IR Request Progress Settings meta-data for use with the 'path'.
     *
     * @param devName   The developername of the custom metadata type.
     * @return a List of Inventory_Request_Progress_Indicator__mdt meta sta types.
     *
     * @todo move to CustomMetadataSvc
     */
    public static List <Inventory_Request_Progress_Indicators__mdt> retrieveInventoryRequestProgressSettingsMeta
                                                                                                (String devName) {
        List<Inventory_Request_Progress_Indicators__mdt> settings;
        String soql = '';
        soql += ' SELECT  Id, DeveloperName, MasterLabel, Order__c, Value__c,DisplayValue__c,Description__c,';
        soql += '         Current__c ';
        soql += ' FROM    Inventory_Request_Progress_Indicators__mdt ';
        if (devName != null) {
            soql += ' WHERE DeveloperName = :devName ';
        }
        soql += ' ORDER BY Order__c ASC ';
        settings = (List<Inventory_Request_Progress_Indicators__mdt>) Database.query(soql);
        return settings;
    }
    /**
     * Determines if an inventory request should be locked (ie. is it a status of 'PO Fulfilled'.
     *
     * @param inventoryRequestLineItem  The inventory request line item sObject to eval.
     * @return                          True if it should be locked, otherwise false.
     */
    public static Boolean shouldIrBeLocked(Inventory_Request_Line_Item__c inventoryRequestLineItem) {
        Boolean lockIt = false;
        if(inventoryRequestLineItem.Inventory_Request__r.Status__c == 'PO Fulfilled') {
            lockIt = true;
        }
        return lockIt;
    }
    /**
     * Lock's the Inventory Request (via Approval.lock)
     *
     * @param inventoryRequestId The Id of the Inventory_Request__c.
     * @return A List of Database.Error objects if an Error, otherwise an empty list.
     */
    public static List<DataBase.Error> lockInventoryRequest(Id inventoryRequestId) {
        List<Database.Error> errors = new List<Database.Error>();
        try {
            Approval.LockResult alr = Approval.lock(inventoryRequestId);
            if (!alr.isSuccess()) {
                for (Database.Error err : alr.getErrors()) {
                    errors.add(err);
                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                }
            }
        } catch (System.NoAccessException nae) {
             System.debug(LoggingLevel.ERROR,nae);
        }
        return errors;
    }

    /**
     * Determine if the Inventory request is locked (via Approval.isLocked)
     *
     * @param inventoryRequestId    The Inventory_Request__c id.
     * @return                      True if it is locked, otherwise false. 
     */
    public static Boolean checkIfIrIsLocked(Id inventoryRequestId) {
        Boolean success = false;
        try {
            success = Approval.isLocked(inventoryRequestId);
        } catch (System.NoAccessException nae) {
            System.debug(LoggingLevel.ERROR, nae);
        }
        return success;
    }
}