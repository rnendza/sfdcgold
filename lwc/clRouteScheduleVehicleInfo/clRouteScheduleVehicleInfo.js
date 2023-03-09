import {LightningElement,api} from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import mainTemplate from './clRouteScheduleVehicleInfo.html';
import {getConstants} from "c/clConstantUtil";


const GLOBAL_CONSTANTS = getConstants();

export default class ClRouteScheduleVehicleInfo extends LightningElement {

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

    static delegatesFocus = true;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteScheduleVehicleInfo',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
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
       // console.log('--> form handleLoad '+JSON.stringify(recordUi));
        console.log('---> handle load');
        if(!this._buildCssOverrides) {
            this.buildFormThemeOverrideCss();
            this._buildCssOverrides = true;
            this._isLoading = false;
        } else {
            this._isLoading = false;
        }
    }

    /**
     * Called via LDS onsubmit={handleVehicleSubmit} on the lightning-record-edit-form tag.
     * @param event
     *
     * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/3023980455
     * @see https://medium.com/@strusov/lwc-lightning-record-edit-form-set-or-modify-field-values-onsubmit-9f00199bc2a
     * @see https://developer.salesforce.com/docs/component-library/bundle/lightning-record-edit-form/documentation  (overriding default behavior)
     */
    handleVehicleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        console.log('---> submitting fields',fields);
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this._isSaving = true;
    }

    // handleSubmit(event) {
    //
    //     //  Stop the form from submitting and do shit if necessary!
    //     event.preventDefault();
    //     //event.stopPropagation();
    //     console.log('submit form');
    //     const fields = event.detail.fields;
    //     this.template.querySelector('lightning-record-edit-form').submit();
    //     //this.template.querySelector('lightning-record-edit-form').submit(fields);
    //     this._isSaving = true;
    // }

    handleSuccess(event) {
       // console.log('handleSuccess route schedule fields. : '+JSON.stringify(event.detail.fields));
        console.log('handleSuccess');
        this._isSaving = false;
        let toastEvt;
        toastEvt = new ShowToastEvent({
            title: '',
            message: 'Vehicle Information Saved successfully!',
            variant: 'success'
        });
        this.dispatchEvent(toastEvt);
        this.dispatchEvent( new CustomEvent('vehicleformsubmitted', {detail: { success: true }}) );

        // try {
        //     this.debugFieldValues(event.detail.fields);
        // } catch (e) {
        //
        // }
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
        return this.routeScheduleId;
    }

    get showStencil() {
        return this._isLoading || this._isSaving;
    }

    get inputsClass() {
        return this.showStencil ? 'slds-hide' : '';
    }


    createKeyframeAnimation() {
        // Figure out the size of the element when collapsed.
        let {x, y} = this.calculateCollapsedScale();
        let animation = '';
        let inverseAnimation = '';

        for (let step = 0; step <= 100; step++) {
            // Remap the step value to an eased one.
            let easedStep = ease(step / 100);

            // Calculate the scale of the element.
            const xScale = x + (1 - x) * easedStep;
            const yScale = y + (1 - y) * easedStep;

            animation += `${step}% {transform: scale(${xScale}, ${yScale});}`;

            // And now the inverse for the contents.
            const invXScale = 1 / xScale;
            const invYScale = 1 / yScale;
            inverseAnimation += `${step}% {
      transform: scale(${invXScale}, ${invYScale});
    }`;

        }

        return `
  @keyframes menuAnimation {
    ${animation}
  }

  @keyframes menuContentsAnimation {
    ${inverseAnimation}
  }`;
    }
    calculateCollapsedScale () {
        // The menu title can act as the marker for the collapsed state.
        const collapsed = menuTitle.getBoundingClientRect();

        // Whereas the menu as a whole (title plus items) can act as
        // a proxy for the expanded state.
        const expanded = menu.getBoundingClientRect();
        return {
            x: collapsed.width / expanded.width,
            y: collapsed.height / expanded.height
        };
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