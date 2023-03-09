import {LightningElement, api, track, wire } from 'lwc';
import LEAFLET_MAPS from '@salesforce/resourceUrl/leaflet_1_8_dev'  //  @todo newest in dev (may have to revert to stable)
import { loadStyle, loadScript } from 'lightning/platformResourceLoader'
import { registerListener, unregisterAllListeners } from 'c/pubSub'; //  @todo replace with lms
import { CurrentPageReference } from 'lightning/navigation';
import MapUiHelper from "./clMapHelper";
import { getConstants } from 'c/clConstantUtil';

const MAP_MAX_ZOOM = 20;
const MAP_MIN_ZOOM = 2;
const GLOBAL_CONSTANTS = getConstants();

export default class ClMap extends LightningElement {

    //  Public API
    @api mapContainerClass = 'accel-cl-map-container';
    @api mapHeight = '500px';
    @api mapboxStyleUrlSuffix = 'mapbox/satellite-streets-v11';
    @api mapDefaultZoom;
    @api mapMaxZoom;
    @api mapMinZoom;
    @api originGeo;
    @api destinationGeo;
    @api defaultCenterGeo;
    @api mapProviderAccessToken;    // required!

   /**
    *  @type {{iconAnchor: number[], iconSize: number[], className: string, html: string}}
    */
    @api customOriginMarkerIconInfo;

    //  Private
    @track map;
    @track mapUiState = {};

    _leafletLoaded;
    _mapInitialized;
    _hasRendered;
    _userCurrentPosition;
    _mapUiHelper = new MapUiHelper();

    constructor() {
        super();
        console.info('%c----> /lwc/clMap',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._userCurrentPosition = this._mapUiHelper.getUserCurrentPosition();
    }

    connectedCallback() {
        if(!this.defaultCenterGeo) {
            this.defaultCenterGeo = this._mapUiHelper.getDefaultCenterGeo();   //  @todo we might not want this.
        }
        this.initMapUiState();
        this.registerAllPubSubListeners();
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            this.loadLeaflet();
        }
    }

    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    @wire(CurrentPageReference)
    pageRef;

    initMap() {
        try {
            let mapEl = this.template.querySelector('.map-root');
            if(mapEl) {
                if (this.mapHeight) {
                    mapEl.style = 'height: ' + this.mapHeight + ';';
                }
                if (this.map) {
                    this._mapUiHelper.removeMap(this.map);
                }
                this.map = L.map(mapEl);
                this._mapUiHelper.setMapTileLayer(this.mapUiState,this.map);
                this.setMapCenterPoint();
                this.addDestinationMarker();
                this._mapInitialized = true;
                console.log('--> map initialized');
            } else {
                this._mapInitialized = true;
                console.error('---> could not find map container element!');
            }
        } catch (e) {
            console.error('--> initializing map error! ',e);
        }
    }

    /**
     * If an originGeo object is passed, use that as map center
     *   Else if a default center geo object is passed use that as map center
     *      Else if all else fails try to user the users current location as map center.
     */
    setMapCenterPoint() {
        let rZoom = this.mapDefaultZoom ? this.mapDefaultZoom : 8;
        let lat, lng;
        let centerPointFrom = '';
        if (this.originGeo) {
            lat = this.originGeo.latitude;
            lng = this.originGeo.longitude;
            centerPointFrom = 'origin';
        } else if (this.defaultCenterGeo) {
            lat = this.defaultCenterGeo.latitude;
            lng = this.defaultCenterGeo.longitude;
            centerPointFrom = 'default';
        } else if (this._userCurrentPosition) {
            let coordinates = this._userCurrentPosition.coords;
            lat = coordinates.latitude;
            lng = coordinates.longitude;
            centerPointFrom = 'user current position';
        }
        if(!lat || !lng) {
            console.info('-----> clMaps parent passed no lat / long into component aborting display!');
            return;
        }
        let marker = L.marker([lat, lng]);
        marker.addTo(this.map);
        this.map.setView([lat, lng], rZoom);
        console.log('---> set map center point lat=' + lat + '.. lng=' + lng + '.. using '+centerPointFrom);
    }

    addDestinationMarker() {
        if(this.destinationGeo) {
            this._mapUiHelper.addMapMarkerMarker(this.map,this.destinationGeo)
        }
    }

    initMapUiState() {
        this.mapUiState.accessToken = this.mapProviderAccessToken;
        this.mapUiState.maxZoom = this.mapMaxZoom ? this.mapMaxZoom : MAP_MAX_ZOOM;
        this.mapUiState.minZoom = this.mapMinZoom ? this.mapMinZoom : MAP_MIN_ZOOM;
        this.mapUiState.mapboxStyleUrlSuffix = this.mapboxStyleUrlSuffix;
        this.mapUiState.tileSize = 512;
        this.mapUiState.zoomOffset = -1;
        this.mapUiState.customOriginMarkerIconInfo = this.customOriginMarkerIconInfo;
    }

    handleOriginGeoUpdated(originGeo) {
        console.log('--> handleOriginGeoUpdated',originGeo);
        if(originGeo) {
            this.originGeo = originGeo;
            //  @todo do we need to reinit the entire map or some remove / add markers?
            this.initMap();
        }
    }

    handleDestinationGeoUpdated(destinationGeo) {
        console.log('--> handleDestinationGeoUpdated',destinationGeo);
        if(destinationGeo) {
            this.destinationGeo = destinationGeo;
            this.initMap();
        }
    }

    loadLeaflet() {
        Promise.all([
            loadStyle(this, LEAFLET_MAPS + '/leaflet.css'),
            loadScript(this, LEAFLET_MAPS + '/leaflet.js')
        ]).then(() => {
            console.log('--> all leaflet resources loaded');
            this._leafletLoaded = true;
            this.initMap();
        }).catch(error => {
            console.error(error);
        });
    }

    registerAllPubSubListeners() {
        registerListener('originGeoUpdated', this.handleOriginGeoUpdated, this);
        registerListener('destinationGeoUpdated', this.handleDestinationGeoUpdated, this);
    }
}