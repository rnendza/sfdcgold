import {LightningElement, wire, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import Logger from 'c/logger'
import retrieveLogs from '@salesforce/apex/GeoTabApiController.retrieveAppLogs';
import {dtHelper} from "./geoTabLogsDtHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_DEVICES_STATUS_INFO       = 'DEVICES_STATUS_INFO';
const MAP_KEY_SERVICE_RESOURCE_STATE    = 'SR_STATE';
const MAP_KEY_APP_LOGS                  = 'APP_LOGS';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const DEVICE_ROW_LIMIT = 5000;
const NUM_REFRESHES_ALLOWED_PER_MINUTE = 5;

export default class GeoTabLogs extends LightningElement {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api assistanceTitle = 'Logs Assistant'
    @api cardTitle = 'Logs';

    @track devicesStatusInfo;
    @track dtRecords;
    @track dtRecordsFiltered;
    @track columns = dtHelper.getLogsColumns();
    @track dtClasses = dtHelper.getDtClasses()
    @track sortDirection = 'asc';
    @track sortBy = 'Name';
    @track serviceResourceState;
    @track logsBulletPoints;
    @track serviceResources;

    _debugConsole;
    _logger;
    _isLoading;
    _filterServiceResourcesOnly;
    _jobNames = ['GeoTabQueueableLocRefresh'];
    _jobStatuses = ['Success','Failed','Partial Success'];
    _dataRefreshTime;
    _selectedHoursBackOption = 1;
    _selectedJobStatusOption = 'All';

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/geoTabLogs', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    @track searchParams = {
        iLimit : 2000,
        iHoursBack : this._selectedHoursBackOption,
        jobNames : this._jobNames,
        jobStatuses : this._jobStatuses
    }

    connectedCallback() {
        this.retrieveAppLogs(this.searchParams);
        this.showAssistance = true;
        this.generateAssistanceBulletPoints();
    }

    retrieveAppLogs(params) {
        this._isLoading = true;
        retrieveLogs( params )
            .then((data) => {
                this.log(DEBUG, 'logs dto->', data);
                let tmpLogs = uiHelper.getMapValue(MAP_KEY_APP_LOGS,data.values);
                this.logs = this.shapeLogsTableData(tmpLogs);
                this.dtRecords = this.logs
                this._dataRefreshTime = new Date().getTime();
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading logs: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }


    shapeLogsTableData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = wraps;
            tmp.forEach(wrap => {
                let record = {};
                record.logId = wrap.Id;
                record.logNumber = wrap.Name;
                record.logLinkTooltip = 'Click here to view detail for '+record.logNumber+'.';
                if(record.logId) {
                    record.sfdcName = record.logNumber;
                    record.sfdcUrl = '/'+record.logId;
                }
                record.jobStatus = wrap.Overall_Job_Status__c;
                record.jobStatusCls = record.jobStatus === 'Failed' ? "slds-text-color_destructive":"slds-text-color_success"
                record.jobName = wrap.Job_Name__c;
                record.jobType = wrap.JobType__c;
                record.processStartDate = wrap.Process_Start_Date__c;
                record.processEndDate = wrap.Process_End_Date__c;
                record.totalRecordsSelected = wrap.Total_Records_Selected__c;
                record.totalRecordsProcessed = wrap.Total_Records_Processed__c;
                record.totalRecordsUpdated = wrap.Total_Records_Updated__c
                record.totalRecordsFailed = wrap.Total_Updates_Failed__c;
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
        this.dtRecords = dtHelper.sortData(tmpSortBy,this.sortDirection,this.dtRecords);

        let payload = {sortBy:this.sortBy,sortDirection:this.sortDirection};
        this.dispatchEvent( new CustomEvent('dtsorted',{detail:payload}));
    }

    handleHoursBackPlChange(evt) {
        let value = evt.target.value;
        if(this.isNumber(value)) {
            value = parseInt(value);
            this._selectedHoursBackOption = value;
            this.searchParams.iHoursBack = value;
            this.handleRefresh(evt);
        }
    }

    handleJobStatusesPlChange(evt) {
        let value = evt.target.value;

            this._selectedJobStatusOption = value;
            if(this._selectedJobStatusOption === 'all') {
                this.searchParams.jobStatuses = ['Success','Failed','Partial Success'];
            } else {
                this.searchParams.jobStatuses = [value];
            }
            this.handleRefresh(evt);

    }

    handleRefresh(evt) {
        this._isLoading = true;
        this.retrieveAppLogs(this.searchParams);
    }

    isNumber(n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }

    /**
     * Bullet points for child assistant / help cmp.
     */
    generateAssistanceBulletPoints() {
        this.logsBulletPoints = [];

        let msg = 'Application logs are defaulted to show the last hours of logs for all statuses.';
        this.logsBulletPoints.push({text: msg, severity: 'info'});

        msg = 'Use the hours back filter to expand the number of records as well as the status filter to further refine the results.';
        this.logsBulletPoints.push({text: msg, severity: 'info'});

        msg = 'Click the Log # link to obtain more detailed information about a specific log.';
        this.logsBulletPoints.push({text: msg, severity: 'info'});

        msg = 'If the time is outside of this range, go to the Accel Application Logs tab and use the listviews within that.';
        this.logsBulletPoints.push({text: msg, severity: 'info'});
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
        return 'logId';
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
     * Gets collection date picklist options.
     * @returns {*[]}
     */
    get hoursBackPlOptions() {
        let options = [];
        options.push({value:1, label:'Last hour', selected:this._selectedHoursBackOption === 1});
        options.push({value:2, label:'Last 2 hours', selected:this._selectedHoursBackOption === 2});
        options.push({value:4, label:'Last 4 hours', selected:this._selectedHoursBackOption === 4});
        options.push({value:8, label:'Last 8 hours', selected:this._selectedHoursBackOption === 8});
        options.push({value:24, label:'Last 24 hours', selected:this._selectedHoursBackOption === 24});
        return options;;
    }

    /**
     * Gets collection date picklist options.
     * @returns {*[]}
     */
    get jobStatusPlOptions() {
        let options = [];
        options.push({value:'all', label:'All Statuses', selected:this._selectedJobStatusOption === 'All'});
        options.push({value:'Failed', label:'Failed', selected:this._selectedJobStatusOption === 'Failed'});
        options.push({value:'Partial Success', label:'Partial Success', selected:this._selectedJobStatusOption === 'Partial Success'});
        options.push({value:'Success', label:'Success', selected:this._selectedJobStatusOption === 'Success'});
        return options;;
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