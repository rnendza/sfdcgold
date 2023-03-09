import {api, track, LightningElement, wire} from 'lwc';
import AccelUtilsSvc from "c/accelUtilsSvc";
import {reduceErrors} from 'c/ldsUtils';
import Id from "@salesforce/user/Id";
import retrieveRpsSheets from '@salesforce/apex/clRouteProcessingSheetsController.retrieveRouteProcessingSheetsForProcessorNoCache';
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import {loadScript, loadStyle} from "lightning/platformResourceLoader";
import mainTemplate from "./clRouteProcessingProcessSheets.html";
import stencil from "./clRouteProcessingProcessSheetsStencil.html";
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { getConstants } from 'c/clConstantUtil';
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';

import lblCardTitle from '@salesforce/label/c.CL_Process_Process_Collections_Card_Title'

const MAP_KEY_RPS_DATA = 'RPS_WRAPS';
const MAP_KEY_ROUTE_DATA = 'ROUTE_DATA';
const MAP_KEY_ROUTE_SCHEDULE_DATA = 'ROUTE_SCHEDULE_DATA';
const MAP_KEY_ROUTE_SCHEDULE_ID = 'ROUTE_SCHEDULE_ID';
const MAP_KEY_COLLECTION_DATE_FORMATTED = 'COLLECTION_DATE_FORMATTED';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';

const METERS_PAGE_NAME = 'meters';
const PAGE_METER_READINGS = 'meterreadings';
const PAGE_PROCESSING_PROCESS ='processing-process';
const PAGE_PROCESSING_SCHEDULES = 'processing-schedules';
const PAGE_PROCESSING_PROCESS_ACTUAL_DROP ='processing-process-actual-drop';

const MDT_DEV_NAME = 'Route_Processing_Fill';
const MDT_APP_DEV_NAME = 'Application';
const GLOBAL_CONSTANTS = getConstants();


export default class ClRouteProcessingProcessSheets extends NavigationMixin(LightningElement) {

    @track currentPageReference = null;
    @track urlStateParameters = null;
    @track routeId;
    @track routeScheduleId;
    @track rpsData;
    @track rsGroupDate;
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
    @track cardTitleLabel;
    @track cardSubtitle;

