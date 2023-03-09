import {LightningElement,wire,track,api} from 'lwc';
import AccelUtilsSvc from "c/accelUtilsSvc";
import Logger from "c/logger";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import retrieveRouteSchedulesForFiller   from '@salesforce/apex/clRouteScheduleController.retrieveRouteSchedulesGroupedForFiller';

import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import {NavigationMixin} from "lightning/navigation";
import Id from '@salesforce/user/Id';
import {reduceErrors} from "c/ldsUtils";
import mainTemplate from './clRouteProcessingGroupFill.html';
import stencil from './clRouteProcessingGroupFillStencil.html';
import { getConstants } from 'c/clConstantUtil';

const PAGE_PROCESS_FILL_SCHEDULES = 'fill-schedules';
const PAGE_HOME = 'home';

const MAP_KEY_RS_DATA = 'RS_GROUP_WRAPS';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';

const MDT_DEV_NAME = 'Route_Processing_Fill';
const GLOBAL_CONSTANTS = getConstants();
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class ClRouteProcessingGroupFill extends  NavigationMixin(LightningElement) {

    @api cardTitle = 'Filling';
    @api cardSubtitle = 'Incomplete Routes';
    @api numOfDaysBackForRouteSchedules = 14;
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

    _wiredRsDto;
    _wiredPageMdt;
    _doneSearching = false;
    _isProcessing = false;
    _allDataLoaded = false;
    _accelUtils = new AccelUtilsSvc(false);
    _collectionDate = this.todaysDate;
    _userId = Id;
    _cacheBust = Math.random();
    _pageMdtDevName = MDT_DEV_NAME;
    _logger;
    _debugConsole;


    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingGroupFill',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
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
     * @param wiredDto
     */
    @wire(retrieveRouteSchedulesForFiller,
        {userId: '$_userId',numOfDaysBackForRouteSchedules: '$numOfDaysBackForRouteSchedules',cacheBust : '$_cacheBust'})
    retrieveRsData(wiredDto) {
        this._wiredRsDto = wiredDto;
        const { data, error } = this._wiredRsDto;
        if(data) {
            this._doneSearching = true;
            this.log(DEBUG,'---> cl RS dto',data);
            if(data.isSuccess) {
                this.rsData = this._accelUtils.getMapValue(MAP_KEY_RS_DATA,data.values);
            } else {
                this.rsData = undefined;
                this.emptyBodyText = data.message;
                this.uiErrorMsg.body = data.message + '. Please contact an administrator [email addy?]';
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
            this.log(ERROR,'---> error retrieving mdt',this.error);
        } else if (data) {
            this.pageMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
        }
    }

    /**
     * Handle the rps card selected event.
     * @param evt
     */
    handleItemSelected(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        if(!this.navigating) { //  prevent rapid double click
            this.navigating = true;
            const rsGroupDate = evt.currentTarget.dataset.rsgroupdate;
            this.navigate(PAGE_PROCESS_FILL_SCHEDULES, rsGroupDate)
        }
        this.navigating = false;
    }

    handleBackClicked(evt) {
        this.navigate(PAGE_HOME);
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
    navigate(pageName,rsGroupDate) {
        try {
            this.log(DEBUG,'---> navigating to page ' + pageName + ' with date '+rsGroupDate);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {rsGroupDate: rsGroupDate}
            });
        } catch (e) {
            console.error(e);
        }
    }

    get showRsData() {
        return this.rsData && Array.isArray(this.rsData) && this.rsData.length > 0 && this._allDataLoaded;
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
        return this.pageMdt && this.pageMdt.Show_Back_Button__c;
    }

    get showNoData() {
        return !this.rsData || this.rsData.length < 1;
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