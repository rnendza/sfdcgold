import {api, LightningElement, track, wire} from 'lwc';
import retrieveBusinesses from '@salesforce/apex/YelpSearchController.retrieveBusinesses';
import retrieveCategories from '@salesforce/apex/YelpSearchController.retrieveCategories';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/pubSub';
import Logger from "c/logger";
import AccelUtilsSvc from 'c/accelUtilsSvc';

const MAP_KEY_BUSINESS_RESULTS          = 'MAP_KEY_BUSINESS_RESULTS';
const MAP_KEY_FILTERED_CATEGORIES       = 'MAP_KEY_FILTERED_CATEGORIES';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class YelpBusinessSearch extends LightningElement {

    _debugConsole = true;
    _className = 'YelpBusinessSearch';
    _logger = new Logger(this._debugConsole);
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _radiusMeters = 16093;

    @track location = 'Chicago';
    @track longitude = null;
    @track latitude  = null;
    @track geoAddressSelected = null;
    @track selectedLocation = this.location;
    @track term = 'Slots';
    @track termEntered = '';
    @track options = [];
    @track selectedOption = 'bars';
    @track selectedCategories = [];
    @track searchButtonDisabled;
    @track hasRendered = false;
    @track businesses = [];
    @track loadedOnce = false;
    @track searchedOnce = false;

    @api
    get radius() {
        return this._radiusMeters;
    }
    set radius(val) {
        if(val) {
            this._radiusMeters = Math.round(val * 1609);
        }
    }


    @api   displayCategories = [];

    @wire(CurrentPageReference) pageRef;

    @api
    get cardTitle() {
        return 'Yelp Search';
    }


    constructor() {
        super();
        this.searchButtonDisabled = true;
    }
    /**
     *
     */
    connectedCallback() {
        this.log(' === connected callback ===');
        this.selectedCategories.push(this.selectedOption);
        this.searchCategories();
       //----------------- this.searchBusinesses();
    }

    renderedCallback() {
        if(!this.hasRendered) {
            this.hasRendered = true;
        }
    }
    /**
     *
     */
    searchCategories() {
        const params = {locale : 'en_US', parentAliases : ['nightlife','casinos','bettingcenters','sportsbetting'] };
        this.log(this._className + ' calling retrieveCategories with prams', JSON.stringify(params));
        fireEvent(this.pageRef, 'isSearching', true);
        retrieveCategories(params)
            .then(result => {
                let dto = result;
                if (dto.isSuccess) {
                    let cats = this._accelUtils.getMapValue(MAP_KEY_FILTERED_CATEGORIES, dto.values);
                    this.shapeCategories(cats);
                    this.log('info', 'shape categories:',JSON.stringify(cats));
                } else {
                    this.log('error', 'error getting cats', JSON.stringify(dto));
                }
               // fireEvent(this.pageRef, 'isSearching', false);
            })
            .catch(error => {
                console.log("error", JSON.stringify(error));
                fireEvent(this.pageRef, 'isSearching', false);
            });
    }
    /**
     *
     */
    searchBusinesses() {
        const params = {
            location: this.location, latitude: this.latitude, longitude: this.longitude,
            term: this.term, categories: this.selectedCategories, radiusMeters: this._radiusMeters
        };
        this.log('info',this._className + ' calling retrieveBusinesses with prams', JSON.stringify(params));
        fireEvent(this.pageRef, 'isSearching', true);
        retrieveBusinesses(params)
            .then(result => {
                this.searchedOnce = true;
                let dto = result;
                if (dto.isSuccess) {
                    let tmpBusinesses =  this._accelUtils.getMapValue(MAP_KEY_BUSINESS_RESULTS, dto.values);
                    //alert(JSON.stringify(tmpBusinesses.businesses));
                    if(tmpBusinesses && Array.isArray(tmpBusinesses.businesses)) {
                        //clone so we can mutate the array!
                        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item); // magic deep clone!
                        this.businesses = clone(tmpBusinesses.businesses);
                        this.addPropertiesToBusinesses(this.businesses);

                    }
                    //alert('aray='+Array.isArray(this.businesses));
                } else {
                    this.log('error', 'error getting businesses', JSON.stringify(dto));
                    this.businesses = [];
                }
                fireEvent(this.pageRef, 'termModified', this.term);
                fireEvent(this.pageRef, 'locationSelected', this.geoAddressSelected);
                fireEvent(this.pageRef, 'categoriesSelected', this.selectedCategories);
                fireEvent(this.pageRef, 'locationListUpdate', this.businesses);
                this.log('info', 'businesses:',JSON.stringify(this.businesses));
                fireEvent(this.pageRef, 'isSearching', false);
                this.loadedOnce = true;
            })
            .catch(error => {
                this.searchedOnce = true;
                console.log("error", JSON.stringify(error));
                this.loadedOnce = true;
                fireEvent(this.pageRef, 'isSearching', false);
            });
    }
    addPropertiesToBusinesses(businesses) {
        if(businesses && Array.isArray(businesses)) {
            let idx = 1;
            businesses.forEach((business,idx) =>  {
                console.log(business);
                let oBusiness = Object.assign({},business);
                oBusiness.idx = idx;
                businesses[idx] = oBusiness;
                idx++;
            });
        }
    }

    /**
     *
     * @param yelpCategories
     */
    shapeCategories( yelpCategories ) {
        if(yelpCategories && Array.isArray(yelpCategories)) {
            this.displayCategories = [];
            this.options = [];
            yelpCategories.forEach(x =>  {
                let optionSelected = false;
                if(x.alias === this.selectedOption || x.title === this.selectedOption) {
                    optionSelected = true;
                }
                let displayCat = {key: x.alias, value: x.title};
                let option = {value: x.alias, label:x.title, selected:optionSelected };
                this.options.push(option);
                this.displayCategories.push(displayCat);
            });
        }
    }
    /**
     *
     * @param event
     */
    handleCategoryChange(event) {
        if(event.detail) {
            let valueSelected = event.detail.value;
            this.selectedCategories = [];
            this.selectedCategories.push(valueSelected);
            this.searchBusinesses();
            console.log(valueSelected);
        }
    }
    /**
     *
     * @param event
     */
    selectionChangeHandler(event) {
        if(event.target) {
            let valueSelected = event.target.value;
            this.selectedCategories = [];
            this.selectedOption = valueSelected;
            this.selectedCategories.push(valueSelected);
            this.searchBusinesses();
            console.log(valueSelected);
        }
    }
    handleSearch(event) {
        this.searchBusinesses();
    }
    handleTermChange(event) {
        if (event.detail) {
            console.log(event.detail.value);
            this.termEntered = event.detail.value;
            this.term = this.termEntered;
            this.searchButtonDisabled = this.term.length <= 3;
        }
    }
    handleLocationChange(event) {
        if (event.detail) {
            console.log(event.detail.value);
            this.location = event.detail.value;
        }
    }

    /**
     *
     * @param event
     */
    handleGeoAddressSelected(event) {
        let geoAddressSelected = event.detail.value;
        this.log(DEBUG, 'geoAddressSelected:',JSON.stringify(geoAddressSelected));
        if( geoAddressSelected ) {
            this.geoAddressSelected = geoAddressSelected;
            let lat = geoAddressSelected.lat;
            let long = geoAddressSelected.lon;
            if(lat && long) {
                this.latitude = lat;
                this.longitude = long;
                this.location = geoAddressSelected.display_address;
                this.selectedLocation = this.location;
                this.searchBusinesses();
            }
        }
    }
    /**
     *
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
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