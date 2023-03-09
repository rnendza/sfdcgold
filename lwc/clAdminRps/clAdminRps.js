import {api, LightningElement, track, wire} from 'lwc';
import {themeOverrider} from "c/clAdminOnlyCardTheme";
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import createRsData from '@salesforce/apex/clRouteProcessingSheetsController.createRouteSchedules';
import {fireEvent} from 'c/pubSub';
import {reduceErrors} from "c/ldsUtils";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveMdt   from '@salesforce/apex/clRouteProcessingSheetsController.retrieveMdtNoCache';
import {refreshApex} from "@salesforce/apex";
import {subscribe, unsubscribe,publish, APPLICATION_SCOPE, MessageContext} from 'lightning/messageService';
import clAdminUtilsMsgChannel from '@salesforce/messageChannel/CashLogiticsUtilsMessageChannel__c';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import mainTemplate from "./clAdminRps.html";
import {getRecord, getFieldValue, getRecordNotifyChange} from 'lightning/uiRecordApi';
import TOTAL_RPS_RECS_FIELD from '@salesforce/schema/Route_Schedule__c.Total_Processing_Sheets__c'
import TOTAL_METER_READINGS_FIELD from '@salesforce/schema/Route_Schedule__c.Total_Meter_Readings__c'
import TOTAL_ACCOUNTS_FIELD from '@salesforce/schema/Route_Schedule__c.Total_Accounts__c';
import RS_NAME from '@salesforce/schema/Route_Schedule__c.Name';
import COLLECTOR1_FIELD from '@salesforce/schema/Route_Schedule__c.Collector_1__c';
import COLLECTOR2_FIELD from '@salesforce/schema/Route_Schedule__c.User__c';
import ASSIGNED_DRIVER_FIELD from '@salesforce/schema/Route_Schedule__c.Assigned_Driver__c';
import createRpsData from '@salesforce/apex/clRouteProcessingSheetsController.createRpsAndMeters';
import stencil from './clAdminRpsStencil.html';


const  SCHEDULE_MDT_DEV_NAME = 'Scheduler';
const  MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const  RESULT_MSG_TEXT_DISPLAY_TIME = 10000;
const  DEFAULT_REGION = 'Burr Ridge';


const  RS_FIELDS = [
    TOTAL_RPS_RECS_FIELD,TOTAL_ACCOUNTS_FIELD,RS_NAME,TOTAL_METER_READINGS_FIELD,
    COLLECTOR1_FIELD,COLLECTOR2_FIELD,ASSIGNED_DRIVER_FIELD
];
const  MAP_KEY_ROUTES = 'ROUTE_DATA';
const  MAP_KEY_ROUTE = 'ROUTE';


export default class ClAdminRps extends NavigationMixin(LightningElement) {

    _subscription = null;
    _wiredScheduleMdt;
    _hasRendered;
    _isLoading = false;
    _isBatchJobRunning = false;
    _scheduleMdtDevName = SCHEDULE_MDT_DEV_NAME;
    _debugConsole = false;
    _cacheBust = Math.random();
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _routeCollectionDate = this.tomorrowsDateFormatted;
    _routeFillDate = this.tomorrowsDateFormatted;
    _activeTabValue = 'tab_rpscreate';
    _rsRecordSelected;
    _wiredRoutes;
    _wiredRs;
    _hasOverrodeSfdcCss;
    _totalNumberRpsRecords = 0;
    _totalNumberOfAccounts = 0;
    _totalMeterReadings = 0;
    _collector1;
    _collector2;
    _assignedDriver;
    _processingLocation = 'Burr Ridge';
    _routeCycleNumber = 0;
    _activeSubTabValue = '';
    _selectedRouteId;
    _newRouteName = '';
    _isUpdating = false;
    _showRouteLink = true;
    rsName;



    error = {};
    refreshAllAutocompletes;
    @track rsId;
    @track scheduleMdt;
    @track scheduleNextCycle;
    @track scopedMsg = {
        message : null,
        severity : null,
        iconName : 'utility:success',
        iconVariant : null,
        iconCustomSize : 'x-small',
        customClass : 'accel-notification_condense ',
        theme : null,
        dismissible : false,
        reset: function () {
            this.message = null;
            this.severity = null;
            this.iconName = 'utility:success';
            this.iconVariant = null;
            this.iconCustomSize = 'x-small';
            this.customClass = 'accel-notification_condense ';
            this.theme = null;
            this.dismissible = false
        }
    }

