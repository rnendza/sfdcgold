/**
 * AccountAssetsController is the UI backing class for the Accel - Account Assets component.
 */
public with sharing class AccountAssetsController {

    public static final String MAP_KEY_ACCOUNT_MACHINE_DATA     = 'ACCOUNT_MACHINE_DATA';
    public static final String MAP_KEY_ACCOUNT_ID               = 'ACCOUNT_ID';
    public static final String VGT_RT_DEV_NAME                  = 'VGT';
    public static final String RT_RT_DEV_NAME                   = 'Redemption';
    public static final String INFO_STRING                      = 'Info';
    public static final Integer DESKTOP_DATA_COL_SIZE           = 6;
    public static final Integer MOBILE_DATA_COL_SIZE            = 12;

   /**
    * Finds account vgt and rt info and some basic account data.
    *
    * 1. Dynamically pull the account id based on on the parentRecordId and parent record account api field name.
    * 2. Retrieve VGTs and RTs associated with the account.
    * 3. Build a response object suitable for front end display.
    *
    * @param parentRecordId          The record Id of the parent record.
    * @param parentAccountApiName    The parent Account Field Api Name.
    *
    * @return                        A ResponseDto object containing asset data.
    */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAccountAssetData(Id parentRecordId, String parentAccountApiName) {

        ResponseDto dto = new ResponseDto();

        if(parentRecordId != null) {
            Id accountId = retrieveRecordAccountId(parentRecordId, parentAccountApiName);
            dto.technicalMsg += debugParams(accountId, parentRecordId, parentAccountApiName);
            if (accountId != null) {
                List<Asset> accountMachineAssets = AssetSvc.retrieveAccountMachines(accountId);
                dto.isSuccess = !accountMachineAssets.isEmpty();
                buildResponse(accountId, parentRecordId, accountMachineAssets, dto);
            }
        } else {
            dto.severity = 'error';
            dto.message = 'Must provide a parentRecordId param!';
        }
        return dto;
    }

    /**
     * Appends to the DTO an AccountMachinesWrapper object and other high level information.
     *
     * @param accountId             The Account.Id value.
     * @param parentRecordId        The Id for the parent record.
     * @param accountMachineAssets  A List of Asset Objects.
     * @param dto                   The response Dto (modified by reference).
     *
     * @see AccountAssetsController.AccountMachinesWrapper
     */
    @TestVisible
    private static void buildResponse( Id accountId,Id parentRecordId,List<Asset> accountMachineAssets,ResponseDto dto) {

        AccountMachinesWrapper accountMachinesWrapper;

        if(!accountMachineAssets.isEmpty()) {
            accountMachinesWrapper = new AccountMachinesWrapper(accountMachineAssets);
            accountMachinesWrapper.sObjectApiName =  parentRecordId.getSobjectType().getDescribe().getName();
            accountMachinesWrapper.sObjectLabel   =  parentRecordId.getSobjectType().getDescribe().getLabel();
        } else {
            accountMachinesWrapper = new AccountMachinesWrapper();
        }
        accountMachinesWrapper.account = retrieveAccount(accountId);
        dto.values.put(MAP_KEY_ACCOUNT_MACHINE_DATA,accountMachinesWrapper);
        dto.values.put(MAP_KEY_ACCOUNT_ID,accountId);
    }

    /**
     *  A wrapper class breaking apart VGT Machines and RT Machines.
     */
    public class AccountMachinesWrapper {

        @AuraEnabled public Account account;
        @AuraEnabled public List<MachineWrapper> vgtMachines;
        @AuraEnabled public List<MachineWrapper> rtMachines;
        @AuraEnabled public Integer iNumVgts = 0;
        @AuraEnabled public Integer iNumRts = 0;
        @AuraEnabled public Integer rtDataColSize = DESKTOP_DATA_COL_SIZE;
        @AuraEnabled public String sObjectApiName;
        @AuraEnabled public String sObjectLabel;

        public AccountMachinesWrapper() {}

        public AccountMachinesWrapper(List<Asset> assets) {

            this.vgtMachines = new List<MachineWrapper>();
            this.rtMachines = new List<MachineWrapper>();

            for(Asset asset : assets) {
                MachineWrapper mWrapper = new MachineWrapper(asset);
                if(asset.RecordType.DeveloperName == VGT_RT_DEV_NAME) {
                    vgtMachines.add(mWrapper);
                    iNumVgts++;
                } else if (asset.RecordType.DeveloperName == RT_RT_DEV_NAME) {
                    rtMachines.add(mWrapper);
                    iNumRts++;
                }
            }
            if(this.iNumRts == 1) {
                this.rtDataColSize = MOBILE_DATA_COL_SIZE;
            }
        }
    }

    /**
     * A Wrapper around on Asset to assist with label display
     */
    public class MachineWrapper {

        @AuraEnabled public Asset asset;
        @AuraEnabled public String label;
        @AuraEnabled public String infoLabel;
        @AuraEnabled public Boolean dupSas;
        @AuraEnabled public String assetName;
        @AuraEnabled public String assetVgtInfo;
        @AuraEnabled public String assetRtInfo;
        @AuraEnabled public String assetLinkHoverTitle;

        public MachineWrapper(Asset asset) {

            this.asset = asset;

            if(asset.RecordType.DeveloperName == VGT_RT_DEV_NAME) {
                this.label = VGT_RT_DEV_NAME+' '+asset.SAS__c;
                this.assetName = this.asset.Name;
                this.assetVgtInfo = asset.Current_Info__c;
                this.infoLabel = this.label + ' '+INFO_STRING;
            } else if (asset.RecordType.DeveloperName == RT_RT_DEV_NAME) {
                this.label = asset.SAS__c;
                this.infoLabel = this.label + ' '+ INFO_STRING;
                this.assetName = this.asset.Name;
                this.assetRtInfo = asset.Current_Info__c;
            }
            if(this.asset != null) {
                this.assetLinkHoverTitle = 'Navigate to the record page for '+this.assetName + '.';
            }
        }
    }

    /**
     * Find the Account Record ID based on the api field name passed (parentgApiName) and determine
     * the type of sObject based on the parentRecordId.
     *
     * @param parentRecordId The Sobject.Id of the parent record.
     * @param parentApiName  The Api Name of the parent record to look for the account Id value.
     *
     * @return               The Id of the account.
     *
     * @implNotes            This will intentionally through an aura error back to the client
     *                       if parentApiName is not found on the sObject type associated
     *                       with the Id and the error should be handled on the client!
     */
    @TestVisible
    private static Id retrieveRecordAccountId(Id parentRecordId, String parentApiName) {

        Id accountId;

        String sObjectApiName = parentRecordId.getSobjectType().getDescribe().getName();
        String soql = '';
        soql += ' SELECT Id,'+parentApiName;
        soql += ' FROM  ' + sObjectApiName;
        soql += ' WHERE Id = :parentRecordId';

        List<SObject> sObjects = Database.query(soql);
        if(!sObjects.isEmpty()) {
            SObject sObj = sObjects[0];
            accountId = (Id)sObj.get(parentApiName);
        }
        return accountId;
    }

    /**
     * @param accountId The Account.Id value.
     * @return          An  Account sObject.
     *
     * @todo move to AccountSvc
     */
    private static Account retrieveAccount(Id accountId) {

        Account account;

        List<Account> accounts = [
                SELECT Id, Name
                FROM   Account
                WHERE  Id = :accountId
        ];
        if(!accounts.isEmpty()) {
            account = accounts[0];
        }
        return account;
    }

    /**
     * @param accountId             Account.Id value.
     * @param parentRecordId        The parent Record Id value.
     * @param parentAccountApiName  The parent record field api name to pull the account Id from.
     *
     * @return
     */
    @TestVisible
    private static String debugParams(Id accountId, Id parentRecordId, String parentAccountApiName) {

        String msg = 'parent record id param='+parentRecordId
                + '... parentAccountApiNameParam ='+parentAccountApiName
                + '... accountId found='+accountId;
        return msg;
    }
}