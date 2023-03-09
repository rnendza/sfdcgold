import {LightningElement,api,wire,track} from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {reduceErrors} from "c/ldsUtils";
import {getConstants} from "c/clConstantUtil";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveAccountAssetData from '@salesforce/apex/AccountAssetsController.retrieveAccountAssetData';
import {uiHelper} from "./accountAssetsListDisplayUiHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_ACCOUNT_ID            = 'ACCOUNT_ID';
const MAP_KEY_ACCOUNT_MACHINE_DATA  = 'ACCOUNT_MACHINE_DATA';
const MOBILE                        = 'Small';
const SUPPRESS_ACCOUNT_FIELDS       = 'none';
const MOBILE_COL_SIZE               = 12;
const DESKTOP_COL_SIZE              = 6;

const assetColumns = [
    {
        label: 'Name',
        fieldName: 'assetLink',
        type: 'url',
        hideDefaultActions: true,
        initialWidth: 95,
        typeAttributes: {label: {fieldName: 'assetName'}, target: '_blank'},
        sortable: true
    },
    {
        label: 'SAS', fieldName: 'assetSas', sortable: true, initialWidth: 75, tooltip: {
            fieldName: 'assetSas'
        }
    },
    {
        label: 'Model', fieldName: 'assetModel', sortable: true, tooltip: {
            fieldName: 'assetModel'
        }
    },
    {
        label: 'Serial #', fieldName: 'assetSerialNumber', sortable: true, initialWidth: 105, tooltip: {
            fieldName: 'assetSerialNumber'
        }
    }
];

//{ label:'Case Number', fieldName: 'caseLink', type: 'url', sortable:true, typeAttributes: {label: {fieldName: 'CaseNumber'}, tooltip:'Go to detail page', target: '_blank'}},



export default class AccountAssetsListDisplay extends NavigationMixin(LightningElement) {

    @api recordId;
    @api cardTitle;
    @api cardIcon;
    @api parentAccountApiName;
    @api showVgtInfoFields;
    @api showRtInfoFields;
    @api showMsgIfNoMachines;
    @api debugConsole;

    @track columns = assetColumns;
    @track pageSizeOptions = [5,10,15];
    @track records;
//    @track dtClasses = 'slds-table_header-fixed_container slds-scrollable_x slds-border_top slds-no-row-hover slds-max-medium-table_stacked slds-table_bordered slds-table_col-bordered';
    @track dtClasses = 'slds-table_header-fixed_container slds-border_top slds-no-row-hover slds-max-medium-table_stacked slds-table_bordered slds-table_col-bordered';

    @api
    set accountFieldsToDisplay( fieldString ) {
        if(fieldString) {
            this._accountFieldsToDisplay = fieldString.split(',');
        }
    }
    get accountFieldsToDisplay() {
        return this._accountFieldsToDisplay;
    };

    @track accountMachineData;
    @track accountId;

    _accountFieldsToDisplay;
    _wiredAccountDto;
    _accelUtils = new AccelUtilsSvc(this.debugConsole);
    _isMachinesLoading;

    constructor(){
        super();
    }