    labels = {lblCardTitle};
    _cacheBust;
    _rsId;
    _rsGroupDate;
    _wiredRpsDto;
    _wiredPageMdt;
    _wiredRouteScheduleDto;
    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _lastMouseOverListId = null;
    _listNodes = [];
    _userId = Id;
    _doneSearching = false;
    _isProcessing = true;
    _allDataLoaded = false;
    _collectionDate;
    _changedTemplateSize = false;
    _openVehicleForm = false;
    _prevTemplateSize = 'SMALL';
    _selectedRpsId;
    _pageMdtDevName = MDT_DEV_NAME;
    _appMdtDevName = MDT_APP_DEV_NAME;
    _wiredAppMdt;
    _invalidParameters = false;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingProcessSheets',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {

    }

    render() {
        return this._allDataLoaded ? mainTemplate : stencil;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            this.loadFontAwesome();
        }
    }

    /**
     * Retrieve all route processing sheets for the userId and todays date.
     * @param wiredDto
     */
    @wire(retrieveRpsSheets, {type: 'process',userId: '$_userId', routeScheduleId: '$routeScheduleId', collectionDate: '$_collectionDate',cacheBust: '$_cacheBust'})
    retrieveRpsData(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const { data, error } = this._wiredRpsDto;
        if(data) {
            this._doneSearching = true;
            if(data.isSuccess) {
                this.rpsData = this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, data.values);
                this.routeData = this._accelUtils.getMapValue(MAP_KEY_ROUTE_DATA,data.values);
                this.routeScheduleData = this._accelUtils.getMapValue(MAP_KEY_ROUTE_SCHEDULE_DATA,data.values);
            } else {
                this.rpsData = undefined;
                this.emptyBodyText = data.message;
                this.uiErrorMsg.body = data.message + '. Please contact an administrator [email addy?]';
            }
            this.cardSubtitle = this._accelUtils.getMapValue(MAP_KEY_COLLECTION_DATE_FORMATTED,data.values);
            console.log('----> clRouteProcessingSheets rps dto=',JSON.parse(JSON.stringify(data)));
            this._isProcessing = false;
            this._allDataLoaded = true;
        } else if (error) {
            this._doneSearching = true;
            console.error(error);
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving data: '+this.error,'error');
            console.error(this.error);
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
                console.error('INVALID URL PARAMETERS. WE NEED AT LEAST ROUTE SCHEDULE ID urlParameters=',JSON.stringify(this.urlStateParameters));
                this._allDataLoaded = true;
                return;
            }
            if (this.urlStateParameters.rsId) {
                if(this.urlStateParameters.rsId != null) {
                    this._invalidParameters = false;
                    this.routeScheduleId = this.urlStateParameters.rsId;
                }
            }
            if (this.urlStateParameters.rsGroupDate) {
                if(this.urlStateParameters.rsGroupDate != null) {
                    this.rsGroupDate = this.urlStateParameters.rsGroupDate;
                    this._collectionDate = this.getAdjustedDate(this.rsGroupDate);
                    console.log('---> param setter called.. have collection date from rsGroupDate');
                    this.cardTitleLabel = 'Collections';
                    //this.cardSubtitle = this._collectionDate;
                    this._cacheBust = Math.random();
                }
            } else {
                this.cardTitleLabel = this.labels.lblCardTitle;
                console.log('---> param setter called.. setting collection date to todays date!');
                this._collectionDate = this.todaysDate;
                //this.cardSubtitle = this.todaysDateFormatted;
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

    /**
     *  Get the app level custom meta-data.
     *
     *  @param wiredData
     *  @see Cash_Logistics_Setting__mdt (Application type)
     */
    @wire(retrieveMdt, { mdtDevName: '$_appMdtDevName' })
    wiredAppMdt(wiredData) {
        this._wiredAppMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error('---> error getting mdt',this.error);
        } else if (data) {
            this.appMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
            if(this.appMdt){
                console.info('---> app mdt=',JSON.parse(JSON.stringify(this.appMdt)))
                //alert(this.appMdt.Use_Processor_Grouping__c);
                if(this.appMdt.Use_Processor_Grouping__c) {

                }
            }
        }
    }

    handleBackClicked(evt) {
        let page = PAGE_PROCESSING_PROCESS;
        if(this.rsGroupDate) {
            page = PAGE_PROCESSING_SCHEDULES;
        }
        this.navigate(page);
    }
    /**
     * Handle the rps card selected event.
     * @param evt
     */
    handleItemSelected(evt) {
        const rpsId = evt.currentTarget.dataset.rpsid
        this._selectedRpsId = rpsId;
        const accountId = evt.currentTarget.dataset.accountid;
        evt.preventDefault();
        evt.stopPropagation();
        //this.showToast('DEV',' NYI - navigate','info');
        this.navigate(PAGE_PROCESSING_PROCESS_ACTUAL_DROP,rpsId);
        // this.startRouteSchedule();
        // this.updateRpsStatus('In Progress');
        // this.navigate(PAGE_METER_READINGS,rpsId,accountId,this.routeId,RECORD_TYPE_VGT);
    }

    get showRpsData() {
        return this.rpsData && Array.isArray(this.rpsData) && this.rpsData.length > 0 && this._allDataLoaded;
    }

    get showNoData() {
        return !this.rpsData || this.rpsData.length < 1;
    }
    getAdjustedDate(originalDt) {
        let d = new Date(originalDt);
        return d;
    }
    get todaysDate() {
        let rightNow = new Date();
        // rightNow.setDate(rightNow.getDate());
        // rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        return rightNow;
    }

    get todaysDateFormatted() {
        return this.todaysDate.toLocaleDateString();
    }


    get showBackButton() {
        return this.pageMdt && this.pageMdt.Show_Back_Button__c;
    }

    /**
     * Navigate to another community page.
     *
     * @param pageName  The community page name to go to
     * @param rpsId     rpsId... hmm might have been misnamed should probably be rsId=.
     *
     * @todo clean this a bit / examine disconnected callback.
     * @todo pass rsGroupDate as opposed to referring to class var.
     */
    navigate(pageName,rpsId) {
        try {
            console.log('attempting to nav to pageName:'+pageName + '..rpsId'+rpsId+'.. rsGroupDate='+this.rsGroupDate);
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
            //this._disconnectCb = true;
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
     * Loads font awesome js and css for fonts not available in SLDS.
     */
    loadFontAwesome() {
        Promise.all([
            // loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/all.css'),
        ])
            .then(() => {
                //console.log('fa loaded');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }

}