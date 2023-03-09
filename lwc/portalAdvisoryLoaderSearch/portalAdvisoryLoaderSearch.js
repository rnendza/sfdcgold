import {LightningElement,api,track} from 'lwc';
import {uiHelper} from "c/portalAdminUtilsUiHelper";
import {dateUtils} from "c/portalAdminDateUtils";
import doLiveSearch from '@salesforce/apex/PortalAdvisoryLoaderController.doLiveSearch';
import {getConstants} from "c/clConstantUtil";
import Logger from 'c/logger'

const MAP_KEY_USER_RECORDS     = 'MAP_KEY_USER_RECORDS';
const MAP_KEY_CALLOUT_PARAMS    = 'MAP_KEY_CALLOUT_PARAMS';
const START_DATE_MONTHS_BACK   = 1;
const GLOBAL_CONSTANTS = getConstants();
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class PortalAdvisoryLoaderSearch extends LightningElement {

    @api cardTitle = 'Live Search';
    @api searchButtonVariant = 'brand';
    @api searchButtonLabel = 'Live Search';
    @api pullImageData;
    @api isUpserting;
    @api
    set customMdtDevName(val) {this._customMdtDevName = val;this._calloutParams.customMdtDevName = val;}
    get customMdtDevName() {return this._customMdtDevName;}

    @api
    set startDate(val) { this._startDate = val;this._calloutParams.dStartDate = val;}
    get startDate() { return this._startDate;};

    @api
    set endDate(val) { this._endDate = val;this._calloutParams.dEndDate = val;}
    get endDate() { return this._endDate;};

    @api
    set matchToSfdcRecs(val) { this._matchToSfdcRecs = val;this._calloutParams.matchToSfdcRecs = val;}
    get matchToSfdcRecs() { return this._matchToSfdcRecs;};

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    _startDate;
    _startDateMax;
    _endDate;
    _endDateMax;
    _endDateMin;
    _serverRecords;
    _isSearching;
    _customMdtDevName;
    _matchToSfdcRecs;
    _debugConsole;
    _logger;

    @track _calloutParams = {
        dStartDate: this._startDate,
        dEndDate: this._endDate,
        customMdtDevName: this.customMdtDevName,
        pullImageDate: this.pullImageData,
        matchToSfdcRecs: this._matchToSfdcRecs
    }

    constructor() {
        super();
        console.info('%c----> /lwc/portalAdvisoryLoaderSearch', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }


    connectedCallback() {
        this.pullImageData = true;
        this._calloutParams.pullImageData = true;
        this.initDateParams();
    }

    get yesterdaysDateISO() {
        return dateUtils.yesterdaysDateISO;
    }

    search() {
        this._isSearching = true;
        let params = { calloutParams: this._calloutParams};

        this.log(DEBUG,'calling rest search svc -->',params);

        doLiveSearch(params)
            .then((result) => {
                if(result.isSuccess) {
                    this._serverRecords = uiHelper.getMapValue(MAP_KEY_USER_RECORDS,result.values);
                    const calloutParamsModified = uiHelper.getMapValue(MAP_KEY_CALLOUT_PARAMS,result.values);
                    this.log(DEBUG,'modified callout params -->',calloutParamsModified);
                    this.dispatchEvent(new CustomEvent('searchcompleted', {
                        detail: { 'success' : true, 'payload' : { 'values' : this._serverRecords, 'calloutParams' : calloutParamsModified} }
                    }));
                } else {
                    this._serverRecords = uiHelper.getMapValue(MAP_KEY_USER_RECORDS,result.values);
                    let mode = 'dismissible';
                    this.log(WARN,'search results warning -->',result);
                    let title;
                    if(result.severity === 'error') {
                        mode='sticky';
                        title = 'Error on Call to provider';
                    }
                    if(result.severity === 'warning' && (this._serverRecords == null || this._serverRecords.length === 0)) {
                        const calloutParamsModified = uiHelper.getMapValue(MAP_KEY_CALLOUT_PARAMS,result.values);
                        this.dispatchEvent(new CustomEvent('searchcompleted', {
                            detail: { 'failure' : true, 'payload' : { 'values' : this._serverRecords, 'calloutParams' : calloutParamsModified} }
                        }));
                    }
                    uiHelper.showToast(this,title,result.message,result.severity,mode);
                }
            })
            .catch((error) => {
                console.error(error);
                let msg = error.body.exceptionType + ' - ' + error.body.message;
                if(error.body.message.includes('limit') || error.body.message.includes('heap')) {
                    msg += '. Please tighten your search parameters.';
                }
                uiHelper.showToast(this,'Error on Call to Provider',msg,'error','sticky');
            })
            .finally(() => {
                this._isLoading = false;
                this._isSearching = false;
            });
    }

    initDateParams() {
        this._startDate = dateUtils.getMonthsBackDateISO(dateUtils.todaysDate,START_DATE_MONTHS_BACK);
        this._startDateMax = this.yesterdaysDateISO;
        this._endDate = dateUtils.todaysDateISO;
        this._endDateMax = dateUtils.todaysDateISO;
        this._endDateMin = this._startDate;
    }

    handleChange(evt) {
        const dt = evt.target.value;
        const name = evt.target.name;
        switch (name) {
            case 'startDate':
                this.startDate = dt;
                console.log('---> change startDate=',this.startDate);
                break;
            case 'endDate':
                this.endDate = dt;
                console.log('---> change endDate=',this.endDate);
                break;
        }
    }

    handleSearchFiltersClose(evt) {
        this.dispatchEvent(new CustomEvent('closesearchfilter'));
    }

    handleButtonClick(event){
        if(event && event.currentTarget && event.currentTarget.dataset) {
            const buttonId = event.currentTarget.dataset.id;
            switch (buttonId) {
                case 'search':
                    this.startDate = this.template.querySelector(`[data-id="startDate"]`).value;
                    this.endDate = this.template.querySelector(`[data-id="endDate"]`).value;
                    this.search();
                    break;
            }
        }
    }

    get showSearchInputs() {
        return !this._isSearching && !this.isUpserting;
    }

    get showStencil() {
        return this._isSearching || this.isUpserting;
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