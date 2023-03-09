import {LightningElement, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/portalAdminUtilsUiHelper'
import Logger from 'c/logger'
import retrieveJobInfo from '@salesforce/apex/AppLogController.retrieveScheduledJobInfo';
import fireJob from '@salesforce/apex/AppLogController.fireJob';
import abortJob from '@salesforce/apex/AppLogController.abortJob';
import {dtHelper} from "./appLogScheduleMaintDtHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_APEX_JOBS                 = 'APEX_JOBS';
const MAP_KEY_JOB_ABORT_IDS           = 'JOB_ABORT_IDS';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const JOB_STATUSES = ['queued'];
const APEX_CLASS_NAMES = ['Sch_BatchAppLogPurge'];


export default class AppLogScheduleMaint extends LightningElement {
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api cardTitle = 'App Log Pruning';
    @api cardSubtitle;
    @api jobCardBodyStyle = 'min-height: 375px' 
    @api cron = '0 0 0 ? * SUN *';
    @api jobName = 'Schedule Batch App Log Purge';

    @track jobs;
    @track dtRecords;
    @track columns = dtHelper.getJobsColumns();
    @track dtClasses = dtHelper.getDtClasses();
    @track sortDirection = 'asc';
    @track sortBy = 'id';
    @track serviceResourceState;
    @track srBulletPoints;
    @track serviceResources;

    @track dialogPayload;
    @track confirmLabel = 'Confirm';
    @track confirmTitle = 'Confirm Abort';
    @track confirmDisplayMessage = '';
    @track confirmIcon = 'standard:question_feed'
    @track confirmIconSize = 'small';
    @track isActionDialogVisible;
    @track schBulletPoints;

    _debugConsole;
    _logger;
    _isLoading;
    _disableFireJobButton;
    _dataRefreshTime;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/appLogScheduleMaint', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.showAssistance = true;
        this.retrieveScheduledJobs();
    }

    retrieveScheduledJobs() {
        let params = {apexClassNames: APEX_CLASS_NAMES, jobStatuses: JOB_STATUSES}
        this.log(DEBUG, '---> call server to retrieve job info with params',params);
        this._isLoading = true;
        retrieveJobInfo( params )
            .then((data) => {
                this._dataRefreshTime = new Date().getTime();
                this.log(DEBUG,'--->app log pruning jobs dto=',data);
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

    fireJob() {
        this._isLoading = true;
        let params = {cron: this.cron, jobName: this.jobName}
        fireJob(params)
            .then((data) => {
                this.log(DEBUG,'--->jobs fire dto =',data);
                let jobId = uiHelper.getMapValue('JOB_FIRE_STATUS',data.values);
                let msg ='Job: '+jobId + ' started successfully!';
                uiHelper.showToast(this,'JOB Info',msg,'success');
                this.retrieveScheduledJobs();
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error Scheduling job: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    doAbortJob() {
        this._isLoading = true;
        this.dtRecords = null;
        let params = {jobName: this.jobName}
        abortJob(params)
            .then((data) => {
                let msg = '';
                if(data.isSuccess) {
                    msg = 'Job Aborted successfully';
                }
                uiHelper.showToast(this,'Abort Status',msg,'success');
                this.retrieveScheduledJobs();
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error aborting: '+msg,'error');
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
        this.retrieveScheduledJobs();
    }
    handleFireJobClick(evt) {
        this.fireJob();
    }

    handleAbort(row) {

        const jobId = row.cronTriggerId;
        const payload = {jobId: jobId, action: 'abort'};
        this.dialogPayload = payload;
        this.confirmIcon = 'action:delete';
        this.confirmIconSize = 'xx-small';
        this.confirmTitle = 'Confirm Abort';
        this.confirmDisplayMessage = 'You have indicated that you wish to abort the App Log Pruning scheduled jobId: ' + jobId + '.  Are you sure?';
        this.confirmLabel = 'Abort Job';
        this.isActionDialogVisible = true;
    }

    /**
     * Handle the Assign to me confirmation of the assign action.  if confirmed.
     * caLl selectRouteSchedule with selected route schedule id.
     * @param evt
     */
    handleModalConfirmClick(evt) {
        if(evt.detail !== 1){
            const detail = evt.detail.originalMessage;
            if(evt.detail.status === 'confirm') {
                if(detail.action){
                    if(detail.action === 'abort') {
                        if(detail.jobId) {
                            this.doAbortJob();
                        }
                    }
                }
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.isActionDialogVisible = false;
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
                this.handleAbort(row);
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