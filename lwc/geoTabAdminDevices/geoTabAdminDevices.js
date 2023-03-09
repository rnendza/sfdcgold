import {LightningElement, wire, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import Logger from 'c/logger'
import retrieveDevices from '@salesforce/apex/GeoTabApiController.retrieveAllDevices';
import retrieveServiceResourceState from '@salesforce/apex/GeoTabApiController.retrieveCurrentServiceResourceState';
import {dtHelper} from "./geoTabAdminDevicesDtHelper";
import {refreshApex} from "@salesforce/apex";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_DEVICES                   = 'DEVICES';
const MAP_KEY_SERVICE_RESOURCES         = 'SERVICE_RESOURCES';
const MAP_KEY_SERVICE_RESOURCE_STATE    = 'SR_STATE';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const DEVICE_ROW_LIMIT = 5000;

export default class GeoTabAdminDevices extends LightningElement {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api assistanceTitle = 'Devices Assistant'
    @api cardTitle = 'GeoTab Devices';

    @track devices;
    @track dtRecords;
    @track dtRecordsFiltered;
    @track columns = dtHelper.getDevicesColumns();
    @track dtClasses = dtHelper.getUserDtClasses();
    @track sortDirection = 'asc';
    @track sortBy = 'id';
    @track serviceResourceState;
    @track srBulletPoints;
    @track serviceResources;

    _debugConsole;
    _logger;
    _wiredDevicesDto;
    _wiredStateDto;
    _isLoading;
    _filterServiceResourcesOnly;
    _dataRefreshTime;
    _deviceRowLimit = DEVICE_ROW_LIMIT;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/geoTabAdminDevices', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {}

    @wire(retrieveServiceResourceState)
    wiredState(wiredData) {
        this._wiredStateDto = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.serviceResourceState = uiHelper.getMapValue(MAP_KEY_SERVICE_RESOURCE_STATE,data.values);
                this.log(DEBUG,'state-->',this.serviceResourceState);
                this.generateAssistanceBulletPoints();
                this.doDeviceLinkPrompt();
            }
        } else if (error) {
            console.error(error);
        }
    }

    @wire(retrieveDevices,{iLimit: '$_deviceRowLimit' })
    wiredDevices(wiredData) {
        this._wiredDevicesDto = wiredData;
        const {data, error} = wiredData;
        if(data) {
            this._isLoading =false;
            if(data.isSuccess) {
                let tmpDevices = uiHelper.getMapValue(MAP_KEY_DEVICES,data.values);
                this._dataRefreshTime = new Date().getTime();
                if(tmpDevices) {
                    this.devices = this.shapeDevicesTableData(tmpDevices);
                    this.dtRecords = this.devices;
                    this.dtRecordsFiltered = this.dtRecords;
                    this.log(DEBUG, 'devices table data-->', this.devices);
                }
            } else {
                if(data.severity === 'warning') {
                    uiHelper.showToast(this,'Auth Error',data.message,'warning','sticky');
                }
            }
        } else if (error) {
            this._isLoading = false;
            console.error(error);
            uiHelper.showToast(this,'','Error loading devices','error');
        }
    }

    shapeDevicesTableData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = JSON.parse(JSON.stringify(wraps));
            tmp.forEach(wrap => {
                let record = {};
                record.serviceResourceId = wrap.serviceResourceId;
                record.serviceResourceName = wrap.serviceResourceName;
                if(record.serviceResourceId) {
                    record.sfdcName = record.serviceResourceName;
                    record.sfdcUrl = '/'+record.serviceResourceId;
                }
                record.id = wrap.id;
                record.serialNumber = wrap.serialNumber;
                record.vehicleIdentificationNumber = wrap.vehicleIdentificationNumber;
                record.name = wrap.name;
                record.idleMinutes = wrap.idleMinutes;
                record.major = wrap.major;
                record.minor = wrap.minor;
                records.push(record);
            });
        }
        return records;
    }
    doDeviceLinkPrompt() {
        if (this.serviceResourceState) {
            if(this.serviceResourceState.totalActiveServiceResourcesWithGeoTabId < 1) {
                let msg = 'There are no devices linked to Service Resources at this time.';
                uiHelper.showToast(this,'Warning',msg,'info');
            }
        }
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

    handleExport(evt) {
        const payload = evt.detail;
        if (payload) {
            //this._isExporting = payload.exporting;
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
    handleRefresh(evt) {
        this._deviceRowLimit++;  // simple a hack to ensure a wire refresh;
        this.dtRecordsFiltered = null;
        this.dtRecords = null;
        this._isLoading = true;
        refreshApex(this._wiredDevicesDto);
    }

    get linkedToResourcesLabel() {
        let label = 'Linked to Svc Resources';
        if(this.serviceResourceState) {
            label+= ' ('+this.serviceResourceState.totalActiveServiceResourcesWithGeoTabId+')';
        }
        return label;
    }

    get srBulletPointCategory() {
        return 'Current State of ServiceResource sObject:';
    }

    get dtKeyField() {
        return 'id';
    }
    get showDataTable() {
        return this.dtRecords;
    }
    get showProgressBar() {
        return this._isLoading;
    }
    get showStencil() {
        return this._isLoading;
    }
    get showExportBtn() {
        return true;
    }
    get numberOfResults() {
        return this.dtRecords ? this.dtRecords.length : 0;
    }
    get filteredNumberOfResults() {
        return this.dtRecordsFiltered ? this.dtRecordsFiltered.length : 0;
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