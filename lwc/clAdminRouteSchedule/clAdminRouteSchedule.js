import {LightningElement, track, wire} from 'lwc';
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

const  SCHEDULE_MDT_DEV_NAME = 'Scheduler';
const  MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const  RESULT_MSG_TEXT_DISPLAY_TIME = 7500;

export default class ClAdminRouteSchedule extends NavigationMixin(LightningElement) {

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
    _routeFillDate = this.todaysDateFormatted;
    _activeTabValue = 'tab_schcreate';
    _rsRecordSelected;
    error = {};

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
    createRs(nextCycleNumber,routeCollectionDate,routeFillDate) {
        let params = {nextCycleNumber: nextCycleNumber, routeCollectionDate: routeCollectionDate, routeFillDate : routeFillDate};
        createRsData( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                this.scopedMsg.message = dto.message;
                this.scopedMsg.iconName = 'utility:info';
                this.scopedMsg.customClass+= 'accel-notification-info_theme';
               // setTimeout(() => { this.scopedMsg.reset()},RESULT_MSG_TEXT_DISPLAY_TIME);
            })
            .catch( error => {
                this._isLoading = false;
                this.error = reduceErrors(error);
                this.showToast('','Problem firing job to create route schedule data: '+this.error,'error');
                console.error(this.error);
            });
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
    handleBatchJobStatusProcessing(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            if(payload.Publishing_Process_Name__c !== 'clBatchRouteScheduleCreation') {
                return;
            }
            console.log('payload recieved.. ',JSON.stringify(payload));
            if(payload && payload.Operation_Type__c == 'INSERT') {
                this.scopedMsg.reset();
                if (payload.severity && payload.severity === 'success') {
                    this.scopedMsg.message = payload.Ui_Message__c;
                    // this.scopedMsg.theme = 'success';
                    // this.scopedMsg.iconVariant = 'inverse';
                    this.scopedMsg.iconName = 'utility:info';
                    this.scopedMsg.customClass+= 'accel-notification-info_theme';
                    this._isBatchJobRunning = false;
                }
            }
        }
    }

    handleBatchJobStatusComplete(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            console.log('paylod recieved.. ',JSON.stringify(payload));
            if(payload.Publishing_Process_Name__c !== 'clBatchRouteScheduleCreation') {
                return;
            }
            if(payload && payload.Operation_Type__c == 'INSERT') {
                //this.scopedMsg.reset();
                setTimeout(() => {this.scopedMsg.reset()}, RESULT_MSG_TEXT_DISPLAY_TIME);
                if (payload.severity && payload.severity === 'success') {
                    this.showToast('',payload.Ui_Message__c,'success');
                    this._isBatchJobRunning = false;
                    // this.scopedMsg.message = payload.Ui_Message__c;
                    // // this.scopedMsg.theme = 'success';
                    // // this.scopedMsg.iconVariant = 'inverse';
                    // this.scopedMsg.iconName = 'utility:info';
                    // this.scopedMsg.customClass+= 'accel-notification-info_theme';
                    // this._isBatchJobRunning = false;
                    let payload2 = {success:true, action:'refresh'};
                    publish(this.messageContext,clAdminUtilsMsgChannel,payload2);
                }
            }
        }
    }  
    handleMessage(message) {
        console.log('message recieved:'+JSON.stringify(message));
        this._cacheBust = Math.random();
        refreshApex(this._wiredScheduleMdt);
    }

    handleRsCreateClick() {
        this._isBatchJobRunning = true;
        this.createRs(this.scheduleNextCycle, this._routeCollectionDate,this._routeFillDate);
    }
    handleScheduleSelected(evt) {
        if(evt.detail && evt.detail.rsRecord) {
            this._rsRecordSelected = evt.detail._rsRecordSelected;
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
    handleRouteFillDateChange(evt) {
        this._showRouteLink = false;
        let fillDate = evt.target.value;
        this._routeFillDate = fillDate;
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
    get todaysDateFormatted() {
        let rightNow = new Date();
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        let yyyyMmDd = rightNow.toISOString().slice(0,10);
        return yyyyMmDd;
    }
    get showRouteSchCreateButton() {
        return !this._isBatchJobRunning && this._activeTabValue !== 'tab_rpscreate';
    }
    get showScopedMsg() {
        return this.scopedMsg && this.scopedMsg.message && this.scopedMsg.message != '';
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