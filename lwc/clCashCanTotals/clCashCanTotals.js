import {LightningElement,api,track} from 'lwc';
import mainTemplate from "./clCashCanTotals.html";

import ONE_NOTE_COUNT_GRAND_TOTAL_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.X1_Note_Count_Grand_Total__c';
import FIVE_NOTE_COUNT_GRAND_TOTAL_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.X5_Note_Count_Grand_Total__c';
import TEN_NOTE_COUNT_GRAND_TOTAL_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.X10_Note_Count_Grand_Total__c';
import TWENTY_NOTE_COUNT_GRAND_TOTAL_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.X20_Note_Count_Grand_Total__c';
import FIFTY_NOTE_COUNT_GRAND_TOTAL_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.X50_Note_Count_Grand_Total__c';
import ONEHUNDRED_NOTE_COUNT_GRAND_TOTAL_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.X100_Note_Count_Grand_Total__c';

import {getConstants} from "c/clConstantUtil";

import Id from "@salesforce/user/Id";

import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";

const RPS_PROCESSING_STATUS_COMPLETED_PROCESSING = 'COMPLETED PROCESSING';
const RPS_PROCESSOR_RT_STATUS = 'Complete';
const GLOBAL_CONSTANTS = getConstants();

export default class ClCashCanTotals extends LightningElement {

    @api formDensity = 'auto';
    @api rpsId;
    @api formTitle = 'Grand Totals:';
    @api objectApiName = 'Route_Processing_Sheet__c';
    @api formClass = 'xxxxslds-box slds-theme_shade';
    @api formHelpMsg;
    @api formName = 'rpsGrandTotalsForm';
    @api allFieldsRequired = false;
    @api useOverridedInputStyles;
    @api
    triggerSaveEvent() {
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    _1GrandTotalField = ONE_NOTE_COUNT_GRAND_TOTAL_FIELD;
    _5GrandTotalField = FIVE_NOTE_COUNT_GRAND_TOTAL_FIELD;
    _10GrandTotalField = TEN_NOTE_COUNT_GRAND_TOTAL_FIELD;
    _20GrandTotalField = TWENTY_NOTE_COUNT_GRAND_TOTAL_FIELD;
    _50GrandTotalField = FIFTY_NOTE_COUNT_GRAND_TOTAL_FIELD;
    _100GrandTotalField = ONEHUNDRED_NOTE_COUNT_GRAND_TOTAL_FIELD;

    _isLoading = true;
    _isSaving;
    _hasRendered;
    _buildCssOverrides;
    _tmpStoredValues = [
        {fieldName:this._1GrandTotalField.fieldApiName,fieldValue:0,multiplier:1},
        {fieldName:this._5GrandTotalField.fieldApiName,fieldValue:0,multiplier:5},
        {fieldName:this._10GrandTotalField.fieldApiName,fieldValue:0,multiplier:10},
        {fieldName:this._20GrandTotalField.fieldApiName,fieldValue:0,multiplier:20},
        {fieldName:this._50GrandTotalField.fieldApiName,fieldValue:0,multiplier:50},
        {fieldName:this._100GrandTotalField.fieldApiName,fieldValue:0,multiplier:100},
    ];

    static delegatesFocus = true;

    constructor() {
        super();
        console.info('%c----> /lwc/clCashCanTotals',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        //console.log('---> rpsId='+this.rpsId);
        this.useOverridedInputStyles = true;
    }

    render() {
        return mainTemplate;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
        }

    }

    handleLoad(event) {
        if(!this._buildCssOverrides) {
            this.buildFormThemeOverrideCss();
            this._buildCssOverrides = true;
            this._isLoading = false;
        } else {
            this._isLoading = false;
        }
        var record = event.detail.records;
        var fields = record[this.rpsId].fields;
        //console.log('--> handle load fields:',fields);
        this._tmpStoredValues.find(x => x.fieldName === 'X1_Note_Count_Grand_Total__c').fieldValue = fields.X1_Note_Count_Grand_Total__c.value;
        this._tmpStoredValues.find(x => x.fieldName === 'X5_Note_Count_Grand_Total__c').fieldValue = fields.X5_Note_Count_Grand_Total__c.value;
        this._tmpStoredValues.find(x => x.fieldName === 'X10_Note_Count_Grand_Total__c').fieldValue = fields.X10_Note_Count_Grand_Total__c.value;
        this._tmpStoredValues.find(x => x.fieldName === 'X20_Note_Count_Grand_Total__c').fieldValue = fields.X20_Note_Count_Grand_Total__c.value;
        this._tmpStoredValues.find(x => x.fieldName === 'X50_Note_Count_Grand_Total__c').fieldValue = fields.X50_Note_Count_Grand_Total__c.value;
        this._tmpStoredValues.find(x => x.fieldName === 'X100_Note_Count_Grand_Total__c').fieldValue = fields.X100_Note_Count_Grand_Total__c.value;
        //console.log('updated array',this._tmpStoredValues);
        this.dispatchEvent( new CustomEvent('grandtotalfieldchanged', {detail: { fieldArray: this._tmpStoredValues }})  );
    }


    handleCloseClicked(evt) {
        this.dispatchEvent( new CustomEvent('formcloseclicked', {detail: { name: this.formName }})  );
    }
    handleGtInputChange(evt) {
        let value = Number(evt.detail.value);
        let field = evt.target.dataset.field;
        this._tmpStoredValues = this._tmpStoredValues.map(x => (x.fieldName === field) ? { ...x, fieldValue: value } : x);
        this.dispatchEvent( new CustomEvent('grandtotalfieldchanged', {detail: { fieldArray: this._tmpStoredValues }})  );
        console.log('fired event');
    }

    handleSubmit(evt) {
        this.showToast('','@todo save here','info');
    }

    handleSuccess(event) {
        //console.log('handleSuccess  fields. : '+JSON.stringify(event.detail.fields));
    }

    get showForm() {
        return this.rpsId;
    }
    get showFormContents() {
        return this.rpsId && !this._isLoading;
    }

    get showStencil() {
        return this._isLoading || this._isSaving;
    }

    get inputsClass() {
        return this.showStencil ? 'slds-hide' : '';
    }

    buildFormThemeOverrideCss() {
        let css = '.slds-form-element_label {color:black!important;font-weight:bold!important}';
        const style = document.createElement('style');
        if(this.useOverridedInputStyles) {
            // css += '.accel-form_container .slds-input {width: 100%;display: inline-block;height: 40px; ';
            // css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
            // css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;}';
            css += '.accel-form_container .slds-form-element__label {/*font-weight:bold!important;*/ }';
            css += '';
        }
        style.innerText = css;
        let target = this.template.querySelector('.form-theme-overrides-class');
        target.appendChild(style);
    }

    handleError(event) {
        this._isSaving = false;
        console.log(JSON.stringify(event.error));
        alert('handleError()--->'+JSON.stringify(event));
    }

    /**
     *
     * @param title
     * @param msg
     * @param variant
     */
    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}