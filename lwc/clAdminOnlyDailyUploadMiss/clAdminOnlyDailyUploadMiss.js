import {api, LightningElement, track, wire} from 'lwc';
import Logger from 'c/logger'
import {getObjectInfo,getPicklistValues} from "lightning/uiObjectInfoApi";
import PROCESSING_LOCATION_FIELD from '@salesforce/schema/Route_Schedule__c.Processing_Location__c';
import ROUTE_SCHEDULE_OBJECT from "@salesforce/schema/Route_Schedule__c";
import retrieveMdtNoCache   from '@salesforce/apex/clRouteProcessingSheetsController.retrieveMdtNoCache';
import retrieveMaxMeterInfo from '@salesforce/apex/clAdminOnlyDailyUploadMissController.retrieveLatestMeterRecordsTotal';
import retrieveLatestRoutesSchedule from '@salesforce/apex/clAdminOnlyDailyUploadMissController.retrieveLatestRouteSchedule';
import retrieveJobInfo from '@salesforce/apex/clAdminOnlyDailyUploadMissController.retrieveScheduledJobInfo';
import retrieveMeterJobInfo from '@salesforce/apex/clAdminOnlyDailyUploadMissController.retrieveBatchMeterJobInfo';
import retrieveDataCreationTotals from '@salesforce/apex/clAdminOnlyDailyUploadMissController.retrieveDataCreationTotals';
import searchMetersToModify from '@salesforce/apex/clAdminOnlyDailyUploadMissController.searchForMetersToModify';
import fireRsJob from '@salesforce/apex/clAdminOnlyDailyUploadMissController.fireRsJob';
import fireRpsJob from '@salesforce/apex/clAdminOnlyDailyUploadMissController.fireRpsJob';
import { getConstants } from 'c/clConstantUtil';
import { reduceErrors } from "c/ldsUtils";
import {themeOverrider} from 'c/clAdminOnlyCardTheme';
import {uiHelper} from './clAdminOnlyDailyUploadMissUiHelper';
import {dtHelper} from './clAdminOnlyDailyUploadMissDtHelper';
import {dateUtils} from './clAdminOnlyDailyUploadMissDateUtils';
import {refreshApex} from "@salesforce/apex";

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff

const   GLOBAL_CONSTANTS                = getConstants();
const   SCHEDULE_MDT_DEV_NAME           = 'Scheduler';
const   MAP_KEY_MDT_RECORD              = 'MDT_RECORD';
const   MAP_KEY_SYNC_RESULTS            = 'SYNC_RESULTS';
const   MAP_KEY_APEX_JOBS               = 'APEX_JOBS';
const   MAP_KEY_DATA_TOTALS             = 'DATA_TOTALS';
const   MAP_KEY_MAX_METER_CREATED_DATE  = 'MAX_METER_CREATED_DATE';
const   MAP_KEY_LATEST_ROUTE_SCHEDULE   = 'LATEST_ROUTE_SCHEDULE';
const   MAP_KEY_METERS_TO_MOD_TOTALS    = 'METERS_TO_MOD_TOTALS';
const   MAP_KEY_REGIONS_AFFECTED        = 'REGIONS_AFFECTED';
const   MAP_KEY_RS_BATCH_JOB_ID         = 'RS_BATCH_JOB_ID';
const   MAP_KEY_RPS_BATCH_JOB_ID        = 'RPS_BATCH_JOB_ID';
const   JOB_STATUSES                    = ['Queued','Aborted','Completed','Failed','Holding','Preparing','Processing'];
const   APEX_CLASS_NAMES                = ['clBatchRouteScheduleCreation','clBatchRouteProcessingSheetCreation','clBatchMeterReadingsCreation'];


export default class clAdminOnlyDailyUploadMiss extends LightningElement {

    @api objectApiName = 'Route_Schedule__c';
    @api mainCardTitle = 'Blah';
    @api meterCreatedDateDaysBack = 300;
    @api showAssistance;

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @track processLocationPlValues;
    @track selectedProcessingLocation;
    @track selectedMeterCreatedTime;
    @track scheduleMdt;
    @track syncDtRecords;
    @track asyncDtRecords;
    @track syncColumns = dtHelper.getSyncColumns();
    @track asyncColumns = dtHelper.getAsyncColumns();
    @track dtClasses = dtHelper.getDtClasses()
    @track sortDirection = 'desc';
    @track sortBy = 'name';
    @track batchJobIds = [];
    @track dataTotals;
    @track meterSearchResultData;
    @track metersToModTotals;
    @track regionsAffected;
    @track maxMeterCreatedDate;
    @track latestRouteSchedule;

