import {LightningElement, wire, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import Logger from 'c/logger'
import retrieveDevicesStatusInfo from '@salesforce/apex/GeoTabApiController.retrieveAllDevicesStatusInfo';
import retrieveServiceResourceState from '@salesforce/apex/GeoTabApiController.retrieveCurrentServiceResourceState';
import {dtHelper} from "./geoTabAdminDeviceStatusDtHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_DEVICES_STATUS_INFO       = 'DEVICES_STATUS_INFO';
const MAP_KEY_SERVICE_RESOURCE_STATE    = 'SR_STATE';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const DEVICE_ROW_LIMIT = 5000;
const NUM_REFRESHES_ALLOWED_PER_MINUTE = 5;

export default class GeoTabAdminDeviceStatus extends LightningElement {
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api assistanceTitle = 'Devices Status Info Assistant'
    @api cardTitle = 'GeoTab Device Status';

    @track devicesStatusInfo;
    @track dtRecords;
    @track dtRecordsFiltered;
    @track columns = dtHelper.getDevicesStatusColumns();
    @track dtClasses = dtHelper.getDtClasses();
    @track sortDirection = 'asc';
    @track sortBy = 'deviceId';
    @track serviceResourceState;
    @track srBulletPoints;
    @track serviceResources;


    _debugConsole;
    _logger;
    _wiredStateDto;
    _isLoading;
    _dataRefreshTime;
    _filterServiceResourcesOnly;
    _numRefreshes = 0;
    _numRefreshesAllowedPerMinute = NUM_REFRESHES_ALLOWED_PER_MINUTE;
    _waitSeconds = 0;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/geoTabAdminDeviceStatus', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.retrieveAllDevicesStatusInfo({iLimit:DEVICE_ROW_LIMIT});
    }


    retrieveAllDevicesStatusInfo(params) {
        this._isLoading = true;
        retrieveDevicesStatusInfo( params )
            .then((data) => {
                this.log(DEBUG, 'devices status info dto->', data);
                let tmpInfos = uiHelper.getMapValue(MAP_KEY_DEVICES_STATUS_INFO,data.values);
                this.devicesStatusInfo = this.shapeDevicesTableData(tmpInfos);
                this.dtRecords = this.devicesStatusInfo;
                this.dtRecordsFiltered = this.dtRecords;
                this.log(DEBUG, 'devices status imperative table data-->', this.dtRecords);
                this._dataRefreshTime = new Date().getTime();
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading device Status Info: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    @wire(retrieveServiceResourceState)
    wiredState(wiredData) {
        this._wiredStateDto = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.serviceResourceState = uiHelper.getMapValue(MAP_KEY_SERVICE_RESOURCE_STATE,data.values);
                this.log(DEBUG,'state-->',this.serviceResourceState);
                this.generateAssistanceBulletPoints();
            }
        } else if (error) {
            console.error(error);
        }
    }

    shapeDevicesTableData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = wraps;
            tmp.forEach(wrap => {
                let record = {};
                record.serviceResourceId = wrap.serviceResourceId;
                record.serviceResourceName = wrap.serviceResourceName;
                if(record.serviceResourceId) {
                    record.sfdcName = record.serviceResourceName;
                    record.sfdcUrl = '/'+record.serviceResourceId;
                }
                record.deviceId = wrap.statusInfo.device.id;
                record.dateTime = wrap.statusInfo.dateTime_x;
                record.latitude = wrap.statusInfo.latitude;
                record.longitude = wrap.statusInfo.longitude;
                record.bearing = wrap.statusInfo.bearing;
                record.speed = wrap.statusInfo.speed;
                record.speedMph = wrap.speedMph;
                record.isDriving = wrap.statusInfo.isDriving;
                record.bearing = wrap.statusInfo.bearing;
                record.currentStateDuration = wrap.statusInfo.currentStateDuration;
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
        if(this.allowRefresh()) {
            this.retrieveAllDevicesStatusInfo({iLimit: DEVICE_ROW_LIMIT});
            this._numRefreshes++;
        } else {
            let msg = 'You are not allowed to refresh more than '+this._numRefreshesAllowedPerMinute +
                ' times in a minute. Please wait '+ this._waitSeconds + ' seconds.';
            uiHelper.showToast(this,'Not Allowed!',msg,'warning','sticky');
        }
    }

    handleSrChkBoxClick(evt) {
        this._filterServiceResourcesOnly = evt.target.checked;
        this.doFilterDtRecords();
    }

    doFilterDtRecords() {
        if(this._filterServiceResourcesOnly) {
            this.dtRecordsFiltered = this.dtRecords.filter(rec => rec.serviceResourceId);
        } else {
            this.dtRecordsFiltered = this.dtRecords;
        }
    }

    /**
     * Bullet points for child assistant / help cmp.
     */
    generateAssistanceBulletPoints() {
        this.srBulletPoints = [];

        let msg = '<i>Total Active Service Resources:</i><b> '+this.serviceResourceState.totalActiveServiceResources+'</b>';
        this.srBulletPoints.push({text: msg, severity: 'info'});
        msg = '<i>Total Active Service Resources With GeoTabId__c:</i><b> '+this.serviceResourceState.totalActiveServiceResourcesWithGeoTabId+'</b>';
        this.srBulletPoints.push({text: msg, severity: 'info'});
        let cls;
        if(this.serviceResourceState.totalActiveServiceResourcesWithoutGeoTabId === 0) {
            cls='slds-text-color_destructive';
        }
        msg = '<span class="'+cls+'"><i>Total Active Service Resources Without GeoTabId__c:</i><b> '+this.serviceResourceState.totalActiveServiceResourcesWithoutGeoTabId+'</b></span>';
        this.srBulletPoints.push({text: msg, severity: 'info'});
    }

    /**
     * GeoTab only allows 10 REST calls per minute. limit to 5 just to be safe.
     * @returns {boolean}
     */
    allowRefresh() {
        this._waitSeconds = 0;
        let allowIt = true;
        let dtNow = new Date().getTime();
        let dtLastRefresh = this._dataRefreshTime;
        let dif = (dtNow - dtLastRefresh) / 1000;
        if(dif <= 60) {
            this._waitSeconds = Math.round(60 - dif);
            if(this._numRefreshes >= this._numRefreshesAllowedPerMinute) {
                allowIt = false;
            }
        }
        return allowIt;
    }
    get showDataTable() {
        return !this._isLoading && this.dtRecords;
    }
    get showProgressBar() {
        return this._isLoading;
    }
    get showStencil() {
        return this._isLoading;
    }
    get dtKeyField() {
        return 'deviceId';
    }
    get numberOfResults() {
        return this.dtRecords ? this.dtRecords.length : 0;
    }
    get filteredNumberOfResults() {
        return this.dtRecordsFiltered ? this.dtRecordsFiltered.length : 0;
    }
    get srBulletPointCategory() {
        return 'Current State of ServiceResource sObject:';
    }
    get linkedToResourcesLabel() {
        let label = 'Linked to Svc Resources';
        if(this.serviceResourceState) {
            label+= ' ('+this.serviceResourceState.totalActiveServiceResourcesWithGeoTabId+')';
        }
        return label;
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