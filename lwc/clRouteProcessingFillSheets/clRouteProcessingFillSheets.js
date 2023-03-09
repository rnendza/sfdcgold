import {api, track, LightningElement, wire} from 'lwc';
import AccelUtilsSvc from "c/accelUtilsSvc";
import {reduceErrors} from 'c/ldsUtils';
import { getConstants } from 'c/clConstantUtil';
import Id from "@salesforce/user/Id";
import retrieveRpsSheets from '@salesforce/apex/clRouteProcessingSheetsController.retrieveRouteProcessingSheetsForProcessorNoCache'
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import mainTemplate from "./clRouteProcessingFillSheets.html";
import stencil from "./clRouteProcessingFillSheetsStencil.html";
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import Logger from "c/logger";

import lblCardTitle from '@salesforce/label/c.CL_Process_Fill_Collections_Card_Title'

const MAP_KEY_RPS_DATA = 'RPS_WRAPS';
const MAP_KEY_ROUTE_DATA = 'ROUTE_DATA';
const MAP_KEY_ROUTE_SCHEDULE_DATA = 'ROUTE_SCHEDULE_DATA';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const MAP_KEY_COLLECTION_DATE_FORMATTED = 'COLLECTION_DATE_FORMATTED';

const PAGE_PROCESSING_FILL_OUTBOUND ='processing-fill-outbound';
const PAGE_PROCESSING_FILL_SCHEDULES = 'fill-schedules';

const MDT_DEV_NAME = 'Route_Processing_Fill';
const GLOBAL_CONSTANTS = getConstants();
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class ClRouteProcessingFillSheets extends NavigationMixin(LightningElement) {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    @track currentPageReference = null;
    @track urlStateParameters = null;
    @track routeId;
    @track routeScheduleId;
    @track rpsData;
    @track routeData;
    @track routeScheduleData;
    @track rpsActions = [];
    @track routeOptions = [];
    @track runningUser;
    @track selectedRouteId;
    @track uiErrorMsg = {};
    @track outerContainerClass= 'slds-m-around_xxx-small accel-rps-outer-container accel-test-borders';
    @track openVehicleForm;
    @track emptyBodyText;
    @track pageMdt;
    @track cardSubtitle;

    labels = {lblCardTitle};
    _wiredRpsDto;
    _wiredPageMdt;
    _accelUtils = new AccelUtilsSvc(false);
    _userId = Id;
    _doneSearching = false;
    _isProcessing = true;
    _allDataLoaded = false;
    _routeFillDate = this.todaysDate;
    _selectedRpsId;
    _pageMdtDevName = MDT_DEV_NAME;
    _invalidParameters = false;
    _logger;
    _debugConsole;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingFillSheets',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
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
     * Retrieve all route processing sheets for the userId and todays date.
     * @param wiredDto
     */
    @wire(retrieveRpsSheets,
        {type:'fill', userId: '$_userId', routeScheduleId: '$routeScheduleId', collectionDate: '$_routeFillDate',cacheBust:'$_cacheBust'})
    retrieveRpsData(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const { data, error } = this._wiredRpsDto;
        if(data) {
            this.log('--> rps dto',data.values);
            this._doneSearching = true;
            if(data.isSuccess) {
                this.rpsData = this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, data.values);
                this.routeData = this._accelUtils.getMapValue(MAP_KEY_ROUTE_DATA,data.values);
                this.routeScheduleData = this._accelUtils.getMapValue(MAP_KEY_ROUTE_SCHEDULE_DATA,data.values);
                this.cardSubtitle = this._accelUtils.getMapValue(MAP_KEY_COLLECTION_DATE_FORMATTED,data.values);
            } else {
                this.rpsData = undefined;
                this.emptyBodyText = data.message;
                this.uiErrorMsg.body = data.message + '. Please contact an administrator [email addy?]';
            }
            this._isProcessing = false;
            this._allDataLoaded = true;
        } else if (error) {
            this._doneSearching = true;
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving data: '+this.error,'error');
            this.log(ERROR,'---> rps dto error',error);
            this.uiErrorMsg.body = this.error;
            this._isProcessing = false;
            this._allDataLoaded = true;
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this._currentPageReference = currentPageReference;
            this.urlStateParameters = currentPageReference.state;
            if(this.urlStateParameters) {
                this.setParametersBasedOnUrl();
            }
        }
    }
    setParametersBasedOnUrl() {
        if(!this._disconnectCb) {
            if(!this.urlStateParameters || !this.urlStateParameters.rsId) {
                this._invalidParameters = true;
                this._allDataLoaded = true;
                return;
            }
            if (this.urlStateParameters.rsId) {
                if(this.urlStateParameters.rsId != null) {
                    this.routeScheduleId = this.urlStateParameters.rsId;
                }
            }
            if (this.urlStateParameters.rsGroupDate) {
                if(this.urlStateParameters.rsGroupDate != null) {
                    this.rsGroupDate = this.urlStateParameters.rsGroupDate;
                    this._routeFillDate = this.getAdjustedDate(this.rsGroupDate);
                    this._cacheBust = Math.random();
                }
            } else {
                this._routeFillDate = this.todaysDate;
                this._cacheBust = Math.random();
            }
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
            console.error(this.error);
        } else if (data) {
            this.pageMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
        }
    }

    handleBackClicked(evt) {
        this.navigate(PAGE_PROCESSING_FILL_SCHEDULES);
    }
    /**
     * Handle the rps card selected event.
     * @param evt
     */
    handleItemSelected(evt) {
        const rpsId = evt.currentTarget.dataset.rpsid
        this._selectedRpsId = rpsId;
        evt.preventDefault();
        evt.stopPropagation();
        this.navigate(PAGE_PROCESSING_FILL_OUTBOUND,rpsId);
    }

    get showRpsData() {
        return this.rpsData && this._allDataLoaded;
    }

    get showNoData() {
        return !this.rpsData || this.rpsData.length < 1;
    }

    get tomorrowsDate() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate() + 1);
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        return rightNow;
    }

    get todaysDate() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate());
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        return rightNow;
    }
    get tomorrowsDateFormatted() {
        return this.tomorrowsDate.toLocaleDateString();
    }
    get todaysDateFormatted() {
        return this.todaysDate.toLocaleDateString();
    }

    get showBackButton() {
        return this.pageMdt && this.pageMdt.Show_Back_Button__c;
    }

    getAdjustedDate(originalDt) {
        let d = new Date(originalDt);
        return d;
    }
    /**
     *
     * @param pageName
     * @todo the nav mix in is buggy with communities and caching.
     */
    navigate(pageName,rpsId) {
        try {
            this.log(DEBUG,'---> attempting to nav to pageName:'+pageName + ' with rpsID='+rpsId + '.. and rsGroupDAte='+this.rsGroupDate);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {
                    rpsId : rpsId,
                    rsGroupDate : this.rsGroupDate
                }
            });
        } catch (e) {
            console.error(e);
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