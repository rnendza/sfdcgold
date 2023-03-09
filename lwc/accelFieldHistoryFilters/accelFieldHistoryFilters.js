import {LightningElement, wire,track,api} from 'lwc';
import {reduceErrors} from 'c/ldsUtils';
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {uiHelper} from "./accelFieldHistoryFiltersUiHelper";
import retrieveHistoryObjects from '@salesforce/apex/FieldHistoryFiltersController.retrieveHistorySObjects';
import retrieveFilteredHistoryObjects from '@salesforce/apex/FieldHistoryFiltersController.retrieveFilteredSObjects';
import retrieveHistObjFields from '@salesforce/apex/FieldHistoryFiltersController.retrieveAllFieldsTracked';

const   GLOBAL_CONSTANTS            = getConstants();
const   MAP_KEY_SOBJECT_DATA        = 'MAP_KEY_SOBJECT_DATA';
const   MAP_KEY_FIELDS_DATA         = 'MAP_KEY_FIELD_DATA';

export default class AccelFieldHistoryFilters extends LightningElement {

    @api defaultSelections;

    _wiredHistObjsDto;
    _wiredObjFieldsDto;

    _isLoading = false;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    @track objectTypePlOptions;
    @track histObjsPlOptions;
    @track histFieldsPlOptions;
    @track selectedSObjType;
    @track selectedHistObj;
    @track selectedStartDateTimeValue;
    @track selectedEndDateTimeValue;
    @track defaultHistoryObjSelection = '-1';

    @track histObjsData;
    @track histFieldsData;
    @track histFieldSelectedValues;

    @track profileData;
    @track pillIcon;
    @track profileOptions;
    @track defaultProfileSelections;
    @track permSetData;
    @track permSetOptions;
    @track defaultPermSetSelections;
    @track sObjectData;
    @track sObjectOptions;
    @track defaultSObjectSelections;
    @track profilePillIcon;
    @track permSetPillIcon;
    @track sObjectPillIcon;
    @track isCustomObjectType;


