import {LightningElement,wire,track} from 'lwc';
import AccelUtilsSvc from "c/accelUtilsSvc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import retrieveRouteSchedulesForProcessor   from '@salesforce/apex/clRouteScheduleController.retrieveRouteProcessingSheetsForProcessor';
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import {NavigationMixin} from "lightning/navigation";
import Id from '@salesforce/user/Id';
import {reduceErrors} from "c/ldsUtils";
import mainTemplate from './clRouteProcessingFill.html';
import stencil from './clRouteProcessingFillStencil.html';
import {getConstants} from "c/clConstantUtil";
import lblCardTitle from '@salesforce/label/c.CL_Process_Fill_Routes_Card_Title'

const PAGE_FILL_RPS_SHEETS = 'processing-fill-collections';
const PAGE_HOME = 'home';

const MAP_KEY_RS_DATA = 'RS_WRAPS';
const MAP_KEY_ROUTE_DATA = 'ROUTE_DATA';
const MAP_KEY_ROUTE_SCHEDULE_ID = 'ROUTE_SCHEDULE_ID';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const GLOBAL_CONSTANTS = getConstants();

const MDT_DEV_NAME = 'Route_Processing_Fill';

export default class ClRouteProcessingFill extends NavigationMixin(LightningElement) {

    labels = {lblCardTitle};

    _wiredRsDto;
    _wiredPageMdt;
    _prevTemplateSize = 'SMALL';
    _doneSearching = false;
    _isProcessing = false;
    _allDataLoaded = false;
    _outerContainerClass= 'slds-m-around_xxx-small accel-test-borders';
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    //_collectionDate = this.tomorrowsDate;
    //_collectionDate = this.todaysDate;
    _fillDate = this.todaysDate;

    _userId = Id;
    _selectedRsId;
    _pageMdtDevName = MDT_DEV_NAME;

    @track pageMdt;
    @track routeData;
    @track routeScheduleId;
    @track rsData;
    @track emptyBodyText;
    @track uiErrorMsg = {};
    @track rsActions = [];


    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingFill',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {

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
//(Id userId, Date fillDate, String type) {
    //@wire(retrieveRouteSchedulesForProcessor, {type: 'fill',userId: '$_userId', fillDate: '$_fillDate'})
    @wire(retrieveRouteSchedulesForProcessor, {userId: '$_userId', dDate: '$_fillDate',type:'fill'})
    retrieveRpsData(wiredDto) {
        this._wiredRsDto = wiredDto;
        const { data, error } = this._wiredRsDto;
        if(data) {
            this._doneSearching = true;
            if(data.isSuccess) {
                console.log('----> clRoute Schedules dto=',JSON.parse(JSON.stringify(data)));
                this.rsData = this._accelUtils.getMapValue(MAP_KEY_RS_DATA,data.values);
            } else {
                this.rsData = undefined;
                this.emptyBodyText = data.message;
                this.uiErrorMsg.body = data.message + '. Please contact an administrator [email addy?]';
            }
            console.log('----> clRoute Schedules rps dto=',JSON.parse(JSON.stringify(data)));
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
            console.error(this.error);
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
        // this.startRouteSchedule();
        // this.updateRpsStatus('In Progress');
        this.navigate(PAGE_FILL_RPS_SHEETS,rsId);
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
    navigate(pageName,rsId) {
        try {
            console.log('attempting to nav to pageName:'+pageName);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {rsId: rsId}
            });
            //this._disconnectCb = true;
        } catch (e) {
            console.error(e);
        }
    }

    get showRsData() {
        return this.rsData && this._allDataLoaded;
    }

    get tomorrowsDate() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate() + 1);
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        return rightNow;
    }

    get tomorrowsDateFormatted() {
        //return this.tomorrowsDate.toISOString().slice(0,10);
        return this.tomorrowsDate.toLocaleDateString();
    }


    get todaysDate() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate());
        //rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        rightNow.setMinutes(0);
        rightNow.setHours(0);

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

}