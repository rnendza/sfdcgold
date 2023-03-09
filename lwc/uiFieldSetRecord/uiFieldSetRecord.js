/**
 * Currently only supported on record pages. (we need object / record context info)
 * @todo replace hard coded string messages with custom labels.
 */
import {LightningElement, api, wire, track} from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getRecordUi,getFieldValue,updateRecord } from 'lightning/uiRecordApi';
import { getMasterRecordTypeId, getRecordTypeId, getSpecificField} from 'c/utilsUiRecord';
import retrieveFsData  from '@salesforce/apex/POC_FieldSetController.retrieveSpecificFieldSetWrappersAndFieldSetMembers';


import Logger from 'c/logger'
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class UiFieldSetRecord extends LightningElement {
    _recId;
    @api recordId;                          //  obtained from the context of being in record page.
    @api objectApiName;                     //  obtained from the context of being in record page.
    _fieldSetWrappers = [];
    @api
    get fieldSetWrappers() {
        return this._fieldSetWrappers;
    }
    set fieldSetWrappers(value) {
        if(value) {
            this._fieldSetWrappers = value;
        }
    }
    fieldSetWrappers = [];
    @api wiredFieldSetDto;
    @api
    get debugConsole() {
        return this._debugConsole;
    }
    set debugConsole(value) {
        this._debugConsole = value;
        this._logger = new Logger(this.debugConsole);
    }

    //--- private tracked.
    @track wiredFsDto;
    @track objectInfo;
    @track record;
    @track errorMsg;
    @track showSpinner = false;

    //--- private non tracked.
    _recordTypeId;
    _logger;
    _debugConsole = false;

    constructor() {
        super();
    }
    connectedCallback() {
    }
}