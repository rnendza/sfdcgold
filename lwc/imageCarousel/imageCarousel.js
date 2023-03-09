import {LightningElement, api} from 'lwc';

export default class ImageCarousel extends LightningElement {
    @api imageUrls = [];
    @api disableAutoScroll = false;
    @api scrollDuration = 5;

    constructor() {
        super();
        this.disableAutoScroll = true;
    }
}