    constructor() {
        super();
    }

    render() {
        //return this._isLoading || this._isUpdating ? stencil : mainTemplate;
        return mainTemplate;
    }


    connectedCallback() {
        //  this._isLoading = true;
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            themeOverrider.buildAdminCardOverrideCss(this);
        }
    }

    createRpsAndMeters(recordId) {
        let params = {routeScheduleId: recordId, region: DEFAULT_REGION};
        this._isBatchJobRunning = true;
        createRpsData( params )
            .then(dto => {
                console.log('--> returned rps and meters dto='+JSON.stringify(dto));
                this.scopedMsg.message = dto.message;
                this.scopedMsg.iconName = 'utility:info';
                this.scopedMsg.customClass+= 'accel-notification-info_theme';
            })
            .catch( error => {
                this._isBatchJobRunning = false;
                this._isLoading = false;
                this.error = reduceErrors(error);
                this.showToast('','Problem firing job to create rps data: '+this.error,'error');
                console.error(this.error);
            });
    }

    createRs(nextCycleNumber,routeCollectionDate) {
        let params = {nextCycleNumber: nextCycleNumber, routeCollectionDate: routeCollectionDate};
        createRsData( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                this.scopedMsg.message = dto.message;
                this.scopedMsg.theme = 'success';
                this.scopedMsg.iconVariant = 'inverse';
                // setTimeout(() => { this.scopedMsg.reset()},RESULT_MSG_TEXT_DISPLAY_TIME);
            })
            .catch( error => {
                this._isLoading = false;
                this.error = reduceErrors(error);
                this.showToast('','Problem firing job to create route schedule data: '+this.error,'error');
                console.error(this.error);
            });
    }

    @wire(getRecord, { recordId: '$rsId', fields: RS_FIELDS })
    wiredRecord(wiredData) {
        this._wiredRs = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this._isLoading = false;
        } else if (data) {
            console.log('---> refreshed route schedule data='+JSON.stringify(data));
            this._isLoading = false;
            this._totalNumberRpsRecords = getFieldValue(data,TOTAL_RPS_RECS_FIELD);
            this._totalNumberOfAccounts = getFieldValue(data,TOTAL_ACCOUNTS_FIELD);
            this._totalMeterReadings    = getFieldValue(data,TOTAL_METER_READINGS_FIELD);
            this._collector1            = getFieldValue(data,COLLECTOR1_FIELD);
            this._collector2            = getFieldValue(data,COLLECTOR2_FIELD);
            this._assignedDriver        = getFieldValue(data,ASSIGNED_DRIVER_FIELD);
            this.rsName                = getFieldValue(data,RS_NAME);
        }
    }

    @wire(CurrentPageReference)
    pageRef;

    @wire(MessageContext)
    messageContext;

    @wire(retrieveMdt, { mdtDevName: '$_scheduleMdtDevName', cacheBust : '$_cacheBust' })
    wiredMdt(wiredData) {
        this._wiredScheduleMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            this.showToast('', 'Problem getting custom metadata settings: ' + this.error, 'error');
            console.error(this.error);
        } else if (data) {
            this.scheduleMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
            if (this.scheduleMdt) {
                this.scheduleNextCycle = this.scheduleMdt.Next_Cycle__c;
            }
            console.log('---- schedule mdt=', JSON.parse(JSON.stringify(data)));
        }
    }
    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
    }
    handleBatchJobProcessing(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            if(payload.Publishing_Process_Name__c !== 'clBatchRouteProcessingSheetCreation'
               && payload.Publishing_Process_Name__c !== 'clBatchMeterReadingsCreation') {
                return;
            }
            console.log('clAdminRps payload recieved in handleBatchJobStatusUpdate.. ',JSON.stringify(payload));
            if(payload && payload.Operation_Type__c == 'INSERT') {
                console.log('reset scoped msg');
                this.scopedMsg.reset();
              //  if (payload.severity && payload.severity === 'success') {
                    console.log('payload success');
                    this.scopedMsg.message = payload.Ui_Message__c;
                    this.scopedMsg.iconName = 'utility:info';
                    this.scopedMsg.customClass+= 'accel-notification-info_theme';
                //}
            }
        }
    }
    handleBatchJobComplete(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            if(payload.Publishing_Process_Name__c !== 'clBatchRouteProcessingSheetCreation'
                && payload.Publishing_Process_Name__c !== 'clBatchMeterReadingsCreation') {
                return;
            }
            this._isBatchJobRunning = false;
            this.scopedMsg.reset();
            console.log('clAdminRps payload recieved in handleBatchJobStatusComplete.. ',JSON.stringify(payload));
            refreshApex(this._wiredRs);
            this.showToast('',payload.Ui_Message__c,'success');
            this.refreshAllAutocompletes = true;
            let payload2 = {success:true, action:'refresh'};
            publish(this.messageContext,clAdminUtilsMsgChannel,payload2);
        }
    }
    handleMessage(message) {
        console.log('message recieved:'+JSON.stringify(message));
        this._cacheBust = Math.random();
        refreshApex(this._wiredScheduleMdt);
    }
    handleRpsCreateClick() {
        this._isBatchJobRunning = true;
        this.createRpsAndMeters(this.rsId);
    }
    handleRsCreateClick() {
        this._isBatchJobRunning = true;
        this.createRs(this.scheduleNextCycle, this._routeCollectionDate);
    }
    handleScheduleSelected(evt) {
        if(evt.detail && evt.detail.value) {
            this._isLoading = true;
            //alert('evt detail='+JSON.stringify(evt.detail.value));
            this.rsId = evt.detail.value.id;
            this.rsName = evt.detail.value.primaryDisplayValue;
        }
    }
    handleOuterContainerClick(evt) {
        fireEvent(this.pageRef, 'eventOuterContainerClicked', 'outercontainerclick');
    }
    handleRouteCollectionDateChange(evt) {
        this._showRouteLink = false;
        let collectionDate = evt.target.value;
        this._routeCollectionDate = collectionDate;
    }

    checkNoCollectorInfo() {
        return !this._collector1 && !this._collector2 && !this._assignedDriver;
    }
    get showExistingRpsInfo() {
        return this.rpsId && !this.showRpsCreateButton && !this.showNoAccountsMessage && this._totalNumberRpsRecords > 0;
    }
    get showNoCollectorInfo() {
        return true;
        // let showIt = false;
        // showIt = this._totalNumberRpsRecords < 1 && this._totalNumberOfAccounts > 0;
        // if(showIt) {
        //     showIt = this.checkNoCollectorInfo();
        // }
        // return showIt;
    }
    get additionalWhereCriteria() {
        let whereCriteria = ' Total_Processing_Sheets__c < 1';
        return whereCriteria;
    }
    get cardTitleStyle() {
        return themeOverrider.getCardTitleStyle(this);
    }
    get showRouteScheduleOptions() {
        return true;
    }
    get tomorrowsDateFormatted() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate() + 1);
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        let yyyyMmDd = rightNow.toISOString().slice(0,10);
        return yyyyMmDd;
    }
    get showRpsDeleteButton() {
        return this._totalNumberRpsRecords > 0;
    }

    get showMetersDeleteButton() {
        return this._totalMeterReadings > 0;
    }

    get showDeleteTab() {
        return false;
        //return this.showMetersDeleteButton || this.showRpsDeleteButton;
    }
    get showRouteSchCreateButton() {
        return !this._isBatchJobRunning && this._activeTabValue !== 'tab_rpscreate';
    }
    get showNoAccountsMessage() {
        return this.rsId && !this._isLoading && (!this._totalNumberOfAccounts || this._totalNumberOfAccounts < 1);
    }
    get showScopedMsg() {
        return this.scopedMsg && this.scopedMsg.message && this.scopedMsg.message != '';
    }

    get showStencil() {
        return this._isBatchJobRunning || this._isUpdating;
    }

    get showRpsCreateButton() {
        return !this._isBatchJobRunning && this._totalNumberRpsRecords < 1 && this._totalNumberOfAccounts > 0;
    }
    handleRsNavToRecordView(evt) {
        evt.preventDefault();
        this.navigateToRecordView('Route_Schedule__c',this.rsId);
    }
    navigateToRecordView(sObjectApiName,recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: sObjectApiName,
                recordId: recordId,
                actionName: 'view'
            }
        });
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

    subscribeToMessageChannel() {
        if (!this._subscription) {
            this._subscription = subscribe(
                this.messageContext,
                clAdminUtilsMsgChannel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this._subscription);
        this._subscription = null;
    }
}