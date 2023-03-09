import {LightningElement,wire,track} from 'lwc';
import AccelUtilsSvc from "c/accelUtilsSvc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import retrieveRouteSchedulesForProcessor   from '@salesforce/apex/clRouteScheduleController.retrieveRouteProcessingSheetsForProcessorNoCache';

import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import { CurrentPageReference,NavigationMixin} from "lightning/navigation";
import Id from '@salesforce/user/Id';
import {reduceErrors} from "c/ldsUtils";
import mainTemplate from './clRouteProcessingSchedules.html';
import stencil from './clRouteProcessingSchedulesStencils.html';
import { getConstants } from 'c/clConstantUtil';

const PAGE_PROCESS_RPS_SHEETS = 'processing-process-collections';
const PAGE_PROCESS_SCHEDULES = 'processing-schedules';
const PAGE_NAME_PROCESS = 'process-routes-group';
//const PAGE_PROCESS_RPS_SHEETS = 'processing_process_collections__c';
const PAGE_HOME = 'home';

const MAP_KEY_RS_DATA = 'RS_WRAPS';
const MAP_KEY_ROUTE_DATA = 'ROUTE_DATA';
const MAP_KEY_COLLECTION_DATE_FORMATTED = 'COLLECTION_DATE_FORMATTED';
const MAP_KEY_ROUTE_SCHEDULE_ID = 'ROUTE_SCHEDULE_ID';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';

const MDT_DEV_NAME = 'Route_Processing_Fill';
const GLOBAL_CONSTANTS = getConstants();

export default class ClRouteProcessingSchedules extends NavigationMixin(LightningElement) {
    _wiredRsDto;
    _wiredPageMdt;
    _prevTemplateSize = 'SMALL';
    _doneSearching = false;
    _isProcessing = false;
    _allDataLoaded = false;
    _outerContainerClass= 'slds-m-around_xxx-small accel-test-borders';
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _collectionDate;
    _userId = Id;
    _cacheBust = Math.random();
    _selectedRsId;
    _pageMdtDevName = MDT_DEV_NAME;
    currentPageReference = null;
    urlStateParameters = null;

    @track pageMdt;
    @track routeData;
    @track routeScheduleId;
    @track rsData;
    @track emptyBodyText;
    @track uiErrorMsg = {};
    @track rsActions = [];
    @track rsGroupDate;
    @track collectionDateFormatted;
    // @track


    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingSchedules',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
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
    //@wire(retrieveRouteSchedulesForProcessor, {type:'process',userId: '$_userId', collectionDate: '$_collectionDate', cacheBust: '$_cacheBust'})
    @wire(retrieveRouteSchedulesForProcessor, {userId: '$_userId', collectionDate: '$_collectionDate', type:'process', cacheBust: '$_cacheBust'})
    retrieveRouteSchedules(wiredDto) {
        this._wiredRsDto = wiredDto;
        const { data, error } = this._wiredRsDto;
        if(data) {
            this._doneSearching = true;
            if(data.isSuccess) {
                this.rsData = this._accelUtils.getMapValue(MAP_KEY_RS_DATA,data.values);
                this.collectionDateFormatted = this._accelUtils.getMapValue(MAP_KEY_COLLECTION_DATE_FORMATTED,data.values);
            } else {
                this.rsData = undefined;
                this.emptyBodyText = data.message;
                //this.uiErrorMsg.body = data.message + '. Please contact an administrator [email addy?]';
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
        this.navigate(PAGE_PROCESS_RPS_SHEETS,rsId,this.rsGroupDate);
    }
    handleBackClicked(evt) {
        this.navigate(PAGE_NAME_PROCESS);
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
            console.log('attempting to nav to pageName:'+pageName + '..rsId='+rsId + '.. rsGroupDate='+rsGroupDate);

            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {rsId: rsId, rsGroupDate : rsGroupDate}
            });
            //this._disconnectCb = true;
        } catch (e) {
            console.error(e);
        }
    }

    get showRsData() {
        return this.rsData && Array.isArray(this.rsData) && this.rsData.length > 0 && this._allDataLoaded;
    }
    blah() {
        //let d = new Date(this.rsGroupDate);
        //d.setDate(d.getDate());
        //d.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        //let d  = this.rsGroupDate.setDate(this.rsGroupDate.getDate() + 1);
        //alert(d.toLocaleDateString());
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
       // return this.pageMdt && this.pageMdt.Show_Back_Button__c;
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
              //  this.showToast('dev note','rs group date set to '+this.rsGroupDate,'info');
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
}