import {LightningElement, wire, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import Logger from 'c/logger'
import retrieveServiceResourceHistories from '@salesforce/apex/GeoTabServiceResourceController.retrieveServiceResourceHistories';
import retrieveServiceResourceUsers from '@salesforce/apex/GeoTabServiceResourceController.retrieveGpsServiceResourceUsers';
import retrieveTrackedFields from '@salesforce/apex/GeoTabServiceResourceController.retrieveAllTrackedFields';
import {dtHelper} from "./geoTabSvcResourceHistoryDtHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_SR_WRAPS                      = 'SERVICE_RESOURCE_WRAPS';
const MAP_KEY_SERVICE_RESOURCE_USERS        = 'SERVICE_RESOURCE_USER_WRAPS';
const MAP_KEY_TRACKED_FIELD_WRAPS           = 'SERVICE_RESOURCE_TRACKED_FIELD_WRAPS';
const MAP_KEY_SERVICE_RESOURCE_HIST         = 'SERVICE_RESOURCE_HISTORY_WRAPS';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const DEVICE_ROW_LIMIT = 5000;
const NUM_REFRESHES_ALLOWED_PER_MINUTE = 5;

export default class GeoTabSvcResourceHistory extends LightningElement {
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api cardTitle = 'Service Resource';
    @api userPillIcon = 'standard:incident';
    @api historySObjectName = 'ServiceResource';
    @api defaultTrackedFieldApiName = 'none';
    @api srHistoryRowLimit = 200;
    @api serviceResourceNameSelectLabel = 'Select Service Resource';
    @api fieldNameSelectLabel = 'Select Tracked Field';

    @track devicesStatusInfo;
    @track dtRecords;
    @track dtRecordsFiltered;
    @track columns = dtHelper.getServiceResourceHistoryColumns();
    @track dtClasses = dtHelper.getDtClasses();
    @track sortDirection = 'desc';
    @track sortBy = 'createdDate';
    @track serviceResourceState;
    @track srBulletPoints;
    @track serviceResources;
    @track serviceResourceOptions;
    @track trackedFields;
    @track allTrackedFieldsApiNames = [];
    @track trackedFieldsOptions;

    _debugConsole;
    _logger;
    _wiredSrUsers;
    _isLoading;
    _dataRefreshTime;
    _displayMapView;
    _displayTableView = true;
    _numRefreshes = 0;
    _srSelectedValue = 'none';
    _fieldApiNameSelectedValue = 'none';
    _fieldApiNameSelectedValues = [];

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/geoTabServiceResourceHistory', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this._fieldApiNameSelectedValue = this.defaultTrackedFieldApiName;
    }


    @wire( retrieveServiceResourceUsers )
    wiredSrUsers(wiredData){
        this._wiredSrUsers = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.log(DEBUG,'sr users dto->', data);
                this.serviceResources = uiHelper.getMapValue(MAP_KEY_SERVICE_RESOURCE_USERS,data.values);
                this.serviceResourceOptions = this.generateUserOptions(this.serviceResources);
                this._isLoading = false;
            } else {
                this.log(WARN,'dto --> ',data);
                this._isLoading = false;
            }
        } else if (error) {
            this._isLoading = false;
            console.error(error);
        }
    }

    @wire( retrieveTrackedFields,{sObjectApiName: '$historySObjectName'} )
    wiredHistoryFields(wiredData){
        this._wiredHistoryFields = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.log(DEBUG,'fields->', data);
                this.trackedFields = uiHelper.getMapValue(MAP_KEY_TRACKED_FIELD_WRAPS,data.values);
                if(this.trackedFields) {
                    this.trackedFields.forEach(item => {
                       this.allTrackedFieldsApiNames.push(item.fieldApiName);
                    });
                }
                this.trackedFieldsOptions = this.generateHistoryFieldOptions(this.trackedFields);
                this._isLoading = false;
            } else {
                this.log(WARN,'dto --> ',data);
                this._isLoading = false;
            }
        } else if (error) {
            this._isLoading = false;
            console.error(error);
        }
    }

    doRetrieveServiceResourceHistories(selectedSrId,fieldApiNames) {
        let params = {serviceResourceId: selectedSrId,fieldApiNames: fieldApiNames,iLimit: this.srHistoryRowLimit}
        this._isLoading = true;
        retrieveServiceResourceHistories( params )
            .then((data) => {
                this.log(DEBUG, 'sr history dto->', data);
                let tmpHistories = uiHelper.getMapValue(MAP_KEY_SERVICE_RESOURCE_HIST,data.values);
                this.dtRecords = this.shapeServiceResourceHistoryData(tmpHistories);
                this.log(DEBUG, 'histimperative table data-->', this.dtRecords);
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

    generateUserOptions(users) {
        let userOptions;
        if(users) {
            let options = [];
            options.push({label: '-- Select One --', value:'none',selected:true});
            users.forEach(item => {
                let lbl = item.srName + ' ( '+item.srGpsType;
                if(item.srGpsType === 'Geotab') {
                    lbl += ' - '+item.srGeoTabId;
                } else if (item.srGpsType === 'Donlen') {
                    lbl += ' - '+item.srTrackerId;
                }
                lbl += ' )';
                let option = {label:lbl, value:item.srId, selected:false};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.label < b.label ? -1 : 1;
            });
            userOptions = options;
        }
        this.log(DEBUG,'sr optons',userOptions);
        return userOptions;
    }

    generateHistoryFieldOptions(fields) {
        let fieldOptions;
        if(fields) {
            let options = [];
            options.push({label: '-- Select One --', value:'none',selected:true});
            options.push({label: '** ALL TRACKED FIELDS **', value:'all',selected:false});
            fields.forEach(item => {
                let option = {label:item.fieldLabel, value:item.fieldApiName};
                options.push(option);
            });
            // options = options.sort((a,b) =>  {
            //     return a.label < b.label ? -1 : 1;
            // });
            fieldOptions = options;
        }
        this.log(DEBUG,'field optons',fieldOptions);
        return fieldOptions;
    }

    handlePlChange(evt) {
        let value = evt.target.value;
        let name = evt.target.dataset.id;

        if (name === 'srSelect') {
            this._srSelectedValue = value
            if (this._srSelectedValue !== 'none' && this._fieldApiNameSelectedValue && this._fieldApiNameSelectedValue !== 'none') {
                if(this._fieldApiNameSelectedValue === 'all'){
                    this._fieldApiNameSelectedValues = this.allTrackedFieldsApiNames;
                } else {
                    this._fieldApiNameSelectedValues = [];
                    this._fieldApiNameSelectedValues.push(this._fieldApiNameSelectedValue);
                }
                this.doRetrieveServiceResourceHistories(this._srSelectedValue,this._fieldApiNameSelectedValues);
            }
        }  else if (name === 'trackedFieldSelect') {
            this._fieldApiNameSelectedValue = value;
            if (this._srSelectedValue !== 'none' && this._fieldApiNameSelectedValue !== 'none') {
                if(this._fieldApiNameSelectedValue === 'all'){
                    this._fieldApiNameSelectedValues = this.allTrackedFieldsApiNames;
                } else {
                    this._fieldApiNameSelectedValues = [];
                    this._fieldApiNameSelectedValues.push(this._fieldApiNameSelectedValue);
                }
                this.doRetrieveServiceResourceHistories(this._srSelectedValue,this._fieldApiNameSelectedValues);
            }
        }
    }

    handleSelect(evt) {
        if(evt.detail) {
            this.log(DEBUG, 'option selected detail', evt.detail);
            const payload = evt.detail.payload;
            if(payload) {
                if (evt.detail.name === 'srSelect') {
                    const classList = evt.currentTarget.classList;
                    classList.add('lgc-highlight');
                    this._srSelectedValue = payload.value;
                    if (this._srSelectedValue !== 'none') {
                        this.doRetrieveServiceResourceHistories(this._srSelectedValue,this._fieldApiNameSelectedValue);
                    }
                } else if (evt.detail.name === 'trackedFieldSelect') {
                    this._fieldApiNameSelectedValue = payload.value;
                    if(this._srSelectedValue && this._srSelectedValue !== 'none') {
                        this.doRetrieveServiceResourceHistories(this._srSelectedValue,this._fieldApiNameSelectedValue);
                    }
                }
            }
        }
    }

    get showServiceResourceNamesPl() {
        return this.serviceResourceOptions;
    }

    get showTrackedFieldsPl() {
        return this.trackedFieldsOptions;
    }

    shapeServiceResourceHistoryData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = wraps;
            tmp.forEach(wrap => {
                let record = {};

            // @AuraEnabled public String historyId;
            // @AuraEnabled public String fieldApiName;
            // @AuraEnabled public Datetime createdDate;
            // @AuraEnabled public String createdByName;
            // @AuraEnabled public Id createdById;
            // @AuraEnabled public Object oldValue;
            // @AuraEnabled public Object newValue;
            // @AuraEnabled public Datetime oldLastKnownLocationDate;
            // @AuraEnabled public Datetime newLastKnownLocationDate;
            // @AuraEnabled public String gpsType;
                record.createdByName = wrap.createdByName;
                record.historyId = wrap.historyId;
                record.fieldApiName = wrap.fieldApiName;
                record.createdDate = wrap.createdDate;
                record.oldValue = wrap.oldValue;
                record.newValue = wrap.newValue;
                if(record.fieldApiName ==='LastKnownLocationDate') {
                    record.oldValue = wrap.oldLastKnownLocationDate;
                    record.newValue = wrap.newLastKnownLocationDate;
                }
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
        this.doRetrieveServiceResourceHistories(this._srSelectedValue,this._fieldApiNameSelectedValue);
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
        return 'historyId';
    }
    get numberOfResults() {
        return this.dtRecords ? this.dtRecords.length : 0;
    }
    get filteredNumberOfResults() {
        return this.dtRecordsFiltered ? this.dtRecordsFiltered.length : 0;
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