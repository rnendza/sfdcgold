import {LightningElement, wire, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import Logger from 'c/logger'
import retrieveServiceResources from '@salesforce/apex/GeoTabApiController.retrieveServiceResources';
import {dtHelper} from "./goTabSvcResourceDtHelper";
import {mapHelper} from "./geoTabSvcResourceLocationMapHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_SR_WRAPS       = 'SERVICE_RESOURCE_WRAPS';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const DEVICE_ROW_LIMIT = 5000;
const NUM_REFRESHES_ALLOWED_PER_MINUTE = 5;

export default class GeoTabSvcResourceLocation extends LightningElement {
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api assistanceTitle = 'Devices Status Info Assistant'
    @api cardTitle = 'Service Resource Locations';

    @track devicesStatusInfo;
    @track dtRecords;
    @track dtRecordsFiltered;
    @track columns = dtHelper.getServiceResourceColumns();
    @track dtClasses = dtHelper.getDtClasses();
    @track sortDirection = 'asc';
    @track sortBy = 'sfdcName';
    @track serviceResourceState;
    @track srBulletPoints;
    @track serviceResources;
    @track mapMarkers;


    _debugConsole;
    _logger;
    _isLoading;
    _dataRefreshTime;
    _displayMapView;
    _displayTableView = true;
    _numRefreshes = 0;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/geoTabServiceResourceLocations', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.doRetrieveServiceResourceLocation()
    }


    doRetrieveServiceResourceLocation() {
        this._isLoading = true;
        retrieveServiceResources( )
            .then((data) => {
                this.log(DEBUG, 'service resources dto->', data);
                let tmpSrs = uiHelper.getMapValue(MAP_KEY_SR_WRAPS,data.values);
                this.dtRecords = this.shapeServiceResourceData(tmpSrs);
                this.dtRecords = dtHelper.sortData(this.sortBy,this.sortDirection,this.dtRecords);
                this.dtRecordsFiltered = this.dtRecords;
                this.mapMarkers = mapHelper.buildMapMarkers(this.dtRecordsFiltered);
                this.log(DEBUG, 'devices status imperative table data-->', this.dtRecords);
                this._dataRefreshTime = new Date().getTime();
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading Service Resource Data '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }


    shapeServiceResourceData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = wraps;
            tmp.forEach(wrap => {
                let record = {};
                record.serviceResourceId = wrap.recordId;
                record.serviceResourceName = wrap.name;
                if(record.serviceResourceId) {
                    record.sfdcName = record.serviceResourceName;
                    record.sfdcUrl = '/'+record.serviceResourceId;
                }
                record.deviceId = wrap.deviceId;
                record.latitude = wrap.lat;
                record.longitude = wrap.lng;
                record.lastKnownLocationDate = wrap.lastKnownLocDate;
                records.push(record);
            });
        }
        return records;
    }

    /**
     * Sort the datatable column.
     * @param evt
     */
    handleSort(evt){
        this.sortBy = evt.detail.fieldName;
        let tmpSortBy = this.sortBy;
        this.sortDirection = evt.detail.sortDirection;
        this.log(DEBUG,'sort by',tmpSortBy);
        this.dtRecordsFiltered = dtHelper.sortData(tmpSortBy,this.sortDirection,this.dtRecordsFiltered);

        let payload = {sortBy:this.sortBy,sortDirection:this.sortDirection};
        this.dispatchEvent( new CustomEvent('dtsorted',{detail:payload}));
    }

    handleRefresh(evt) {
        this.doRetrieveServiceResourceLocation();
    }

    handleIconButtonClick(evt) {
        const buttonId = evt.currentTarget.dataset.iconbuttonid;
        this.log(DEBUG,'buttonId',buttonId);
        if(buttonId === 'btnDisplayMap') {
            this._displayMapView = true;
            this._displayTableView = false;
        } else if (buttonId === 'btnDisplayTable') {
            this._displayMapView = false;
            this._displayTableView = true;
        } else if (buttonId === 'btnExportPdf') {
            this.processPdfButtonClick();
        }
    }

    get showDataTable() {
        return !this._isLoading && this.dtRecords && this.displayTableView;
    }
    get showMap() {
        return !this._isLoading && this.dtRecordsFiltered && this.displayMapView;
    }
    get showProgressBar() {
        return this._isLoading;
    }
    get showStencil() {
        return this._isLoading;
    }
    get dtKeyField() {
        return 'serviceResourceId';
    }
    get numberOfResults() {
        return this.dtRecords ? this.dtRecords.length : 0;
    }
    get filteredNumberOfResults() {
        return this.dtRecordsFiltered ? this.dtRecordsFiltered.length : 0;
    }

    get tableIconClass() {
        let cls = '';
        if(this._displayTableView) {
            cls += ' slds-m-left_xx-small accel-blue-icon';
        } else {
            cls += ' slds-m-left_xx-small';
        }
        return cls;
    }

    get displayMapView() {
        return ( this._displayMapView );
    }

    get displayTableView() {
        return ( this._displayTableView);
    }

    /**
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger && this.debugConsole) {
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