import {LightningElement, api, wire, track} from 'lwc';
import stencil from './clAdminRouteCycleNumberUpdateStencil.html';
import mainTemplate from './clAdminRouteCycleNumberUpdate.html';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import updateNextCycleNumber from '@salesforce/apex/clRouteProcessingSheetsController.updateNextCycleNumber';
import retrieveMdtNoCache   from '@salesforce/apex/clRouteProcessingSheetsController.retrieveMdtNoCache';
import {refreshApex} from "@salesforce/apex";
import {reduceErrors} from 'c/ldsUtils';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import clUtilsMsgChannel from '@salesforce/messageChannel/CashLogiticsUtilsMessageChannel__c';
import { publish, MessageContext } from 'lightning/messageService';
import {themeOverrider} from 'c/clAdminOnlyCardTheme';

const  SCHEDULE_MDT_DEV_NAME = 'Scheduler';
const  MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const  RESULT_MSG_TEXT_DISPLAY_TIME = 10000;

export default class ClAdminRouteCycleNumberUpdate extends LightningElement {

    @track scheduleMdt;
    @track scheduleNextCycle;
    @track cycleNumberFieldLabel = 'Current Fill Cycle #';
    @track scopedMsg = {
        message : null,
        severity : null,
        iconName : 'utility:success',
        iconVariant : null,
        iconCustomSize : 'x-small',
        customClass : 'accel-notification_small ',
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

    _wiredScheduleMdt;
    _isLoading = false;
    _isUpdating = false;
    _isBatchJobRunning = false;
    _cacheBust = Math.random();
    _hasRendered = false;
    _showRouteLink = false;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _scheduleMdtDevName = SCHEDULE_MDT_DEV_NAME;
    error = {};

    constructor() {
        super();
    }

    render() {
        return this._isLoading ?  stencil : mainTemplate;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            themeOverrider.buildAdminCardOverrideCss(this);
        }
    }
    @wire(MessageContext)
    messageContext;

    @wire(retrieveMdtNoCache, { mdtDevName: '$_scheduleMdtDevName', cacheBust : '$_cacheBust' })
    wiredMdt(wiredData) {
        this._wiredScheduleMdt = wiredData;
        console.log('in wire');
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

    updateCycleNumber( nextCycleNumber) {
        let params = {nextCycleNumber: nextCycleNumber};
        console.log('params='+JSON.stringify(params));
        this._isUpdating = true;
        this.scopedMsg.message = 'Running update...';
        this.scopedMsg.iconName = 'utility:info';
        this.scopedMsg.customClass+= 'accel-notification-info_theme';
        updateNextCycleNumber( params )
            .then(dto => {
                this.scopedMsg.reset();
                console.log('--> returned dto='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    this.cycleNumberFieldLabel = 'Current Cycle Number';
                    this.scopedMsg.message = dto.message;
                    if(dto.severity == 'success') {
                        this.scopedMsg.severity = dto.severity;
                    } else if (dto.severity == 'info') {
                        this.scopedMsg.iconName = 'utility:info';
                        this.scopedMsg.customClass+= 'accel-notification-info_theme';
                    }
                } else {
                }
            })
            .catch( error => {
                this._isUpdating = false;
                this.error = reduceErrors(error);
                this._isLoading = false;
                this.showToast('','Problem firing job to update next cycle number: '+this.error,'error');
                console.error(this.error);
            });
    }

    handleBatchJobCompleted(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            //alert(JSON.stringify(payload));
            if(payload && payload.Operation_Type__c == 'MDT_UPDATE') {
                this.scopedMsg.reset();
                if (payload.severity && payload.severity === 'success') {
                    let payload2 = {success : true,action:'refresh'};
                    publish(this.messageContext, clUtilsMsgChannel, payload2);
                    // this.scopedMsg.message = payload.Ui_Message__c;
                    // this.scopedMsg.theme = 'success';
                    // this.scopedMsg.iconVariant = 'inverse';
                    this.showToast('',payload.Ui_Message__c,'success');
                    this._cacheBust = Math.random();
                    refreshApex(this._wiredScheduleMdt);
                    // setTimeout(() => {
                    //     this.scopedMsg.reset()
                    // }, RESULT_MSG_TEXT_DISPLAY_TIME);
                }
            }
        }
        this._isBatchJobRunning = false;
        this._isUpdating = false;
    }

    handleRouteCollectionDateChange(evt) {
        this._showRouteLink = false;
        let collectionDate = evt.target.value;
        this._routeCollectionDate = collectionDate;
    }

    handleRouteCycleNumberChange(evt) {
        this._showRouteLink = false;
        this._routeCycleNumber = evt.target.value;
    }

    handleNewRouteNameChange(evt) {
        this._showRouteLink = false;
        this._newRouteName = evt.target.value;
    }

    handleScheduleMdtUpdateClick(evt) {
        this._isBatchJobRunning = true;
        this.updateCycleNumber(this.scheduleNextCycle);
    }
    handleScheduleNumberChange(evt) {
        this._showRouteLink = false;
        this.scheduleNextCycle = evt.target.value;
        if(!this.scheduleNextCycle) {
            this.cycleNumberFieldLabel = 'Current Fill Cycle #';
        } else {
            this.cycleNumberFieldLabel = 'Fill Cycle # to Update to';
        }
    }
    handleAlertContainerDismissed(evt) {
        this.scopedMsg.reset();
    }

    get showCycleNumberForm() {
        return this.scheduleMdt && !this._isBatchJobRunning;
    }
    get showScopedMsg() {
        return this.scopedMsg && this.scopedMsg.message && this.scopedMsg.message != '';
    }
    get cardTitleStyle() {
        return themeOverrider.getCardTitleStyle(this);
    }
    get showCycleUpdateButton() {
        return !this._isBatchJobRunning && !this._isUpdating;
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