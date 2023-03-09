import {LightningElement,api} from 'lwc';

export default class UiButton extends LightningElement {

    @api buttonName;
    @api buttonTitle;
    @api buttonLabel;
    @api buttonStyle;
    @api buttonDisabled;
    @api buttonLabelStyle;
    @api buttonClasses = 'slds-button slds-button_neutral slds-button_stretch'
    @api buttonIconName;
    @api buttonIconVariant;
    @api buttonIconAltText;
    @api buttonIconTitle;
    @api buttonIconSize;

    handleClick(evt) {
        const payload = { buttonid: evt.currentTarget.dataset.buttonid };
        const customEvt = new CustomEvent('buttonclick', { bubbles : true, detail: payload, composed : true });
        this.dispatchEvent(customEvt);
    }

    get showButton() {
        return this.buttonName;
    }
}