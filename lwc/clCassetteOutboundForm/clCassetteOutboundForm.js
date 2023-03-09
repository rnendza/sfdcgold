import {api, LightningElement} from 'lwc';
import mainTemplate from "./clCassetteOutboundForm.html";
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class ClCassetteOutboundForm extends LightningElement {

    @api formDensity = 'compact';
    @api routeScheduleId;
    @api objectApiName = 'Route_Processing_Sheet__c';
    @api formClass = 'slds-theme_shade accel-outbound-form-theme_shade';
    @api formHelpMsg;
    @api formName = 'cassetteoutboundform';
    @api useOverridedInputStyles;
    @api rpsId;

    _isLoading = true;
    _isSaving;
    _hasRendered;
    _buildCssOverrides;

    static delegatesFocus = true;

    constructor() {
        super();
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
        console.log('---> handle load');
        if(!this._buildCssOverrides) {
            this.buildFormThemeOverrideCss();
            this._buildCssOverrides = true;
            this._isLoading = false;
        } else {
            this._isLoading = false;
        }
    }

    handleError(event) {
        this._isSaving = false;
        console.log(JSON.stringify(event.error));
        alert('handleError()--->'+JSON.stringify(event));
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