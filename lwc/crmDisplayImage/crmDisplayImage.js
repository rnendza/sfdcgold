import {LightningElement, track, api} from 'lwc';
import IMAGES from '@salesforce/resourceUrl/crm_image_resources';
/**
 * AcDisplayImage is a simple wrapper around an html img element which looks for images in a static resource.
 */
export default class CrmDisplayImage extends LightningElement {

    //  Public and Reactive Props
    @api   imageName;       //  REQUIRED ie Twinstar

    //     optional
    @api   imageFolder;     //  if not passed, then it assumes the root of the static resource.
    @api   imageType;       //  ie jpg
    @api   imageAlt;        //  Any alt text
    @api   imageClass;      //  css class (must define in css in this component or import static resource).
    @api   imageHeight;     //  ie 16
    @api   imageWidth;      //  ie 48
    @api   imageStyle;      //  ie border:1px dotted red

    //  Private Reactive Props
    @track imageUrl;

    constructor() {
        super();
        this.imageType = 'png'; //  Default the type to png.
    }
    connectedCallback() {
        this.buildImageUrl(); //  Fire this after we have a writable DOM.
    }
    /**
     *  Simply build the url with the passed public props.
     *  If no imageFolder is passed, assumes the root.
     */
    buildImageUrl() {
        try {
            this.imageUrl = IMAGES +'/';
            if(this.imageFolder) {
                this.imageUrl += this.imageFolder + '/';
            }
            this.imageUrl += this.imageName;
            this.imageUrl += '.' + this.imageType;
        } catch (e) {
            console.error(e); //@todo... possible write error to server?
        }
    }
}