    defaultRtId;
    scheduleNextCycle;

    _logger;
    _debugConsole;
    _isLoading;
    _isLoadingAsyncJobs;
    _isSearching;
    _hasFocusedProcessingLocation;
    _wiredScheduleMdt;
    _wiredMaxMeterInfo;
    _wiredLatestRoutesSchedule;
    _hasRendered;
    _scheduleMdtDevName = SCHEDULE_MDT_DEV_NAME;
    _cacheBust = Math.random();
    _rsCreationJobId;
    _rsJobMethodRunning;
    _rpsCreationJobId;
    _rsJobCompleted;
    _syncRefreshDateTime;
    _asyncRefreshDateTime;
    _totalsRefreshDateTime;
    _asyncRefreshTimerId;
    _asyncRefreshInterval = 2500;
    _allJobsDone;

    _meterDate;
    _meterDateMin;
    _meterDateMax;
    _hasSearched;
    _showAdvancedFormOptions;
    _nbrOfMinutesToAddToMeterCreatedDate = 2;
    _nbrOfMinutesToSubtractFromMeterCreatedDate = 4;

    constructor() {
        super();
        this._isLoading = true;
        this.showAssistance = true;
        console.info('%c----> /lwc/clAdminOnlyDailyUploadMiss', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {

    }

    renderedCallback() {
        if(!this._hasFocusedProcessingLocation) {
            this.focusProcessingLocation();
        }
        if(!this._hasRendered) {
            this._hasRendered = true;
            themeOverrider.buildAdminCardOverrideCss(this);
        }
    }

    disconnectedCallback() {
       this.killTimer();
    }

    initDateParams() {
        if(this.maxMeterCreatedDate) {
            this._meterDate = this.maxMeterCreatedDate;
        } else {
            this._meterDate = dateUtils.todaysDatetimeISO;
        }
        this.selectedMeterCreatedTime = this._meterDate;
    }

    killTimer() {
        if(this._asyncRefreshTimerId) {
            clearInterval((this._asyncRefreshTimerId));
            this._asyncRefreshTimerId = null;
        }
    }


    doSearchForMetersToModify( meterCreatedDate,region,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate) {

        this._isSearching = true;
        this.metersToModTotals = null;
        this.regionsAffected = null;
        this._hasSearched = true;
        let params = {
            meterCreatedDate: meterCreatedDate,
            region:region,
            nbrOfMinutesToAddToMeterCreatedDate: nbrOfMinutesToAddToMeterCreatedDate,
            nbrOfMinutesToSubtractFromMeterCreatedDate : nbrOfMinutesToSubtractFromMeterCreatedDate
        };
        this.log(DEBUG,'--> firing server call with params',params);
        searchMetersToModify(params)
            .then(dto => {
                this.log(DEBUG,'dto resp from server',dto);
                if(dto.isSuccess) {
                    this.metersToModTotals = uiHelper.getMapValue(MAP_KEY_METERS_TO_MOD_TOTALS,dto.values);
                    this.regionsAffected = uiHelper.getMapValue(MAP_KEY_REGIONS_AFFECTED,dto.values);
                }else {
                    uiHelper.showToast(this,'',dto.message,dto.severity,'sticky');
                }
            })
            .catch(error => {
                this.log(ERROR,'error on server call',error);
                let msg = 'Error on server call! ';
                if(error.body && error.body.message) {
                    msg += error.body.message;
                } else {
                    msg += error;
                }
                uiHelper.showToast(this,'',msg,'error','sticky');
            })
            .finally(() => {
                this._isLoading = false;
                this._isSearching = false;
                // this._rsJobMethodRunning = false;
            });
    }

    doFireRsJob() {
        this._isLoading = true;

        let params = {
            processingLocation: this.selectedProcessingLocation,
            iNextCycle: this.scheduleNextCycle,
            meterCreatedDate:   this.selectedMeterCreatedTime,
            nbrOfMinutesToAddToMeterCreatedDate : this._nbrOfMinutesToAddToMeterCreatedDate,
            nbrOfMinutesToSubtractFromMeterCreatedDate: this._nbrOfMinutesToSubtractFromMeterCreatedDate
        };
        this.log(DEBUG,'--> firing doFireRsJob server call with params',params);
        this._rsJobCompleted = false;
        this._rsJobMethodRunning = true;
        fireRsJob(params)
            .then(dto => {
               this.log(DEBUG,'dto resp from server',dto);
               if(dto.isSuccess) {
                   this._syncRefreshDateTime = new Date().getTime();
                   this.syncDtRecords = uiHelper.getMapValue(MAP_KEY_SYNC_RESULTS,dto.values);
                   this._rsCreationJobId = uiHelper.getMapValue(MAP_KEY_RS_BATCH_JOB_ID,dto.values);
                   uiHelper.showToast(this,'',dto.message,dto.severity);
                   this.batchJobIds.push(this._rsCreationJobId);
                   this.doRetrieveJobInfo();
                   this._asyncRefreshTimerId = setInterval(()=>this.doAsyncRefresh(), this._asyncRefreshInterval);
               }else {
                   let msg = 'Something went wrong on the server call ';
                   uiHelper.showToast(this,'',msg + dto.message,dto.severity);
               }
            })
            .catch(error => {
               this.log(ERROR,'error on server call',error);
               let msg = 'Error on server call! ';
               if(error.body && error.body.message) {
                   msg += error.body.message;
               } else {
                   msg += error;
               }
               uiHelper.showToast(this,'',msg,'error','sticky');
            })
            .finally(() => {
               this._isLoading = false;
               this._rsJobMethodRunning = false;
            });
    }

    doFireRpsJob() {
        let params = {processingLocation: this.selectedProcessingLocation};
        this.log(DEBUG,'--> firing server call with params',params);
        fireRpsJob(params)
            .then(dto => {
                this.log(DEBUG,'dto resp from server',dto);
                if(dto.isSuccess) {
                    this._syncRefreshDateTime = new Date().getTime();
                    this.syncDtRecords = [...this.syncDtRecords,...uiHelper.getMapValue(MAP_KEY_SYNC_RESULTS,dto.values)];
                    this._rpsCreationJobId = uiHelper.getMapValue(MAP_KEY_RPS_BATCH_JOB_ID,dto.values);
                    uiHelper.showToast(this,'',dto.message,dto.severity);
                    this.batchJobIds.push(this._rpsCreationJobId);
                    this.doRetrieveJobInfo();
                }else {
                    let msg = 'Something went wrong on the server call ';
                    uiHelper.showToast(this,'',msg + dto.message,dto.severity);
                }
            })
            .catch(error => {
                this.log(ERROR,'error on server call',error);
                let msg = 'Error on server call! ';
                if(error.body && error.body.message) {
                    msg += error.body.message;
                } else {
                    msg += error;
                }
                uiHelper.showToast(this,'',msg,'error','sticky');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    doRetrieveJobInfo() {
        let params = {apexClassNames: APEX_CLASS_NAMES, jobStatuses: JOB_STATUSES,jobIds : this.batchJobIds}
        this.log(DEBUG,'calling doRetrieveJobInfo with params',params);
        this._isLoadingAsyncJobs = true;
        retrieveJobInfo( params )
            .then((data) => {
                this._asyncRefreshDateTime = new Date().getTime();
                this.log(DEBUG,'--->jobs dto=',data);
                this.asyncDtRecords = [...uiHelper.getMapValue(MAP_KEY_APEX_JOBS,data.values)];
                this.doRetrieveMeterJobInfo();
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
                this._isLoadingAsyncJobs = false;
            });
    }

    doRetrieveDataCreationTotals() {

        let params = {
            processingLocation: this.selectedProcessingLocation,
            nbrOfMinutesToAddToMeterCreatedDate : this._nbrOfMinutesToAddToMeterCreatedDate,
            nbrOfMinutesToSubtractFromMeterCreatedDate: this._nbrOfMinutesToSubtractFromMeterCreatedDate
        };
        this.log(DEBUG,'calling doRetrieveDataCreationTotals with params',params);
        retrieveDataCreationTotals( params )
            .then((data) => {
                this.log(DEBUG,'--->data creation dto=',data);
                this._totalsRefreshDateTime = new Date().getTime();
                this.dataTotals = uiHelper.getMapValue(MAP_KEY_DATA_TOTALS,data.values);
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading data creation totals: '+msg,'error');
            })
            .finally(() => {
                this._isLoadingAsyncJobs = false;
            });
    }

    doRetrieveMeterJobInfo() {
        let params = {apexClassName: 'clBatchMeterReadingsCreation', jobStatuses: JOB_STATUSES};
        this.log(DEBUG,'calling doRetrieveMeterInfo with params',params);
        this._isLoadingAsyncJobs = true;
        retrieveMeterJobInfo( params )
            .then((data) => {
                this._asyncRefreshDateTime = new Date().getTime();
                this.log(DEBUG,'--->meter readings job  dto=',data);
                if(data.isSuccess) {
                    this.asyncDtRecords = [...this.asyncDtRecords,...uiHelper.getMapValue(MAP_KEY_APEX_JOBS, data.values)];
                }
                this.checkKillRefreshTimer(this.asyncDtRecords);
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
                this._isLoadingAsyncJobs = false;
            });
    }

    checkKillRefreshTimer(asyncDtRecords) {
        if(asyncDtRecords && Array.isArray(asyncDtRecords)) {
            const numRecords = 3;
            let numCompleted = 0;
            asyncDtRecords.forEach(rec => {
                if(rec.completedDate) {
                    numCompleted++;
                }
            });
            if(numRecords === numCompleted){
                this.log(DEBUG,'===> Stopping Timer!');
                this._allJobsDone = true;
                this.doRetrieveDataCreationTotals();
                let msg = 'All jobs are now completed!';
                uiHelper.showToast(this,'All Jobs Complete',msg,'success');
                this.killTimer();
            } else {
                this.checkRsJobCompleted(this.asyncDtRecords);
            }
        }
    }

    checkRsJobCompleted(asyncDtRecords) {
        if(!this._rsJobCompleted) {
            asyncDtRecords.forEach(rec => {
                if (rec.apexClassName === 'clBatchRouteScheduleCreation' && rec.completedDate) {
                    this._rsJobCompleted = true;
                    let msg = 'The Route Schedule Job has completed. You may now fire the Route Processing Sheet creation job.';
                    uiHelper.showToast(this, 'Route Schedule Job Completed', msg, 'success');
                }
            });
        }
    }

    doAsyncRefresh() {
        this.doRetrieveJobInfo();
    }

    @wire(getObjectInfo, { objectApiName: ROUTE_SCHEDULE_OBJECT })
    wiredObject({ data, error }) {
        if (data) {
            this.defaultRtId = data.defaultRecordTypeId;
        } else if (error) {
            this.log(ERROR,'get object error',error);
        }
    }

    @wire (getPicklistValues, {recordTypeId: '$defaultRtId', fieldApiName: PROCESSING_LOCATION_FIELD})
    wiredPriorityPlValues({ error, data }) {
        if (data) {
            this.processLocationPlValues = data.values;
            this.log(DEBUG,'pl values',this.processLocationPlValues);
        } else if (error) {
            console.log(error);
        }
    }

    @wire (retrieveMaxMeterInfo)
    wiredMaxMeterInfo(wiredData) {
        this._wiredMaxMeterInfo = wiredData;
        const { error, data } = wiredData;
        if (data) {
            this.log(DEBUG,'--> max meter created info dto',data);
            if(data.isSuccess) {
                this.maxMeterCreatedDate = uiHelper.getMapValue(MAP_KEY_MAX_METER_CREATED_DATE,data.values);
                this.initDateParams();
            }
        } else if (error) {
            console.log(error);
        }
    }

    @wire (retrieveLatestRoutesSchedule)
    wiredLatestRouteSchedule(wiredData) {
        this._wiredLatestRoutesSchedule = wiredData;
        const { error, data } = wiredData;
        if (data) {
            this.log(DEBUG,'--> latest route schedule  dto',data);
            if(data.isSuccess) {
                this.latestRouteSchedule = uiHelper.getMapValue(MAP_KEY_LATEST_ROUTE_SCHEDULE,data.values);
            }
        } else if (error) {
            console.log(error);
        }
    }


    @wire(retrieveMdtNoCache, { mdtDevName: '$_scheduleMdtDevName', cacheBust : '$_cacheBust' })
    wiredMdt(wiredData) {
        this._wiredScheduleMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            this.showToast('', 'Problem getting custom metadata settings: ' + this.error, 'error');
            this.log(ERROR,'error getting mdt',error);
            this._isLoading = false;
        } else if (data) {
            this._isLoading = false;
            this.scheduleMdt = uiHelper.getMapValue(MAP_KEY_MDT_RECORD, data.values);
            if (this.scheduleMdt) {
                this.scheduleNextCycle = this.scheduleMdt.Next_Cycle__c;
            }
        }
    }



    processSubmitRsClick() {
        let msg = '';
        msg += 'This action will delete route schedules, route processing sheets, and meter readings created ';
        msg += `within ${this._nbrOfMinutesToSubtractFromMeterCreatedDate} minutes behind and `;
        msg += `${this._nbrOfMinutesToAddToMeterCreatedDate} ahead of the meter created time of `;
        msg += `${this.selectedMeterCreatedTime} as well as any data found for ${this.selectedProcessingLocation} `;
        msg += `which was created today.  This will also fire the route schedule creation job for `;
        msg += `${this.selectedProcessingLocation} for the Fill Cycle of ${this.scheduleNextCycle}. Are you Sure?`;
        uiHelper.showConfirm(msg, 'error', 'Confirm Route Schedule Job Submit').then((res) => {
            if (res) {
                this.doFireRsJob();
            }
        });
    }

    processSubmitRpsClick() {
        let msg = '';
        msg += 'This action will fire the Route processing sheet  Creation Job (and chained meters reading creation job) for  '
            + this.selectedProcessingLocation +'. Please confirm the Route Schedule Job is completed prior to executing. Are you sure?';
        uiHelper.showConfirm(msg, 'error', 'Confirm Route Processing Sheet Job Submit').then((res) => {
            if (res) {
                this.doFireRpsJob();
            }
        });
    }

    processSubmitSelectRegionClick() {
        this._rpsCreationJobId = null;
        this._rsCreationJobId = null;
        this.asyncDtRecords = null;
        this.syncDtRecords = null;
        this.dataTotals = null;
        this.batchJobIds = [];
        this.selectedProcessingLocation = null;
        this._allJobsDone = false;
        this.metersToModTotals = null;
        this._hasSearched = false;
        refreshApex(this._wiredMaxMeterInfo);
        refreshApex(this._wiredLatestRoutesSchedule);
    }


    handleSubmit(evt) {
        if(evt && evt.detail) {
            switch (evt.detail.buttonid) {
                case 'submitRsButton' : {
                    this.processSubmitRsClick();
                    break;
                }
                case 'submitRpsButton' : {
                    this.processSubmitRpsClick();
                    break;
                }
                case 'submitSelectRegion' : {
                    this.processSubmitSelectRegionClick();
                    break;
                }
                default : {
                    this.log(ERROR,'unhandled button id',evt.detail);
                }
            }
        }
    }

    handleInputFocus(event) {
        const classList = event.target.parentNode.classList;
        classList.add('lgc-highlight');
    }

    handleInputBlur(event) {
        const classList = event.target.parentNode.classList;
        classList.remove('lgc-highlight');
    }

    handleChange(evt) {
        const value = evt.target.value;
        const name = evt.target.name;
        switch (name) {
            case 'processingLocation':
                this.selectedProcessingLocation = value;
                break;
            case 'meterCreatedDate':
                this.selectedMeterCreatedTime = value;
                break;
            case '-1':
                this.selectedProcessingLocation = null;
                this.selectedMeterCreatedTime = null;
                break;
            case  'nbrOfMinutesToAddToMeterCreatedDate':
                this._nbrOfMinutesToAddToMeterCreatedDate = value;
                break;
            case 'nbrOfMinutesToSubtractFromMeterCreatedDate':
                this._nbrOfMinutesToSubtractFromMeterCreatedDate = value;
                break;
        }
    }

    handleSearchClick(evt) {
        this.doSearchForMetersToModify(
            this.selectedMeterCreatedTime,
            this.selectedProcessingLocation,
            this._nbrOfMinutesToAddToMeterCreatedDate,
            this._nbrOfMinutesToSubtractFromMeterCreatedDate
        );
    }

    handleHideAdvancedOptions(evt) {
        this._showAdvancedFormOptions = false;
    }
    handleShowAdvancedOptions(evt) {
        this._showAdvancedFormOptions = true;
    }

    focusProcessingLocation() {
        setTimeout(() => {
            const tmpSelector = '[data-id="processinglocation"]';
            const inputBox = this.template.querySelector(tmpSelector);
            if(inputBox) {
                inputBox.focus();
                this._hasFocusedProcessingLocation = true;
            }
        });
    }

    get cardTitle() {
        return this.mainCardTitle;
    }

    get showStencil() {
        return this._isLoading;
    }
    get showSearchingStencil() {
        return this._isSearching;
    }

    get showProgressBar() {
        return this._isLoading;
    }

    get showForm() {
        return !this._isLoading && this.processLocationPlValues && !this.showRpsJobSubmitButton &&
            !this.showSelectRegionButton && !this._asyncRefreshTimerId;
    }

    get disableSubmitButton() {
        return this._isLoading || !this.selectedMeterCreatedTime;
    }

    get disableSearchButton() {
        return this._isLoading || !this.selectedProcessingLocation || !this.selectedMeterCreatedTime;
    }

    get showRsJobSubmitButton() {
        return !this._isLoading && !this._rsCreationJobId && this.selectedMeterCreatedTime && this.selectedProcessingLocation && this.showMeterSearchResults;
    }

    get showRpsJobSubmitButton() {
        return !this._isLoading && this._rsCreationJobId && !this._rpsCreationJobId && this._rsJobCompleted;
    }

    get showAnyButton() {
        return this.showRsJobSubmitButton || this.showRpsJobSubmitButton || this.showSelectRegionButton;
    }

    get showSyncDatatable() {
        return !this._isLoading && this.syncDtRecords;
    }

    get showAsyncDatatable() {
        return !this._isLoading && this.asyncDtRecords;
    }

    get showMeterSearchResults() {
        return this.metersToModTotals && !this.showSelectRegionButton && !this.showRpsJobSubmitButton && !this._asyncRefreshTimerId;
    }

    get showDataTotals() {
        return this.dataTotals;
    }

    get syncDtKeyField() {
        return "msgDateTime";
    }

    get asyncDtKeyField() {
        return "jobId";
    }

    get showSelectRegionButton() {
        return !this._isLoading && this._allJobsDone;
    }

    get showNoSearchResults() {
        return !this._isSearching && !this._isLoading && this._hasSearched && !this.metersToModTotals;
    }


    get defaultMeterDate() {
        let d = new Date();
        d = new Date(d.setDate(d.getDate()));
        d.setHours(0,0,0,0)
        return d.toISOString();
    }

    /**
     * Build object data for child assistance cmp.
     * @returns {*[]}
     */
    get helpBulletPoints() {
        let  arr = [];
        let msg;
        msg = 'The region selected is the region that new data will be uploaded to.';
        arr.push({text: msg, severity: 'info'});
        msg = 'The meter created time is used to search for all data to delete regardless of region.';
        arr.push({text: msg, severity: 'info'});

        if(this.scheduleNextCycle) {
            msg = 'The current fill cycle number in this instance is '+this.scheduleNextCycle;
            arr.push({text: msg, severity: 'info'});
        }
        if(this.maxMeterCreatedDate) {
            let dDate = this.convertApexStringDateToLocalDate(this.maxMeterCreatedDate);
            msg = 'The most recent meter created date is '+dDate.toLocaleString();
            arr.push({text: msg, severity: 'info'});
        }
        if(this.latestRouteSchedule) {
            let dDate = this.convertApexStringDateToLocalDate(this.latestRouteSchedule.CreatedDate);
            msg = 'The most recent route schedule created date is '+dDate.toLocaleString();
            msg+= ' for '+this.latestRouteSchedule.Processing_Location__c;
            arr.push({text: msg, severity: 'info'});
        }
        return arr;
    }

    get meterSearchResultsMsgText() {
        let txt = '';
        if(this.metersToModTotals) {
            txt += `${this.metersToModTotals.numMeters} meters,${this.metersToModTotals.numRPS} route processing sheets, and `;
            txt += `${this.metersToModTotals.numRS} route schedules will be deleted. `;
            if(this.regionsAffected) {
                txt += `from region(s): ${this.regionsAffected}. `;
            }
            txt += `<br/>New Route Schedules will be created for ${this.selectedProcessingLocation} for the current `;
            txt += `fill cycle of ${this.scheduleNextCycle}.`;
        }
        return txt;
    }

    convertApexStringDateToLocalDate(sDate) {
        let utcDate = new Date(sDate);
        return new Date(utcDate.getTime() + utcDate.getTimezoneOffset());
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