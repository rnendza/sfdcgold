import {LightningElement, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import Logger from 'c/logger'
import retrieveJobInfo from '@salesforce/apex/FslApiController.retrieveScheduledJobInfo';
import {dtHelper} from "./fslScheduleMaintDtHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_APEX_JOBS                 = 'APEX_JOBS';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const JOB_STATUSES = ['queued'];
const JOB_NAMES = ['Integrity Checker','Optimization','SLR Purge#FSL#','SLR Purge FSL'];


export default class FslScheduleMaint extends LightningElement {
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api cardTitle = 'FSL Scheduled Jobs';
    @api cardIconName = 'standard:service_appointment';
    @api jobCardBodyStyle = 'min-height: 375px'
    @api jobCardStyle;

    @track jobs;
    @track dtRecords;
    @track columns = dtHelper.getJobsColumns();
    @track dtClasses = dtHelper.getDtClasses();
    @track sortDirection = 'asc';
    @track sortBy = 'id';

    _debugConsole;
    _logger;
    _isLoading;
    _dataRefreshTime;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/fslScheduleMaint', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.retrieveFslScheduledJobs();
    }

    retrieveFslScheduledJobs() {
        let params = {jobNames: JOB_NAMES, jobStatuses: JOB_STATUSES}
        this._isLoading = true;
        retrieveJobInfo( params )
            .then((data) => {
                this._dataRefreshTime = new Date().getTime();
                this.log(DEBUG,'--->fsl jobs dto=',data);
                this.jobs = uiHelper.getMapValue(MAP_KEY_APEX_JOBS,data.values);
                this.dtRecords = this.shapeJobsTableData(this.jobs);
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading jobs Info: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }


    shapeJobsTableData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = JSON.parse(JSON.stringify(wraps));
            tmp.forEach(wrap => {
                let record = wrap;
                records.push(record);
            });
        }
        return records;
    }

    handleRefresh(evt) {
        this.dtRecords = null;
        this.retrieveFslScheduledJobs();
    }


    handleRowAction(evt){
        evt.preventDefault();
        evt.stopPropagation();
        const row = evt.detail.row;
        const action = evt.detail.action;
        const actionName = action.name;
        console.log('--->',JSON.parse(JSON.stringify(row)));
        console.log('---> action:',JSON.parse(JSON.stringify(action)));
        switch (actionName) {
            case 'abort':
                //this.handleAbort(row);
                break;
            default:
        }
    }

    get dtKeyField() {
        return 'cronTriggerId';
    }
    get showDataTable() {
        return this.dtRecords && this.dtRecords.length > 0;
    }
    get showProgressBar() {
        return this._isLoading;
    }
    get showStencil() {
        return this._isLoading;
    }
    get showNoJobs() {
        return !this._isLoading && !this.showDataTable;
    }
    get numberOfResults() {
        return this.dtRecords ? this.dtRecords.length : 0;
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