import {api, LightningElement} from 'lwc';

export default class UiImageThumb extends LightningElement {
    /**
     * The height to set on the div to render.
     * @type {number}
     * @access public
     * @default 10
     */
    @api height = 10;
    @api meterId;
    @api assetId;
    @api rpsId;
    @api rpsImageType;
    @api imgDownloadUrl;
    @api imgPreviewUrl;
    @api contentDocumentId;
    @api contentVersionId;

    /**
     * The width to set on the div to render.
     * @type {number}
     * @access public
     */
    @api width;

    get containerStyle() {
        return `${this.containerHeight}; ${this.containerWidth}; ${this.containerRadius}`;
    }

    get imgStyle() {
        return `${this.imgHeight}; ${this.imgWidth}`;
    }
    
    get containerHeight() {
        return `height: ${this.height}px`;
    }

    get containerWidth() {
        if (!this.width) {
            return 'width: 100%';
        }
        return `width: ${this.width}px`;
    }
    
    

    get imgHeight() {
        return `height: ${this.height}px`;
    }

    get imgWidth() {
        if (!this.width) {
            return 'width: 100%';
        }
        return `width: ${this.width}px`;
    }
    handleImgClick(evt) {
        let payload;
        console.log('img click 1 in thumb');
        if(!this.rpsId) {
            payload  = {
                meterId: this.meterId,
                assetId: this.assetId,
                contentDocumentId: this.contentDocumentId,
                contentVersionId: this.contentVersionId
            };
        } else {
            payload  = {
                rpsId: this.rpsId,
                rpsImageType: this.rpsImageType,
                contentDocumentId: this.contentDocumentId,
                contentVersionId: this.contentVersionId
            };
        }
        console.log('hanldeImgClick in image thumb. fire with payload=',payload);
        this.dispatchEvent(new CustomEvent('uiimageclick', {detail: payload}));

    }
    previewDocument(evt) {
        window.open(this.imgPreviewUrl);
    }
}