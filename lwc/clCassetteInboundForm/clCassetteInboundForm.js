import {api, LightningElement} from 'lwc';
import mainTemplate from "./clCassetteInboundForm.html";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { getConstants } from 'c/clConstantUtil';

const GLOBAL_CONSTANTS = getConstants();

export default class ClCassetteInboundForm extends LightningElement {

    @api formDensity = 'compact';
    @api routeScheduleId;
    @api objectApiName = 'Route_Processing_Sheet__c';
    @api formClass = 'slds-theme_shade accel-form-theme_shade';
    @api formHelpMsg;
    @api formName = 'cassetteinboundform';
    @api allFieldsRequired = false;
    @api useOverridedInputStyles;
    @api saveButtonLabel = 'Save RTs';
    @api showFormSave = false;
    @api redemptionType;
    @api showOverflowFields;
    @api rpsId;
    @api
    triggerSaveEvent() {
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    _isLoading = true;
    _isSaving;
    _hasRendered;
    _buildCssOverrides;

    static delegatesFocus = true;

    constructor() {
        super();
        console.info('%c----> /lwc/clCassetteInboundForm',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
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
        const recordUi = event.detail;
        if(!this._buildCssOverrides) {
            this.buildFormThemeOverrideCss();
            this._buildCssOverrides = true;
            this._isLoading = false;
        } else {
            this._isLoading = false;
        }
        if(!this.redemptionType) {
            this.showToast('',' Account has no redemption type','error');
        }
        //alert('redemptoin type'+this.redemptionType);

    }

    /**
     * Trap the submit event and massage update if necessary (uses standard LDS for updates)
     * @param event
     */
    handleSubmit(event) {
        this._isSaving = true;
        //  Stop the form from submitting and do any overrides if necessary!
        event.preventDefault();
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event) {
        this._isSaving = false;
        let toastEvt;
        toastEvt = new ShowToastEvent({
            title: '',
            message: 'RT Info saved successfully!',
            variant: 'success'
        });
        this.dispatchEvent(toastEvt);
        this.dispatchEvent( new CustomEvent('redemptioninboundcassetteformsubmitted', {detail: { success: true }}) );
    }

    handleError(event) {
        this._isSaving = false;
        console.log(JSON.stringify(event.error));
        alert('handleError()--->'+JSON.stringify(event));
    }

    handleCloseClicked(evt) {
        this.dispatchEvent( new CustomEvent('formcloseclicked', {detail: { name: this.formName }})  );
    }

    get showForm() {
        return this.rpsId;
    }

    get showStencil() {
        return this._isLoading || this._isSaving;
    }

    get inputsClass() {
        return this.showStencil ? 'slds-hide' : '';
    }

    get showNrtFields() {
        return this.redemptionType === 'NRT';
    }

    get showM3TFields() {
        return this.redemptionType === 'M3T';
    }
    get showSafeCashFields() {
        return this.redemptionType === 'Safe Cash';
    }

    buildFormThemeOverrideCss() {
        let css = '.slds-form-element_label {color:black!important;font-weight:bold!important}';
        const style = document.createElement('style');
        if(this.useOverridedInputStyles) {
            // the below was causing issues in pad / chrome
            //           css` += '.accel-form_container ';
            // css += '.slds-input {width: 40%;height: 25px!important; ';
            // css += 'font-size: 16px;font-weight: 500;line-height: 25px;';
            // css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem!important;}';
            css += '.accel-form_container .slds-form-element__label {font-weight:bold!important;font-size:.65rem!important;max-width: calc(100% - var(--lwc-squareIconUtilityMedium,1.25rem)); }';
            css += '.accel-form_container  .slds-form-element_horizontal .slds-form-element__control {padding-left:65%!important}';
            css += '.accel-form_container  .slds-form-element_horizontal:nth-child(3n) {';
            css += ' padding-bottom:30px}';
            css += '.accel-form_container .slds-form-element_horizontal:not(.slds-is-editing) {padding:0!important}';
            css += '.accel-form container .accel-form-group-spacer {padding-bottom:1rem!important}';
            css += '';
        }
        style.innerText = css;
        let target = this.template.querySelector('.form-theme-overrides-class');
        target.appendChild(style);
    }

    debugFieldValues(fields) {
        fields.forEach(item => {
            console.log('name='+JSON.stringify(item));
        });
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