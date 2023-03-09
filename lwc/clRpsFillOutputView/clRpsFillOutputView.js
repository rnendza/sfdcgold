import {LightningElement,api,track} from 'lwc';
import mainTemplate from "./clRpsFillOutputView.html";


import ONE_OB_NOTE_COUNT_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Cassette_1_Note_Count_Outbound__c';  
import FIVE_OB_NOTE_COUNT_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Cassette_5_Note_Count_Outbound__c';
import TWENTY_OB_NOTE_COUNT_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Cassette_20_Note_Count_Outbound__c';
import FIFTY_OB_NOTE_COUNT_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Cassette_50_Note_Count_Outbound__c';
import HUNDRED_OB_NOTE_COUNT_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Cassette_100_Note_Count_Outbound__c';
//import OUTBOUND_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Outbound__c';
import OUTBOUND_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Outbound_Total__c';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { getConstants } from 'c/clConstantUtil';

const GLOBAL_CONSTANTS = getConstants();

export default class ClRpsFillOutputView extends LightningElement {

    @api formDensity = 'auto';
    @api rpsId;
    @api formTitle;
    @api objectApiName = 'Route_Processing_Sheet__c';
    @api formClass = 'slds-box slds-theme_shade';
    @api formHelpMsg;
    @api formName = 'rpsOutboundForm';
    @api allFieldsRequired = false;
    @api useOverridedInputStyles;

    _oneObNoteCountField = ONE_OB_NOTE_COUNT_FIELD;
    _fiveObNoteCountField = FIVE_OB_NOTE_COUNT_FIELD;
    _twentyObNoteCountField = TWENTY_OB_NOTE_COUNT_FIELD;
    _fiftyObNoteCountField = FIFTY_OB_NOTE_COUNT_FIELD;
    _hundredObNoteCountField = HUNDRED_OB_NOTE_COUNT_FIELD;
    _outboundField = OUTBOUND_FIELD;

    _isLoading = true;
    _isSaving;
    _hasRendered;
    _buildCssOverrides;

    static delegatesFocus = true;

    constructor() {
        super();
        console.info('%c----> /lwc/clRpsFillOutputView',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.useOverridedInputStyles = true;
        console.log('ccback outputview rpsId='+this.rpsId);
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
    }


    handleCloseClicked(evt) {
        this.dispatchEvent( new CustomEvent('formcloseclicked', {detail: { name: this.formName }})  );
    }

    handleSubmitFillComplete(evt) {
        this.showToast('','@todo save here','info');
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
            css += '.accel-form_container .slds-input {width: 100%;display: inline-block;height: 40px; ';
            css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
            css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;}';
            css += '.accel-form_container .slds-form-element__label {/*font-weight:bold!important;*/ }';
            css += '';
        }
        style.innerText = css;
        let target = this.template.querySelector('.form-theme-overrides-class');
        target.appendChild(style);
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