    constructor() {
        super();
        console.info('%c----> /lwc/accelFieldHistoryFilters',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
    }

    connectedCallback() {
        this._isLoading = true;
        this.generateDefaults();
    }

    @api generateDefaults() {
        this.generateObjectTypeOptions();
        this.generateDefaultDates();
        this.histFieldSelectedValues = null;
        if(this.defaultSelections) {
            this.filteredHistoryObjects = this.defaultSelections.filteredHistoryObjects;
            console.log('---> generateDefaults defaultSelections',JSON.parse(JSON.stringify(this.defaultSelections)));
            this.generateHistoryObjectsOptions();
        }
        this.selectedHistObj = '-1';
    }

    @wire(retrieveHistoryObjects,{'objectType': '$selectedSObjType'})
    wiredHistObjs(wiredData) {

        this._wiredHistObjsDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            uiHelper.showToast(this,'Error getting data',this.error,'error');
            this._isLoading = false;
        } else if (data) {
            console.log('---> dto',JSON.parse(JSON.stringify(data)));
            this.histObjsData = this._accelUtils.getMapValue(MAP_KEY_SOBJECT_DATA, data.values);
            this.generateHistoryObjectsOptions();
        }
        this._isLoading = false;
    }
    @wire(retrieveFilteredHistoryObjects,{'historyObjects': '$filteredHistoryObjects'})
    wiredFilteredHistObjs(wiredData) {

        this._wiredHistObjsDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            uiHelper.showToast(this,'Error getting data',this.error,'error');
            this._isLoading = false;
        } else if (data) {
            console.log('---> dto',JSON.parse(JSON.stringify(data)));
            this.histObjsData = this._accelUtils.getMapValue(MAP_KEY_SOBJECT_DATA, data.values);
            this.generateHistoryObjectsOptions();
        }
        this._isLoading = false;
    }
    @wire(retrieveHistObjFields,{'sObjectApiName': '$selectedHistObj'})
    wiredObjFields(wiredData) {
        console.log('in wired');
        this._wiredObjFieldsDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            console.log('---> dto',JSON.parse(JSON.stringify(data)));
            this.histFieldsData = this._accelUtils.getMapValue(MAP_KEY_FIELDS_DATA, data.values);
            if(data.isSuccess) {
                this.generateHistoryFieldsOptions();
            } else {
                if(this.selectedHistObj !== '-1') {
                    uiHelper.showToast(this, '', 'No fields are tracked for ' + this.selectedHistObj, 'warning');
                }
            }
        }
        this._isLoading = false;
    }
    generateDefaultDates() {
        this.selectedStartDateTimeValue = this.defaultStartDateTime;
        this.selectedEndDateTimeValue = this.defaultEndDateTime;
        this.dispatchEvent(new CustomEvent('startdatechange', {
            detail: {
                'name' :  'startdatechange',
                'payloadType' : 'date',
                'payload' : {
                    'value' : this.selectedStartDateTimeValue
                }
            }
        }));
        this.dispatchEvent(new CustomEvent('enddatechange', {
            detail: {
                'name' :  'enddatechange',
                'payloadType' : 'date',
                'payload' : {
                    'value' : this.selectedEndDateTimeValue
                }
            }
        }));
    }
    generateHistoryFieldsOptions() {
        if(this.histFieldsData) {
            let options = [];
            this.histFieldsData.forEach(item => {
                let option = {label:item.fieldLabel, value:item.fieldApiName};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.fieldLabel < b.fieldLabel ? -1 : 1;
            });
            this.histFieldsPlOptions = options;
        }
    }

    generateHistoryObjectsOptions() {
        if(this.histObjsData) {
            let options = [];
            this.histObjsData.forEach(item => {
                let sObjValue;
                if(item.apiName.includes('__History')) {
                    sObjValue = item.apiName.replace('__History','__c');
                } else if(item.apiName.includes('History')) {
                    sObjValue = item.apiName.replace('History','');
                }
                let selected = false;
                if(this.defaultHistoryObjectSelection) {
                    if(this.defaultHistoryObjectSelection === item.apiName) {
                        selected = true;
                    } else {
                        selected = false;
                    }
                }
                let option = { label:item.label, value:sObjValue, historySObjName: item.apiName ,selected:selected};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.label < b.label ? -1 : 1;
            });
            options.unshift( {label: 'Select History Object', value: '-1', selected: true, disabled:"disabled"} );
            this.histObjsPlOptions = options;
        }
    }
    generateObjectTypeOptions() {
        let options = [
            {label: 'Select Object Type', value: '-1', disabled:"disabled"},
            {label: 'Custom Object', value: 'custom', selected: true},
            {label: 'Standard Object', value: 'standard', selected: false}
        ];
        this.objectTypePlOptions = options;
    }

    handleSingleSelect(evt) {
        let value = evt.target.value;
        let name  = evt.target.name;

        switch(name) {
            case 'objecttype':
                this.processObjectTypeSelection(value);
                break;
            case 'histobj':
                this.processHistObjSelection(value);
                break;
        }
    }

    processObjectTypeSelection(objectTypeValue) {
        if (objectTypeValue !== '-1') {
            this._isLoading = true;
            this.selectedSObjType = objectTypeValue;
        }
    }

    processHistObjSelection(histSObjValue) {
        if (histSObjValue !== '-1') {
            this._isLoading = true;
            this.selectedHistObj = histSObjValue;
            this.histFieldSelectedValues = null;
            this.histFieldsPlOptions = null;
            let option = this.histObjsPlOptions.find( option => option.value === histSObjValue);
            let histSObjName;
            if(option) {
                histSObjName = option.historySObjName;
            }
            this.dispatchEvent(new CustomEvent('histobjselect', {
                detail: {
                    'name' :  'histobjselect',
                    'payloadType' : 'select',
                    'payload' : {
                        'value' : histSObjValue,
                        'historySObjName' : histSObjName
                    }
                }
            }));
        }
    }

    handleStartDateChange(evt) {
        this.selectedStartDateTimeValue = evt.target.value;
        this.dispatchEvent(new CustomEvent('startdatechange', {
            detail: {
                'name' :  'startdatechange',
                'payloadType' : 'date',
                'payload' : {
                    'value' : this.selectedStartDateTimeValue
                }
            }
        }));
    }

    handleEndDateChange(evt) {
        this.selectedEndDateTimeValue = evt.target.value;
        this.dispatchEvent(new CustomEvent('enddatechange', {
            detail: {
                'name' :  'enddatechange',
                'payloadType' : 'date',
                'payload' : {
                    'value' : this.selectedEndDateTimeValue
                }
            }
        }));
    }
    handleSelect(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                if(evt.detail.name === 'histFieldSelect') {
                    this.histFieldSelectedValues = payload.values;
                }
                this.dispatchEvent(new CustomEvent('fieldselect', {
                    detail: {
                        'name' :  evt.detail.name,
                        'payloadType' : 'multi-select',
                        'payload' : {
                            'value' : payload.value,
                            'values' : payload.values
                        }
                    }
                }));
            }
        }
    }
    handleOptionsRemoved(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                console.log('forwarding opttion removed from recieved payload',JSON.parse(JSON.stringify(payload)));
                let arrValuesRemoved = [];
                if(payload.optionsRemoved) {
                    payload.optionsRemoved.forEach( option => {arrValuesRemoved.push(option.value)});
                }
                this.dispatchEvent(new CustomEvent('fieldremove', {
                    detail: {
                        'name' :  evt.detail.name,
                        'payloadType' : 'multi-select',
                        'payload' : {
                            'optionsRemoved' : arrValuesRemoved
                        }
                    }
                }));
            }
        }
    }

    get isLoading() {
        return this._isLoading;
    }
    get showStencil() {
        return this.isLoading;
    }

    get defaultStartDateTime() {
        let d = new Date();
        d = new Date(d.setDate(d.getDate()-7));
        d.setHours(0,0,0,0)
        return d.toISOString();
    }

    get defaultEndDateTime() {
        let d = new Date();
        return d.toISOString();
    }
}