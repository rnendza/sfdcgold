import {LightningElement,api} from 'lwc';

export default class UiImageInfo extends LightningElement {

    @api imgTitleDisplay;
    @api imgTitleFull;
    @api imgSize;
    @api imgUserName;
    @api imgDate;
    @api imgViewCount;

}