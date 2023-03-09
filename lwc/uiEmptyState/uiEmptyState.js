import {LightningElement,api} from 'lwc';

export default class UiEmptyState extends LightningElement {

    @api containerClass = 'slds-illustration slds-illustration_small';
    @api headerText;
    @api bodyText;

}