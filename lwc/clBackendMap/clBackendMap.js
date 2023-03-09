import {api, wire, track, LightningElement} from 'lwc';
import {getRecord, getFieldValue} from 'lightning/uiRecordApi';
import ROUTE_FIELD from '@salesforce/schema/Route_Schedule__c.Route__c';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import { getConstants } from 'c/clConstantUtil';

import retrieveReverseGeoAddy from '@salesforce/apex/clMapController.retrieveReverseGeoAddy';

//@todo  the below is due to a bug in SFDC referencing geo fields.
//const ROUTE_SCH_CURRENT_GEO_LAT_FIELD = 'Route_Schedule__c.Route__r.Geolocation__Latitude__s';
//const ROUTE_SCH_CURRENT_GEO_LNG_FIELD = 'Route_Schedule__c.Route__r.Geolocation__Longitude__s';
const ROUTE_SCH_CURRENT_GEO_LAT_FIELD = 'Route_Schedule__c.Current_Geolocation__Latitude__s';
const ROUTE_SCH_CURRENT_GEO_LNG_FIELD = 'Route_Schedule__c.Current_Geolocation__Longitude__s';
const ROUTE_CURRENT_GEO_LAT_FIELD = 'Route__c.Geolocation__Latitude__s';
const ROUTE_CURRENT_GEO_LNG_FIELD = 'Route__c.Geolocation__Longitude__s';

const ROUTE_SCHEDULE_FIELDS = [ROUTE_FIELD,ROUTE_SCH_CURRENT_GEO_LAT_FIELD,ROUTE_SCH_CURRENT_GEO_LNG_FIELD];
const ROUTE_FIELDS = [ROUTE_CURRENT_GEO_LAT_FIELD,ROUTE_CURRENT_GEO_LNG_FIELD];
const GLOBAL_CONSTANTS = getConstants();
const MAPBOX_ACCESS_TOKEN = 'pk.eyJ1IjoiYWNjZWxlbnQiLCJhIjoiY2s2am54emM0MGRzbTNsbnVyYmVqaXpncCJ9.YsdKgiAYZ-drheOX_CGuxQ';

export default class ClBackendMap extends LightningElement {

    //  Public API
    @api cardTitle = 'Route Map'
    @api mapContainerClass = 'accel-cl-map-container';
    @api mapHeight = '400px';
    @api mapboxStyleUrlSuffix = 'mapbox/satellite-streets-v11';
    @api mapDefaultZoom;
    @api mapMaxZoom;
    @api mapMinZoom;
    @api originGeo;
    @api destinationGeo;
    @api defaultCenterGeo;
    @api mapProviderAccessToken = '';    // required!
    @api isReverseGeoOriginAddress = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(val) {
        this._recordId = val;
    }
    @api
    get objectApiName() {
        return this._objectApiName;
    }
    set objectApiName(val) {
        this._objectApiName = val;
    }

    //  Private
    @track routeId;
    @track routeScheduleId;
    @track formattedAddress;
    @track originGeoToReverseLookup;

    _wiredGeoAddyDto;
    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _recordId;
    _objectApiName;

    constructor() {
        super();
        console.info('%c----> /lwc/clBackendMap',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        console.log('back end map con cb');
        switch (this.objectApiName) {
            case 'Route_Schedule__c':
                this.routeScheduleId = this.recordId;
                break;
            case 'Route__c':
                this.routeId = this.recordId;
                break;
            default:
                console.log('unsupported object ');
        }
    }

    @wire(getRecord, {recordId: '$routeScheduleId', fields: ROUTE_SCHEDULE_FIELDS})
    wiredRouteScheduleRecord({error, data}) {
        if(data) {
            this.findGeoValues(data,ROUTE_SCH_CURRENT_GEO_LAT_FIELD, ROUTE_SCH_CURRENT_GEO_LNG_FIELD);
        } else if (error) {
            this.processError(error);
        }
    }

    @wire(getRecord, {recordId: '$routeId', fields: ROUTE_FIELDS})
    wiredRouteRecord({error, data}) {
        if(data) {
            this.findGeoValues(data, ROUTE_CURRENT_GEO_LAT_FIELD, ROUTE_CURRENT_GEO_LNG_FIELD);
        } else if (error) {
            this.processError(error);
        }
    }

    @wire(retrieveReverseGeoAddy, {geoCoordinates: '$originGeoToReverseLookup'})
    wiredRetrieveAddy(wiredDto) {
        this._wiredGeoAddyDto = wiredDto;
        const {data, error} = this._wiredGeoAddyDto;
        if (data) {
            //console.log('---> dto=', JSON.parse(JSON.stringify(data)));
            if (data.isSuccess) {
                this.formattedAddress = this._accelUtils.getMapValue('FORMATTED_ADDRESS', data.values);
            } else {
                console.log('---> could not find address for coords:' + this.originGeo);
            }
        } else if (error) {
            this.processError(error);
        }
    }

    findGeoValues(data, latField, lngField) {
        const lat = getFieldValue(data, latField);
        const lng = getFieldValue(data, lngField);
        this.originGeo = {latitude: lat, longitude: lng};
        if (this.isReverseGeoOriginAddress) {
            this.originGeoToReverseLookup = this.originGeo;
        }
    }

    processError(error) {
        console.error(error);
    }

    get mapProviderAccessToken() {
        return MAPBOX_ACCESS_TOKEN;
    }


    //  @see clMap (publish these events to ensure map refresh if needed!
    //registerListener('originGeoUpdated', this.handleOriginGeoUpdated, this);
    //registerListener('destinationGeoUpdated', this.handleDestinationGeoUpdated, this);
}