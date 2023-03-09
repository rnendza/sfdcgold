import {LightningElement,api,wire,track} from 'lwc';

import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';
import {reduceErrors} from "c/ldsUtils";
import {getConstants} from "c/clConstantUtil";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveAccountAssetData from '@salesforce/apex/AccountAssetsController.retrieveAccountAssetData';
import {uiHelper} from "./accountAssetsTileDisplayUiHelper";

const GLOBAL_CONSTANTS = getConstants();
const MODULE_NAME_DISPLAY           = '----> /lwc/accountAssetsTileDisplay';
const MAP_KEY_ACCOUNT_ID            = 'ACCOUNT_ID';
const MAP_KEY_ACCOUNT_MACHINE_DATA  = 'ACCOUNT_MACHINE_DATA';
const MOBILE                        = 'Small';
const SUPPRESS_ACCOUNT_FIELDS       = 'none';
const MOBILE_COL_SIZE               = 12;
const DESKTOP_COL_SIZE              = 6;

export default class AccountAssetsTileDisplay extends NavigationMixin(LightningElement) {

    @api recordId;
    @api cardTitle;
    @api cardIcon;
    @api parentAccountApiName;
    @api showVgtInfoFields;
    @api showRtInfoFields;
    @api showMsgIfNoMachines;
    @api debugConsole;
    @api showAssetLink;

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
            console.info('%c'+MODULE_NAME_DISPLAY, GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        }
        this.checkRequiredProperties();
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
            this.shapeAccountMachineData(accountMachineData);
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
     * Release from cache and sort.
     * @param accountMachineData
     */
    shapeAccountMachineData(accountMachineData) {
        this.accountMachineData = JSON.parse(JSON.stringify(accountMachineData));
        this.accountMachineData.vgtMachines = this.sortMachines(this.accountMachineData.vgtMachines);
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
    get numberOfLayoutColumns() {
        let numCols = DESKTOP_COL_SIZE
        if(FORM_FACTOR == MOBILE) {
            numCols = MOBILE_COL_SIZE;
        }
        return numCols;
    }
    get numberOfRecordFormColumns() {
        let numCols = DESKTOP_COL_SIZE
        if(FORM_FACTOR == MOBILE) {
            numCols = MOBILE_COL_SIZE;
        }
        return numCols;
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
                //uiHelper.showToast(this, 'Contact Administrator', msg, 'error');
            }
        }
        if(dto && !dto.isSuccess) {
            console.warn('dto',JSON.parse(JSON.stringify(dto)));
        }
    }
}