import {LightningElement,api} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {getConstants} from "c/clConstantUtil";

const GLOBAL_CONSTANTS = getConstants();

export default class ClRouteVehicleInfo extends LightningElement {

    @api formDensity = 'auto';
    @api routeScheduleId;
    @api objectApiName = 'Route_Schedule__c';
    @api formClass = 'slds-box slds-theme_shade';
    @api formHelpMsg;
    @api formName = 'vechicleform';
    @api allFieldsRequired = false;
    @api useOverridedInputStyles;
    @api showEndingMileage;

    _isLoading = true;
    _isSaving;
    _hasRendered;
    _buildCssOverrides;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteVehicleInfo',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.useOverridedInputStyles = true;
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

    // /**
    //  * Called via LDS onsubmit={handleVehicleSubmit} on the lightning-record-edit-form tag.
    //  * @param event
    //  *
    //  * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/3023980455
    //  * @see https://medium.com/@strusov/lwc-lightning-record-edit-form-set-or-modify-field-values-onsubmit-9f00199bc2a
    //  * @see https://developer.salesforce.com/docs/component-library/bundle/lightning-record-edit-form/documentation  (overriding default behavior)
    //  */
    // handleVehicleSubmit(event) {
    //     event.preventDefault();
    //     const fields = event.detail.fields;
    //     console.log('---> submitting fields',fields);
    //     this.template.querySelector('lightning-record-edit-form').submit(fields);
    //     this._isSaving = true;
    // }

    handleSuccess(event) {
        this._isSaving = false;
        let toastEvt;
        toastEvt = new ShowToastEvent({
            title: '',
            message: 'Vehicle Information Saved successfully!',
            variant: 'success'
        });
        this.dispatchEvent(toastEvt);
        console.log('---> form success delaying event fire of form submitted');
        setTimeout(() => {
            this.dispatchEvent( new CustomEvent('vehicleformsubmitted', {detail: { success: true }}) );
        }, 500);

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
        console.log('--> showForm rsId',this.routeScheduleId);
        return this.routeScheduleId;
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
            css += '.accel-form_container .slds-form-element__label {font-weight:bold!important; }';
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
}