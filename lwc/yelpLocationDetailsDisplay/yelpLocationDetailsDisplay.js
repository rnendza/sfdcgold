import {api, LightningElement, track, wire} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import retrieveBusinessDetails from '@salesforce/apex/YelpSearchController.retrieveBusinessDetails';
import retrieveReviews from '@salesforce/apex/YelpSearchController.retrieveReviews';
import {fireEvent, registerListener, unregisterAllListeners} from 'c/pubSub';
import Logger from "c/logger";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {loadScript, loadStyle} from "lightning/platformResourceLoader";
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';

const MAP_KEY_BUSINESS_DETAILS         =            'MAP_KEY_BUSINESS_DETAILS';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class YelpLocationDetailsDisplay extends LightningElement {

    _debugConsole = true;
    _className = 'YelpLocationDetailsDisplay';
    _logger = new Logger(this._debugConsole);
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    @wire(CurrentPageReference) pageRef;
    @track isSearching;
    @track anyDetailsToDisplay = false;
    @track showBusinessDetails = false;
    @track reviews = [];
    @api businessDetails;
    @track showPhotoCarousel = false;
    @api businessClicked;

    @api
    get cardTitle() {
        if(this.businessClicked) {
            return this.businessClicked.name + ' details';
        } else {
            return '';
        }
    }
    constructor() {
        super();
        console.log('-----> contructor locdets');
        this.anyDetailsToDisplay = true;
        this.isSearching = true;
    }
    renderedCallback() {
        if(!this.hasRendered) {
            this.hasRendered = true;
       //     this.loadFontAwesome();
        }
    }
    connectedCallback() {
        this.log( 'debug',' === connected callback ===');
        this.isSearching = true;
        registerListener('locationMoreDetailClicked', this.handleLocationMoreDetailClicked, this);
        registerListener('locationSelected', this.handleGeoAddressSelected, this);
        this.log( 'debug',' === registered locationMoreDetailClicked ===');
    }
    handleLocationMoreDetailClicked(business) {
        console.log('in yelpLocationDetailsDisplay business-'+JSON.stringify(business));
        if(business) {
            this.anyDetailsToDisplay = true;
            this.businessClicked = business;
            this.searchBusinessDetails();
            this.searchReviews(); //  @todo here or cb of searchBusinessDetails?
        } else {
            this.anyDetailsToDisplay = false;
        }
    }

    handleSearchAgain(event) {
        fireEvent(this.pageRef, 'searchAgain', true);
        this.showBusinessDetails = false;
        this.reviews = [];
        this.businessDetails = null;
        this.showPhotoCarousel = false;
        this.businessClicked = null;
        this.isSearching = true;
    }
    /**
     *
     */
    searchBusinessDetails() {
        const params = {businessId: this.businessClicked.id };
        this.log('info',this._className + ' calling retrieveBusinessDetails with prams', JSON.stringify(params));
        this.isSearching = true;
        retrieveBusinessDetails(params)
            .then(result => {
                let dto = result;
                if (dto.isSuccess) {
                  let tmp = this._accelUtils.getMapValue(MAP_KEY_BUSINESS_DETAILS, dto.values);
                 this.businessDetails = Object.assign({},tmp);
                  try {
                      this.showBusinessDetails = true;
                      this.parseBusinessDetails();
                  } catch (e) {
                      alert(e);
                  }
                } else {
                    this.log('error', 'error getting business details', JSON.stringify(dto));
                    this.businessDetails = null;
                    this.showBusinessDetails = false;
                }
                this.log('info', 'business details',JSON.stringify(this.businessDetails));
                this.isSearching = false;
            })
            .catch(error => {
                console.log("error", JSON.stringify(error));
                this.isSearching = false;
            });
    }
    /**
     *
     */
    searchReviews() {
        const params = {businessId: this.businessClicked.id };
        this.log('info',this._className + ' calling retrieveReviews with prams', JSON.stringify(params));
        this.isSearching = true;
        retrieveReviews(params)
            .then(result => {
                let dto = result;
                if (dto.isSuccess) {
                    this.reviews = this._accelUtils.getMapValue('BLAH', dto.values);
                } else {
                    this.log('error', 'error getting reviews', JSON.stringify(dto));
                }
                this.log('info', '----> reviews:',JSON.stringify(this.reviews));
                this.isSearching = false;
            })
            .catch(error => {
                console.log("error", JSON.stringify(error));
                this.isSearching = false;
            });
    }
    parseBusinessDetails() {
        if(this.businessDetails) {
            console.log(JSON.stringify(this.businessDetails));
            if(this.businessDetails.photos && this.businessDetails.photos.length > 1) {
                this.showPhotoCarousel = true;
            } else {
                this.showPhotoCarousel = false;
            }
        }
    }
    /**
     * Loads font awesome js and css for fonts not available in SLDS.
     * @todo only load what is needed. we are probably loading too much here.
     */
    loadFontAwesome() {
        Promise.all([
            loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/all.css'),
        ])
            .then(() => {
                this.log( 'debug',' === loaded font awesome ===');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }
    /**
     *
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
            if(this._className) {
                msg = this._className + ' - ' + msg;
            }
            switch (logType) {
                case DEBUG:
                    this._logger.logDebug(msg,obj);
                    break;
                case ERROR:
                    this._logger.logError(msg,obj);
                    break;
                case INFO:
                    this._logger.logInfo(msg,obj);
                    break;
                default:
                    this._logger.log(msg, obj);
            }
        }
    }
}