/**
 * Main UI Controller backing Inventory_Request__c and Inventory_Request_Line_Item__c components.
 */
public without sharing class InventoryRequestController {

    public final static String MAP_KEY_SW_ASSET_CONFIG_SETTING  = 'SW_ASSET_CONFIG';
    public final static String MAP_KEY_IR_LINE                  = 'MAP_KEY_IR_LINE';
    public final static String MAP_KEY_IR_LINES                 = 'MAP_KEY_IR_LINES'; //@TODO deprecate
    public final static String MAP_KEY_CREATE_ASSET_PERMISSION  = 'MAP_KEY_CREATE_ASSET_PERMISSION';
    public final static String MAP_KEY_PROGRESS_INDICATORS      = 'MAP_KEY_PROGRESS_INDICATORS';
    public final static String MAP_KEY_PARENT_STATUS_IND        = 'MAP_KEY_PARENT_STATUS_IND';
    public final static String MAP_KEY_ACCOUNTS                 = 'MAP_KEY_ACCOUNTS';
    public final static String MAP_KEY_ASSETS                   = 'MAP_KEY_ASSETS';

   /**
    * Retrieve an Inventory_Request__c and child Inventory_Request_Line_Item__c record(s).
    *
    * @param irId  The SFDC Id of the Inventory_Request__c.
    * @return a dto containing the Inventory_Request__c and child array of Inventory_Request_Line_Item__c {dto.sObj}
    *         also a map keyed by SW_ASSET_CONFIG returning custom settings.
    *
    * @TODO deprecate in favor of line by line processing.
    */
    @AuraEnabled
    public static ResponseDto retrieveInventoryRequestAndLineItems( Id irId ) {
        ResponseDto dto = new ResponseDto();
        Inventory_Request__c ir = InventoryRequestSvc.retrieveInventoryRequestAndLineItems(irId);
        List<Inventory_Request_Line_Item__c> irLines = new List<Inventory_Request_Line_Item__c>();
        Software_Assets_Config__c configSettings = CustomSettingsSvc.getSoftwareAssetsConfigSettings(UserInfo.getUserId());
        if(ir != null) {
            dto.sObj = ir;
            //------------- deconstruct child related recs for easier client consumption.
            if(ir.Inventory_Request_Line_Items__r != null && !ir.Inventory_Request_Line_Items__r.isEmpty()) {
                for (Inventory_Request_Line_Item__c li: ir.Inventory_Request_Line_Items__r) {
                    irLines.add(li);
                }
            }
            dto.values.put(MAP_KEY_SW_ASSET_CONFIG_SETTING,configSettings);
            dto.values.put(MAP_KEY_IR_LINES,irLines);
            dto.isSuccess = true;
        }
        return dto;
    }
   /**
    * Retrieve an Inventory_Request_Line_Item__c record.
    *
    * @param irLineItemId The SFDC Id of the Inventory_Request_Line_Item__c.
    * @return a dto containing the Inventory_Request_Line_Item {dto.sObj}
    *         also a map keyed by SW_ASSET_CONFIG returning custom settings.
    */
    @AuraEnabled
    public static ResponseDto retrieveInventoryRequestLineItem( Id irLineItemId ) {
        ResponseDto dto = new ResponseDto();
        Inventory_Request_Line_Item__c irLineItem = InventoryRequestSvc.retrieveInventoryRequestLineItem( irLineItemId );
        Software_Assets_Config__c configSettings = CustomSettingsSvc.getSoftwareAssetsConfigSettings(UserInfo.getUserId());
        if(irLineItemId != null) {
            dto.sObj = irLineItem;
            dto.values.put(MAP_KEY_SW_ASSET_CONFIG_SETTING,configSettings);
            dto.isSuccess = true;
        }
        return dto;
    }

   /**
    * Checks Custom Permissions based on the custom permission api name.
    *
    * @param customPermissionApiName  the custom permission api name to check.
    * @return   TRUE if the user has permission, otherwise false.
    */
    @AuraEnabled
    public static Boolean doesUserHavePermission( String customPermissionApiName ) {
        Boolean hasPermission = FeatureManagement.checkPermission(customPermissionApiName);
        return hasPermission;
    }

    /**
     * Determines if the Line Item has assets associated with it.
     *
     * @param irLineItemId The SFDC Id of the Inventory_Request_Line_Item__c4
     * @return TRUE if the line item has assets, otherwise FALSE.
     */
    @AuraEnabled
    public static Boolean doesIrLineItemHaveAssets(  Id irLineItemId  ) {
        List<Asset> assets = [SELECT Id FROM Asset WHERE Inventory_Request_Line_Item__c = :irLineItemId];
        return !assets.isEmpty();
    }

    /**
     * Retrieves a Profile based on the running user Profile Id.
     * @return  a Profile sObject if found, otherwise null.
     */
    @AuraEnabled
    public static Profile retrieveUserProfile() {
        return UserSvc.retrieveUserProfileById( UserInfo.getProfileId() );
    }

    /**
     * Retrieves a RecordType sObject for a given recordTypeId.
     *
     * @param rtId  The recordTypeId to search for.
     * @return  a dto containing a RecordType sObject in the dto.sObj property
     * @TODO Move up to a Service.
     */
    @AuraEnabled
    public static ResponseDto retrieveRecordTypeViaId(String rtId) {
        ResponseDto dto = new ResponseDto();

        RecordType recordType;
        List<RecordType> recordTypes = [
                SELECT  Id, Name, DeveloperName
                FROM    RecordType
                WHERE   Id = :rtId
        ];
        if(!recordTypes.isEmpty()) {
            recordType = recordTypes[0];
            dto.sObj = recordType;
            dto.isSuccess = true;
        } else {
            dto.message = 'Could not find a valid record type for Inventory Request';
            dto.technicalMsg = 'No RT find for passed rtId ='+rtId;
        }
        return dto;
    }

    /**
     * Deletes assets associated with the Inventory_Request_Line_Item__c
     *
     * @param irLineItemId  An Inventory_Request_Line_Item__c Id.
     * @return              A ResponseDto object containing the status of the asset deletion
     *
     * @todo failsafe the delete!
     */
    @AuraEnabled
    public static ResponseDto deleteIrLineItemAssets(Id irLineItemId) {
        ResponseDto dto = new ResponseDto();

        List<Asset> assets = [SELECT Id FROM Asset WHERE Inventory_Request_Line_Item__c = :irLineItemId];
        Integer iNum = assets.size();
        if (!assets.isEmpty()) {
            delete assets;
            dto.message = iNum + ' assets deleted successfully!';
            dto.isSuccess = true;
        } else {
            dto.message = 'No Assets Found for Inventory Request Line Item to Delete';
            dto.technicalMsg = 'No Assets found for ir Line Item Id:'+irLineItemId;
        }
        return dto;
    }

    /**
     * If criteria of Line.Eligible_To_Create_Assets__c (Formula field) is not meant.. updates whatever is needed
     * to be updated (parent or child item item).
     *
     * @param irLineItemId  An Inventory_Request_Line_Item__c Id.
     * @return              A ResponseDto object containing the status of the update of the IR header and line.
     */
    @AuraEnabled
    public static ResponseDto makeIrLineEligibleToCreateAssets(Id irLineItemId) {

        ResponseDto dto = new ResponseDto();

        Inventory_Request_Line_Item__c irLine = InventoryRequestSvc.retrieveInventoryRequestLineItem(irLineItemId);
        Inventory_Request__c ir = InventoryRequestSvc.retrieveInventoryRequestAndLineItems(irLine.Inventory_Request__c);

        dto.message = 'Nothing done';
        if(irLine != null && ir != null) {
            if(ir.PO_Number__c == null) {
                ir.PO_Number__c = '666666';
            }
            if(ir.PO_Submitted_Date__c == null) {
                ir.PO_Submitted_Date__c = Date.today();
            }
            if(ir.Submitted_Date__c == null) {
                ir.Submitted_Date__c = Date.today();
            }
            if(ir.Status__c != 'Approved for PO') {
                ir.Status__c = 'Approved for PO';
            } else if(ir.IR_Approved_Date__c == null) {
                ir.IR_Approved_Date__c = Date.today();
            }
            update ir;
            if(irLine.Received_Date__c == null) {
                irLine.Received_Date__c = Date.today();
            }
            update irLine;
            dto.isSuccess = true;
            dto.message = 'IR / IR Lines successfully updated to allow asset creation.';
        } else {
            dto.message = 'idpassed='+irLineItemId+'..ir line='+ir +'.. irLineItem='+ir;
        }
        return dto;
    }

    /**
     * If criteria of Line.Eligible_To_Create_Assets__c (Formula field) is not meant.. updates whatever is needed
     * to be updated (parent or child item item).
     *
     * @param irLineItemId  An Inventory_Request_Line_Item__c Id.
     * @return              A ResponseDto object containing the status of the update of the IR Line.
     */
    @AuraEnabled
    public static ResponseDto makeIrLineInEligibleToCreateAssets(Id irLineItemId) {

        ResponseDto dto = new ResponseDto();

        Inventory_Request_Line_Item__c irLine = InventoryRequestSvc.retrieveInventoryRequestLineItem(irLineItemId);
        dto.message = 'Nothing done';
        if(irLine != null ) {
            irLine.Received_Date__c = null;
           // irLine.Manufacturer__c = null;
            update irLine;
            dto.isSuccess = true;
            dto.message = 'Received date Nullified on Line Item to make it ineligible to create assets..';
        } else {
            dto.message = 'idpassed='+irLineItemId+'..ir line='+irLine;
        }
        return dto;
    }

    /**
     * Retrieves a list of accounts for the given where criteria. .
     *
     * @param whereCriteria the where criteria for Account ie. RecordType.Developername = 'xyz
     * @return a dto containing a list of accounts in the values property.
     */
    @AuraEnabled
    public static ResponseDto retrieveAccountsForIrSelection(String whereCriteria) {
        List<Account> accounts;
        if(whereCriteria == null || whereCriteria == '') {
            //@todo dyna rt ret.
            whereCriteria = ' RecordType.Developername = \'Warehouse\'';
        }
        ResponseDto dto = new ResponseDto();

        String soql = '';
        soql += ' SELECT    Id, Name ';
        soql += ' FROM      Account ';
        soql += ' WHERE ' + whereCriteria;
        soql += ' ORDER BY Name ASC ';
        soql += ' LIMIT 500 ';

        try {
            accounts = Database.query(soql);
            if(!accounts.isEmpty()) {
                dto.isSuccess = true;
            } else {
                dto.message = 'No accounts found';
                dto.technicalMsg = 'empty list found for accounts with where criteria = '+whereCriteria;
            }
        } catch (Exception ex) {
            dto.technicalMsg = ex.getMessage();
            dto.message = 'Unable to locate accounts for selection. probably invalid whereCriteria=' + whereCriteria;
        }
        dto.values.put(MAP_KEY_ACCOUNTS,accounts);
        return dto;
    }

    /**
     * Retrieves a list of assets for the given where criteria. .
     *
     * @param whereCriteria the where criteria for Asset ie. RecordType.Developername = 'xyz currently not used.
     * @return a dto containing a list of assets in the values property.
     */
    @AuraEnabled
    public static ResponseDto retrieveParentAssetsForIrSelection(String whereCriteria) {
        List<Asset> assets;
        String parentAssetCriteria = ' Software_Type__c = \'Parent Asset\' ';

        if(whereCriteria == null || whereCriteria == '') {
            //@todo dyna rt ret.
            whereCriteria = parentAssetCriteria;
        }

        ResponseDto dto = new ResponseDto();

        String soql = '';
        soql += ' SELECT    Id, Name ';
        soql += ' FROM      Asset ';
        soql += ' WHERE ' + whereCriteria;
        soql += ' ORDER BY Name ASC ';
        soql += ' LIMIT 500 ';


        try {
            assets = Database.query(soql);
            if(!assets.isEmpty()) {
                dto.isSuccess = true;
            } else {
                dto.message = 'No assets found';
                dto.technicalMsg = 'empty list found for assets with where criteria = '+parentAssetCriteria;
            }
        } catch (Exception ex) {
            dto.technicalMsg = ex.getMessage();
            dto.message = 'Unable to locate assets for selection. probably invalid whereCriteria=' + parentAssetCriteria;
        }
        dto.values.put(MAP_KEY_ASSETS,assets);
        return dto;
    }

    /**
     * Retrieves the Inventory_Request_Progress_Indicators__mdt custom metadata which is basically a list of
     * Inventory_Request__c.Status__c with each Picklist option containing additional meta data.
     *
     * @param inventoryRequestId
     * @return a ResponseDto object containing a list of ProgressIndicator keys by MAP_KEY_PROGRESS_INDICATORS
     * @see ProgressIndicator
     */
    @AuraEnabled
    public static ResponseDto retrieveIrProgressIndicators(Id inventoryRequestId) {
        ResponseDto dto = new ResponseDto();

        List<ProgressIndicator> progressIndicators = new List<ProgressIndicator>();
        List <Inventory_Request_Progress_Indicators__mdt> settings =
                InventoryRequestSvc.retrieveInventoryRequestProgressSettingsMeta(null );
        if(settings != null) {
            for(Inventory_Request_Progress_Indicators__mdt setting : settings) {
                ProgressIndicator pi = new ProgressIndicator();
                pi.value = setting.Value__c;
                pi.displayValue = setting.DisplayValue__c;
                if(setting.Description__c != null) {
                    pi.description = setting.Description__c;
                }
                pi.order = Integer.valueOf(setting.Order__c);
                pi.current = setting.Current__c;
                progressIndicators.add(pi);
            }
            dto.values.put( MAP_KEY_PROGRESS_INDICATORS,progressIndicators );
            Boolean isLocked = InventoryRequestSvc.checkIfIrIsLocked(inventoryRequestId);
            ParentStatusIndicator psi = new ParentStatusIndicator();
            psi.isLocked = isLocked;
            dto.values.put( MAP_KEY_PARENT_STATUS_IND, psi);

            dto.isSuccess = true;
        }
        return dto;
    }

    /**
     * A nested class to wrap Inventory_Request_Progress_Indicators__mdt
     */
    public class ProgressIndicator {
        @AuraEnabled public String  value               { get;set; }
        @AuraEnabled public String  displayValue        { get;set; }
        @AuraEnabled public String  description         { get;set; }
        @AuraEnabled public Integer order               { get;set; }
        @AuraEnabled public Boolean current             { get;set; }
        @AuraEnabled public Boolean completed           { get;set; }
        @AuraEnabled public String  textClass           { get;set; } //  css class of the  display value and the desc.
        @AuraEnabled public String  valueContainerClass { get;set; } //  css class of value container ie. parent div.

        /**
         *  No arg constructor.. not setting empty string so the platform will return in the JSON.
         */
        public ProgressIndicator() {
            this.description = '';
            this.completed = false;
            this.current = false;
            this.textClass = '';
            this.valueContainerClass = '';
        }
    }

    /**
     *  An Inner class holding locked status of the parent IR for display in the progress indicator
     */
    public class ParentStatusIndicator {
        @AuraEnabled public Boolean isLocked          { get;set; }
        public ParentStatusIndicator() {
            this.isLocked = false;
        }
    }
}