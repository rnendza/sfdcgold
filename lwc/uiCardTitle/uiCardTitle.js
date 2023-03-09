import {LightningElement,api} from 'lwc';

export default class UiCardTitle extends LightningElement {

    @api cardTitle;     // required
    @api cardSubtitle;
    @api cardSecondSubtitle;
    @api cardThirdSubtitle;
    @api cardFourthSubtitle;
    @api showBackButton = false;
    @api backButtonLabel;
    @api backButtonStyle = 'font-size:.75rem!important';
    @api iconName       = 'standard:account';
    @api iconClass      = 'slds-m-right_x-small';
    @api iconSize       = 'medium';
    @api cardTitleStyle = '';
    @api subTitleTextClass = 'accel-card_subtitle';
    @api subTitleTextStyle = '';

    handleBackClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        let payload = 'not sure yet';
        this.dispatchEvent( new CustomEvent('backclicked', {detail: {payload}}));
    }

    get backButtonClass() {
        let cls = '';
        if(!this.backButtonStyle) {
            cls = 'accel-back-button';
        }
        return cls;
    }
}