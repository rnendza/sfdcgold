import {LightningElement,api} from 'lwc';

export default class ClTimeStamp extends LightningElement {
    @api iconName;
    @api iconClass = '';
    @api iconTitle;
    @api iconSize = 'xx-small';
    @api dateValue;
    @api dateTextClass;
    @api helpText;
}