    connectedCallback() {
        if(this.debugConsole) {
            console.info('%c----> /lwc/accountAssetsTileDisplay', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        }
        this.checkRequiredProperties();
    }

    //Called after the component finishes inserting to DOM
    connectedCallback() {
        if(this.debugConsole) {
            console.info('%c----> /lwc/accountAssetsListDisplay', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        }
    }

    /**
     * SFDC can fire the wired call.
     */
    checkRequiredProperties() {
        if(this.recordId && this.parentAccountApiName && this.accountFieldsToDisplay) {
            this._isMachinesLoading = true;
        }
    }

    /**
     * Wired call to the server to get account asset data (object with nested arrays) and basic account info (id).
     * @param wiredDto  Data sent by SFDC in the callback from the server.
     */
    @wire(retrieveAccountAssetData, {   parentRecordId: '$recordId',parentAccountApiName: '$parentAccountApiName'})
    retrieveAccountAssetData(wiredDto) {
        this._wiredAccountDto = wiredDto;
        const { data, error } = this._wiredAccountDto

        if(data) {
            const dto = data;
            let accountMachineData = this._accelUtils.getMapValue(MAP_KEY_ACCOUNT_MACHINE_DATA, dto.values)
            this.records = this.shapeAccountMachineData(accountMachineData);
            this.accountId = this._accelUtils.getMapValue(MAP_KEY_ACCOUNT_ID, dto.values)
            this.debugResults(dto);
            this._isMachinesLoading = false;
        } else if (error) {
            this.processAssetDataError(error);
        }
    }

    /**
     * Simple error handler in order to keep wired call a bit cleaner
     * @param error
     */
    processAssetDataError(error) {
        console.error(JSON.stringify(error));
        this.error = reduceErrors(error);
        console.error('reduced errors',this.error);
        this._isMachinesLoading = false;
        if(this.debugConsole) {
            uiHelper.showToast(this, '', 'Error', this.error);
        }
    }

    /**
     * For future use in case we need to overwrite locked / cacheable data.
     * @param accountMachineData
     */
    shapeAccountMachineData(accountMachineData) {
        this.accountMachineData = accountMachineData;
        let records = [];
        if (accountMachineData && accountMachineData.iNumVgts > 0) {
            console.log('----> list asset data vgt ', JSON.parse(JSON.stringify(accountMachineData.vgtMachines)));
            let tmp = JSON.parse(JSON.stringify(accountMachineData.vgtMachines));
            tmp = this.sortMachines(tmp);
            tmp.forEach(machine => {
                const asset = machine.asset;
                if (asset) {
                    let record = {};
                    record.assetLink = '/' + asset.Id
                    record.assetName = asset.Name;
                    record.assetId = asset.Id;
                    record.assetSas = 'VGT ' +asset.SAS__c;
                    record.assetModel = asset.Model__c;
                    record.assetSerialNumber = asset.SerialNumber;
                    records.push(record);
                }
            });
        }


        if (accountMachineData && accountMachineData.iNumRts > 0) {
            console.log('----> list asset data rts ', JSON.parse(JSON.stringify(accountMachineData.rtMachines)));
            accountMachineData.rtMachines.forEach(machine => {
                const asset = machine.asset;
                if (asset) {
                    let record = {};
                    record.assetLink = '/' + asset.Id
                    record.assetName = asset.Name;
                    record.assetId = asset.Id;
                    record.assetSas = asset.SAS__c;
                    record.assetModel = asset.Model__c;
                    record.assetSerialNumber = asset.SerialNumber;
                    records.push(record);
                }
            });
        }
        return records;
    }

    sortMachines(machines) {
        machines.sort((a, b) => {
            return this.hasSAS(a) && this.hasSAS(b) && (Number(a.asset.SAS__c) < Number(b.asset.SAS__c)) ? -1 : 1;
        });
        return machines;
    }
    hasSAS(machine) {
        return machine && machine.asset && machine.asset.SAS__c;
    }

    get showStencil() {
        return this._isMachinesLoading;
    }
    get showAccountData() {
        return this.accountId && this.accountFieldsToDisplay;
    }
    get showVgtMachines() {
        return this.accountMachineData && this.accountMachineData.vgtMachines;
    }
    get showRtMachines() {
        return this.accountMachineData && this.accountMachineData.rtMachines;
    }
    get showAccountFields() {
        return this.showAccountData && this.accountFieldsToDisplay.length > 0 && this.accountFieldsToDisplay[0] !== SUPPRESS_ACCOUNT_FIELDS;
    }
    get showNoMachineDataMsg() {
        return this.showMsgIfNoMachines && !this.showVgtMachines && !this.showRtMachines;
    }
    get showDatatable() {
        return this.columns && this.records && this.records.length > 0;
    }
    get noMachineDataMsg() {
        let msg = 'No machine data found for ';
        if(this.accountMachineData && this.accountMachineData.account) {
            msg += this.accountMachineData.account.Name;
        } else {
            msg += 'account....'
        }
        msg += '.';
        return msg;
    }
    get assetDtKeyField() {
        return 'assetId';
    }
    get numberOfRecordFormColumns() {
        let numCols = DESKTOP_COL_SIZE
        if(FORM_FACTOR == MOBILE) {
            numCols = MOBILE_COL_SIZE;
        }
        return numCols;
    }
    get totalRecords() {
        return this.records ? this.records.length : 0;
    }
    debugResults(dto) {
        if(this.accountMachineData && this.debugConsole) {
            console.info('-->accountMachineData',JSON.parse(JSON.stringify(this.accountMachineData)));
        }
        if(this.accountId && this.debugConsole) {
            console.info('-->accountId',JSON.parse(JSON.stringify(this.accountId)));
        }
        if(!this.accountId) {
            console.warn('No Account Id found for Asset Retrieval account field='+this.parentAccountApiName);
            if(this.debugConsole) {
                let msg = 'Could not locate the parent account field. Please ensure ' + this.parentAccountApiName
                    + ' exists on the current object or select a different Parent Account Field.';
                uiHelper.showToast(this, 'Contact Administrator', msg, 'error');
            }
        }
        if(dto && !dto.isSuccess) {
            console.warn('dto',JSON.parse(JSON.stringify(dto)));
        }
    }
}