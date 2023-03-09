/**
 * Currently only supported on record pages. (we need object / record context info)
 * @todo replace hard coded string messages with custom labels.
 */
import {LightningElement, api, wire, track} from 'lwc';
import { getPicklistValuesByRecordType } from 'lightning/uiObjectInfoApi';
import { getRecordUi,getFieldValue,updateRecord } from 'lightning/uiRecordApi';
import { getMasterRecordTypeId, getRecordTypeId, getSpecificField} from 'c/utilsUiRecord';
import Logger from 'c/logger'
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class UiPicklist extends LightningElement {

    //--- public api
    @api fireOptionSelectedEvent = false;   //  passed in via property  - REQUIRED.
    @api picklistLabelOverride;             //  passed in via property  - not required.
    @api picklistRequired;                  //  passed in via property  - not required.
    @api picklistLabelHideOnMobile;
    @api recordId;                          //  obtained from the context of being in record page.
    @api objectApiName;                     //  obtained from the context of being in record page.
    @api immediateUpdate = false;           // NOT YET supported.. for future use.
    @api picklistCssClass;
    @api
    get debugConsole() {
        return this._debugConsole;
    }
    set debugConsole(value) {
        this._debugConsole = value;
        this._logger = new Logger(this.debugConsole);
    }
    @api
    get picklistFieldApiName() {
        return this._picklistFieldApiName;
    }
    set picklistFieldApiName(value) {
        this._picklistFieldApiName = value;
    }

    //--- private tracked.
    @track objectInfo;
    @track record;
    @track errorMsg;
    @track showSpinner = false;
    @track picklistOptions = [];
    @track picklistSelectedValue = '';
    @track picklistLabel;
    @track picklistFieldLevelHelp = 'Test';
    @track   _picklistFieldApiName;
    @track savedDataSelectedVal;
    @track currentTime = Date.now();

    //--- private non tracked.
    _recordTypeId;
    _logger;
    _debugConsole = false;
    _picklistField;
    _picklistDefaultOverride;
    _selectedIdx = 0;

    constructor() {
        super();
    }
    connectedCallback() {
        this.immediateUpdate = false;
        if(this._picklistDefaultOverride) {
            this.picklistSelectedValue  = this._picklistDefaultOverride;
        }
        this.picklistLabelHideOnMobile = true;
    }

    /**
     * Bucho issues with selects working in desktop / mobile / iOs / Android / Salesforce1 mobile.. in every use
     * case. This was the lesser of all evils. Insert overrides of lwc shit as a style tag into the dom to bypass
     * CSS isolation. Also overrides the cursor from text to a pointer for inputs inside of a slds-combobox to look
     * more like a real dropdown as combobox currently (as of 11/24/2019 provides no data-list like functionality anyway.
     */
    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;

        const style = document.createElement('style');
        style.innerText = '.slds-is-mobile .slds-listbox_vertical .slds-listbox__option_plain, .slds-is-mobile  ' +
            '.slds-listbox_vertical .slds-listbox__option--plain, .slds-is-mobile .slds-listbox--vertical ' +
            '.slds-listbox__option_plain, .slds-is-mobile .slds-listbox--vertical .slds-listbox__option--plain {' +
            '    line-height: calc(2.00rem - 0rem)!important;font-weight:bold' +
            '}';
        style.innerText += ' .slds-combobox input {cursor:pointer}'; //<--- change cursor from text to pointer.
        let target = this.template.querySelector('.fake-lightning-combobox-class');
        target.appendChild(style);
    }

    get selectedOption() {
        if(this.picklistOptions.length > 0) {
            return this.picklistOptions[this._selectedIdx];
        }
    }
    get hasToShowSpinner() { return this.showSpinner || !this.isLoaded;}
    get isLoaded() { return this.record && this.objectInfo;}
    get genericErrorMessage() {return 'An unexpected error occurred. Please contact your System Administrator.';}
    get picklistOptions() {return this.picklistOptions;}

    @api
    get picklistDefaultOverride() {
        return this._picklistDefaultOverride;
    }
    set picklistDefaultOverride(val) {
        if(val) {
            this._picklistDefaultOverride = val;
            this.picklistSelectedValue = this._picklistDefaultOverride;
            this.dispatchOptionSelectedEvent(this.picklistSelectedValue);
        }
    }
    /**
     * Retrieve the recordUi based on the recordId in Full View mode.. ie. objectInfo. rtId etc.
     *
     * @param error
     * @param data
     * @see https://developer.salesforce.com/docs/component-library/documentation/lwc/lwc.reference_wire_adapters_record_ui
     * note.. adds picklistFieldApiName as optional field in case it's not on the page layout.
     * optionalFields: '$picklistFieldApiName'
     * optionalFields: '$_picklistFieldApiName'}
     */
    @wire(getRecordUi, { recordIds: '$recordId', layoutTypes: 'Full', modes: 'Edit'})
    wiredRecordUI({ error, data }) {
        if(!this.picklistFieldApiName) {
            this.log(ERROR,'could not find picklistFieldApiName='+this.errorMsg,error);
            return;
        }
        if(error) {
            this.errorMsg = error.body.message;
            this.log(ERROR,'in wiredrecordui error='+this.errorMsg,error);
        }
        if (data && data.records[this.recordId]) {
            this.record = data.records[this.recordId];

            this.objectInfo = data.objectInfos[this.objectApiName];
            const rtId = getRecordTypeId(this.record);

            this._recordTypeId = rtId ? rtId : getMasterRecordTypeId(this.objectInfo);
            this._picklistField = getSpecificField(this.objectInfo,this.picklistFieldApiName);

            if(this._picklistField && this._picklistField.inlineHelpText) {
                this.picklistFieldLevelHelp = this._picklistField.inlineHelpText;
            }
            if(this.record) {
                let currentValue = getFieldValue(this.record, this.objectApiName + '.' + this.picklistFieldApiName);
               // alert(currentValue);
                this.savedDataSelectedVal = currentValue;

                if(this._picklistDefaultOverride) {
                    this.picklistSelectedValue = this._picklistDefaultOverride;
                    this.dispatchOptionSelectedEvent(this.picklistSelectedValue);
                }else {
                    if (currentValue && !this._picklistDefaultOverride) {
                        this.picklistSelectedValue = currentValue;
                        this.dispatchOptionSelectedEvent(currentValue);
                    } else {
                        this.picklistSelectedValue = 'Opportunity Information';
                        // Edited by Cedric - Old value: 'Opportunity Information'//
                        //this.picklistSelectedValue = null;
                        this.dispatchOptionSelectedEvent(this.picklistSelectedValue);
                    }
                }
            }
            if(this.picklistLabelOverride) {
                this.picklistLabel = this.picklistLabelOverride;
            }else if(this._picklistField) {
                this.picklistLabel = this._picklistField.label;
            }
        }
    }
    /**
     * Load picklist values available for current record type. will refire upon change of sObjectName or recordTypeId.
     *
     * @param error
     * @param data
     */
    @wire(getPicklistValuesByRecordType, { objectApiName: '$objectApiName', recordTypeId: '$_recordTypeId'})
    wiredPicklistValues({ error, data }) {
        if (!this._recordTypeId || !this._picklistFieldApiName) {
            return;
        }
        if (error) {
            this.errorMsg = error.body.message;
            this.log(ERROR,'in wiredPicklistValues error='+this.errorMsg,error);
        }
        if (data) {
            if (data.picklistFieldValues[this.picklistFieldApiName]) {
                let pl = data.picklistFieldValues[this.picklistFieldApiName];
                if(!this.picklistSelectedValue && !this._picklistDefaultOverride) {
                    if (pl.defaultValue) {
                        this.picklistSelectedValue = pl.defaultValue.value;
                    }
                }
                pl.values.map((ele, idx) => {
                    let selected = false;
                    if(ele.value === this.picklistSelectedValue) {
                        this._selectedIdx = idx;
                        selected = true;
                    }
                    this.picklistOptions = [...this.picklistOptions, {label: ele.label + '', value: ele.value + '', selected:selected }];
                });
            } else {
                this.errorMsg = `Failed to load ${ this.picklistFieldApiName} values for record type ${this._recordTypeId}`;
                this.log(ERROR,'in wiredPicklistValues error='+this.errorMsg);
            }
        }
    }
    /**
     * Handles the change event of the picklist and fires a custom event with the selected option value.
     * @param event
     */
    handleChange(event) {
        event.stopPropagation();
        const valueSelected = event.target.value;
        this.picklistSelectedValue = valueSelected;
        if (valueSelected) {
            if(this.immediateUpdate) {
                this._updateRecord();
            }
            if(!this.fireOptionSelectedEvent) {
                return;
            }
            this.dispatchOptionSelectedEvent(valueSelected);
        }
    }
    /**
     *
     * @param value
     */
    dispatchOptionSelectedEvent(value){
        if(value) {
            let payload = {
                objectApiName: this.objectApiName,
                fieldApiName: this._picklistFieldApiName,
                value: value
            };
            const optionSelectedEvent = new CustomEvent('optionselected', {detail: {payload},});
            this.log(DEBUG,'firing optionselected selected event with payload:' + JSON.stringify(payload));
            this.dispatchEvent(optionSelectedEvent);
        }
    }

    /**
     * For future use!
     * @private
     */
    _updateRecord() {
        try {
            let toUpdate = {fields: {Id: this.recordId}};
            toUpdate.fields[this.picklistFieldApiName] = this.picklistSelectedValue;
            this.spinner = true;

            updateRecord(toUpdate)
                .then(() => {
                    this.spinner = false;
                    this.log(DEBUG,'update success');
                })
                .catch(error => {
                    alert(error);
                    //--- silent for now.. too many things such as  val rules and stuff could prevent this.
                    this.log(ERROR, JSON.stringify(error));
                    this.errorMsg = error.body.message;
                    this.spinner = false;
                });
        } catch(e) {
            console.error(e);
        }
    }
    /**
     *
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
            switch (logType) {
                case DEBUG:
                    this._logger.logDebug(msg,obj);
                    break;
                case ERROR:
                    this._logger.logError(msg,obj);
                    break;
                case INFO:
                    this._logger.logInfo(msg,obj);
                    break;
                default:
                    this._logger.log(msg, obj);
            }
        }
    }
}