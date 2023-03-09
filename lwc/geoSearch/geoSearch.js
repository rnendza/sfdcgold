import { LightningElement, track, api } from 'lwc';
import retrieveGeocodeAutocompleteAddresses from '@salesforce/apex/GeocodeSearchController.retrieveGeocodeAutocompleteAddresses';
import retrieveReverseGeocodeAddress from '@salesforce/apex/GeocodeSearchController.retrieveReverseGeocodeAddress';
import Logger from "c/logger";
import AccelUtilsSvc from 'c/accelUtilsSvc';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class GeoSearch extends LightningElement {

    //  General Utility / Logging stuff
    _hasRendered    = false;
    _debugConsole   = true;
    _className      = 'GeoSearch';
    _logger         = new Logger(this._debugConsole);
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);
    _anySearchEntered = false;
    _userCurrentPosition;

    //  Private / Reactive
    @track  geoAddresses = [];
    @track  geoComboboxCssClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track term = '';
    @track placeholder = '';

    //  Public / Reactive
    @api        defaultTerm = '';
    @api        attemptDefaultUserCurrentPosition = false;
    @api        defaultPlaceholder = '';
    @api        defaultCoords;


    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
            this.getDefaultLocation();
        }
    }
    getDefaultLocation() {
        if(this.attemptDefaultUserCurrentPosition) {
            this.getUsersCurrentPosition();
        } else  {
            if( this.defaultTerm && this.defaultTerm !== '') {
                this.term = this.defaultTerm;
                this.searchForGeoData(this.term);
            } else {
                if (this.defaultPlaceholder && this.defaultPlaceholder !== '') {
                    this.placeholder = this.defaultPlaceholder;
                }
            }
        }
    }
    getUsersCurrentPosition() {
        navigator.geolocation.getCurrentPosition(position => {
            var crd = position.coords;
            console.log('Your current position is:');
            console.log('Latitude : '+crd.latitude);
            console.log(crd);
            this._userCurrentPosition = position;
            if(position) {
                this.searchForReverseGeocodeAddress();
            }
        });
    }
    /**
     *
     * @param event
     */
    handleGeoInputChange(event) {
        let value = event.target.value;
        this.term = value;
        if(value && value.length > 2) {
            this._anySearchEntered = true;
            this.searchForGeoData(value);
        } else {
            if(!value) {
                this.geoAddresses = [];
                this.shapeGeoData();
            }
        }
    }
    /**
     *
     * @param event
     */
    handleGeoAddressClicked(event) {
        let placeId = event.currentTarget.dataset.id;
        let geoAddressClicked = this.geoAddresses.find(x => x.place_id === placeId);
        this.log( DEBUG, 'geoAddressClicked: ', JSON.stringify(geoAddressClicked));
        if(geoAddressClicked) {
            let geoInput = this.template.querySelector('[data-id="geoinput"]');
            this.term = geoAddressClicked.display_name;
            this.closeAutocompleteTrigger();
            this.dispatchEvent(new CustomEvent('geoaddressselected', {
                bubbles: false,
                detail: {value: geoAddressClicked}
            }))
        }
    }

    /**
     *
     * @param event
     */
    handleGeoMenuBlur(event) {
        console.warn('blur');
    }
    /**
     *
     * @param event
     */
    handleGeoInputFocus(event) {
        if(this.geoAddresses && Array.isArray(this.geoAddresses) && this.geoAddresses.length > 0) {
            this.openAutocompleteTrigger();
        }
        console.warn('blur');
    }
    /**
     *
     * @param term
     */
    searchForGeoData(term) {
        const params = { term: term };
        this.log( DEBUG, 'calling searchForGeoData with prams', JSON.stringify(params));

        retrieveGeocodeAutocompleteAddresses(params)
            .then(result => {
                let dto = result;
                let geoData = [];
                if (dto.isSuccess) {
                    geoData = this._accelUtils.getMapValue('MAP_KEY_GEO_JSON_RESULTS', dto.values);

                } else {
                    this.log(ERROR, 'error getting geo data', JSON.stringify(dto));
                }
                this.shapeGeoData(geoData);
            })
            .catch(error => {
                this.log(ERROR, 'error on SS Call', JSON.stringify(error));
            });
    }
    searchForReverseGeocodeAddress() {
        let lat = this._userCurrentPosition.coords.latitude;
        let long = this._userCurrentPosition.coords.longitude;
        const params = { latitude: lat, longitude: long };
        this.log( DEBUG, 'calling seachForReverseGeocodeAddress with prams', JSON.stringify(params));

        retrieveReverseGeocodeAddress(params)
            .then(result => {
                let dto = result;
                let geoData = [];
                if (dto.isSuccess) {
                    geoData = this._accelUtils.getMapValue('MAP_KEY_REVERSE_GEOCODE_ADDRESS', dto.values);
                    this.term = geoData.display_name;
                    this.dispatchEvent(new CustomEvent('geoaddressselected', {
                        bubbles: false,
                        detail: {value: geoData}
                    }));
                    this.searchForGeoData(this.term)

                } else {
                    this.log(ERROR, 'error getting geo data', JSON.stringify(dto));
                }
                //this.shapeGeoData(geoData);
            })
            .catch(error => {
                this.log(ERROR, 'error on SS Call', JSON.stringify(error));
            });
    }
    /**
     *
     * @param geoData
     */
    shapeGeoData(geoData) {
        this.geoAddresses = geoData;
        this.highlightSearchTerms();
        if(this.geoAddresses && this._anySearchEntered) {
            this.openAutocompleteTrigger();
        } else {
            this.closeAutocompleteTrigger();
        }
        this.log(INFO, 'geoAddresses:',JSON.stringify(this.geoAddresses));
    }
    closeAutocompleteTrigger() {
        this.geoComboboxCssClass = 'lds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    }
    openAutocompleteTrigger() {
        this.geoComboboxCssClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
    }
    /**
     *
     */
    highlightSearchTerms() {
        if(this.geoAddresses && Array.isArray(this.geoAddresses) && this.term) {
            //let searchTerm;
            let searchTerm = Object.assign({},this.term);
            // alert(JSON.stringify(searchTerm));
            // if(searchTerm)  {
            //     this.geoAddresses.forEach(x => {
            //         searchTerm = searchTerm.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
            //         let regExp = new RegExp(searchTerm, 'g');
            //         if (searchTerm.length > 0) {
            //             x.name = x.name.replace(regExp, '<mark>$&</mark>');
            //         }
            //         //else paragraph.innerHTML = opar;
            //     });
            // }
        }
    }
    /**
     *
     * @param logType  The type of log (see the constants). (optional)
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
            if(msg) {
                if(this._className) {
                    msg = this._className + ' - ' + msg;
                }
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