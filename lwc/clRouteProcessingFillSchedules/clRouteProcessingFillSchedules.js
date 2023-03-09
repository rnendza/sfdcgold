import {LightningElement, wire, track, api} from 'lwc';
import AccelUtilsSvc from "c/accelUtilsSvc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import retrieveRouteSchedulesForProcessor   from '@salesforce/apex/clRouteScheduleController.retrieveRouteProcessingSheetsForProcessorNoCache';

import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import { CurrentPageReference,NavigationMixin} from "lightning/navigation";
import Id from '@salesforce/user/Id';
import {reduceErrors} from "c/ldsUtils";
import mainTemplate from './clRouteProcessingFillSchedules.html';
import stencil from './clRouteProcessingFillSchedulesStencil.html';
import { getConstants } from 'c/clConstantUtil';
import Logger from "c/logger";

const PAGE_PROCESS_FILL_RPS_SHEETS = 'processing-fill-collections';
const PAGE_NAME_FILL = 'processing-fill';

const MAP_KEY_RS_DATA = 'RS_WRAPS';
const MAP_KEY_COLLECTION_DATE_FORMATTED = 'COLLECTION_DATE_FORMATTED';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';

const MDT_DEV_NAME = 'Route_Processing_Fill';
const GLOBAL_CONSTANTS = getConstants();
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class ClRouteProcessingFillSchedules  extends NavigationMixin(LightningElement) {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    @track pageMdt;
    @track routeData;
    @track routeScheduleId;
    @track rsData;
    @track emptyBodyText;
    @track uiErrorMsg = {};
    @track rsActions = [];
    @track rsGroupDate;
    @track collectionDateFormatted;

    _wiredRsDto;
    _wiredPageMdt;
    _doneSearching = false;
    _isProcessing = false;
    _allDataLoaded = false;
    _accelUtils = new AccelUtilsSvc(false);
    _collectionDate;
    _userId = Id;
    _cacheBust = Math.random();
    _selectedRsId;
    _pageMdtDevName = MDT_DEV_NAME;
    currentPageReference = null;
    urlStateParameters = null;
    _logger;
    _debugConsole;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingFillSchedules',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.debugConsole = true;  // @todo remove. change to builder prop.
    }

    render() {
        return this._allDataLoaded ? mainTemplate : stencil;
    }
    renderedCallback() {

    }
    /**
     * Retrieve all route processing sheets for the userId and tomorrows date.
     * @param wiredDto
     */
    @wire(retrieveRouteSchedulesForProcessor, {userId: '$_userId', collectionDate: '$_collectionDate', type:'fill', cacheBust: '$_cacheBust'})
    retrieveRouteSchedules(wiredDto) {
        this._wiredRsDto = wiredDto;
        const { data, error } = this._wiredRsDto;
        if(data) {
            this.log(DEBUG,'--> schedules dto',data.values);
            this._doneSearching = true;
            if(data.isSuccess) {
                this.rsData = this._accelUtils.getMapValue(MAP_KEY_RS_DATA,data.values);
                this.collectionDateFormatted = this._accelUtils.getMapValue(MAP_KEY_COLLECTION_DATE_FORMATTED,data.values);
            } else {
                this.rsData = undefined;
                this.emptyBodyText = data.message;
            }
            this._isProcessing = false;
            this._allDataLoaded = true;
        } else if (error) {
            this._doneSearching = true;
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving data: '+this.error,'error');
            this.uiErrorMsg.body = this.error;
            this._isProcessing = false;
            this._allDataLoaded = true;
        }
    }


    /**
     *  Get the page level custom meta-data.
     * @param wiredData
     */
    @wire(retrieveMdt, { mdtDevName: '$_pageMdtDevName' })
    wiredMdt(wiredData) {
        this._wiredPageMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            this.log(ERROR,'--> error getting mdt',error);
        } else if (data) {
            this.pageMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
        }
    }

    /**
     * Handle the rps card selected event.
     * @param evt
     */
    handleItemSelected(evt) {
        const rsId = evt.currentTarget.dataset.rsid
        this._selectedRsId = rsId;
        evt.preventDefault();
        evt.stopPropagation();
        this.navigate(PAGE_PROCESS_FILL_RPS_SHEETS,rsId,this.rsGroupDate);
    }
    handleBackClicked(evt) {
       this.navigate(PAGE_NAME_FILL);
    }
    /**
     * Actions (top right of card). There are none yet but here for future use.
     * @param event
     */
    handleAction(event) {
        event.preventDefault();
        const tileAction = event.detail.action.value;
        this.showToast('',tileAction + ' not yet supported','info');
    }
    /**
     *
     * @param pageName
     * @todo the nav mix in is buggy with communities and caching.
     */
    navigate(pageName,rsId,rsGroupDate) {
        try {
            this.log(DEBUG,'attempting to nav to pageName:'+pageName + '..rsId='+rsId + '.. rsGroupDate='+rsGroupDate);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {rsId: rsId, rsGroupDate : rsGroupDate}
            });
        } catch (e) {
            console.error(e);
        }
    }

    get showRsData() {
        return this.rsData && Array.isArray(this.rsData) && this.rsData.length > 0 && this._allDataLoaded;
    }

    getAdjustedDate(originalDt) {
        let d = new Date(originalDt);
        return d;
    }

    get todaysDate() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate());
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        return rightNow;
    }

    get todaysDateFormatted() {
        return this.todaysDate.toLocaleDateString();
    }

    get showBackButton() {
        return true;
    }

    get showNoData() {
        return !this.rsData || this.rsData.length < 1;
    }
    /**
     * Get url state for purposes of navigating to other pages and returning back.
     * @param currentPageReference
     */
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.urlStateParameters = currentPageReference.state;
            if(this.urlStateParameters) {
                this.setParametersBasedOnUrl();
            }
        }
    }
    setParametersBasedOnUrl() {
        if(this.urlStateParameters && this.urlStateParameters.rsGroupDate) {
            this.rsGroupDate = this.urlStateParameters.rsGroupDate;
            this._collectionDate = this.getAdjustedDate(this.rsGroupDate);
            this._cacheBust = Math.random();
        }
    }
    /**
     *
     * @param title
     * @param msg
     * @param variant
     */
    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
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