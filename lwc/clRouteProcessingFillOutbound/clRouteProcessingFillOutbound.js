import {api, LightningElement, track, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import Id from '@salesforce/user/Id';
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from "c/accelUtilsSvc";
import Logger from "c/logger";
// import retrieveRpsData from '@salesforce/apex/clRouteProcessingFillOutbound.retrieveRpsWrapper';
import retrieveRpsDataNoCache from '@salesforce/apex/clRouteProcessingFillOutbound.retrieveRpsWrapperNoCache';
import updateRpsStatus from '@salesforce/apex/clRouteProcessingFillOutbound.updateRpsStatus';
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import {reduceErrors} from "c/ldsUtils";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import mainTemplate from './clRouteProcessingFillOutbound.html';
import stencil from './clRouteProcessingFillOutbountStencil.html';
import RPS_ID_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Id';
import RPS_PROCESSING_STATUS_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Processing_Status__c';
import RPS_PROCESSING_STATUS_CHANGED_DATE_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Processing_Status_Changed_Date__c';
import RPS_PROCESSING_STATUS_CHANGED_BY_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Processing_Status_Changed_By__c';

import lblCardTitleCollection from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Card_Title_Collection'
import lblCardTitleFill from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Card_Title_Fill'
import lblCardTitleRedemption from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Card_Title_Redemption'
import lblButtonFillComplete from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Action_Button_Fill_Completed';
import lblFormCardTitle from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Form_Title';

const MAP_KEY_RPS_DATA = 'RPS_WRAPPER_DATA';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const RPS_PROCESSING_STATUS_COMPLETED_FILL = 'COMPLETED FILL';
const PAGE_PROCESSING_FILL_COLLECTIONS = 'processing-fill-collections';
const MDT_DEV_NAME = 'Route_Processing_Fill';
const GLOBAL_CONSTANTS = getConstants();
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class ClRouteProcessingFillOutbound extends NavigationMixin(LightningElement) {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    @track emptyBodyText = 'No data found';
    @track urlStateParameters;
    @track currentPageReference;
    @track rpsId;
    @track rsId;
    @track rsGroupDate;
    @track rpsWrapper;
    @track pageMdt;

    labels = {lblCardTitleCollection,lblCardTitleFill,lblCardTitleRedemption,lblButtonFillComplete,lblFormCardTitle};
    _wiredPageMdt;
    _wiredRpsDto;
    _accelUtils = new AccelUtilsSvc(false);
    _currentPageReference;
    _isLoading = true;
    _pageMdtDevName = MDT_DEV_NAME;
    _cacheBust = Math.random();
    _isRunningUpdate = false;
    _userId = Id;
    _invalidParameters = false;
    _logger;
    _debugConsole;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingFillOutBound',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {

    }

    render() {
        return !this._isLoading ? mainTemplate : stencil;
    }


    @wire(retrieveRpsDataNoCache,{rpsId : '$rpsId',cacheBust: '$_cacheBust'})
    retrieveRpsWraps(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const {data, error} = this._wiredRpsDto;
        if(data) {
            this.log(DEBUG,'---> rps dto',data.values);
            if(data.isSuccess) {
                this.rpsWrapper = this._accelUtils.getMapValue(MAP_KEY_RPS_DATA,data.values);
                this.rsId = this.rpsWrapper.routeScheduleId;
            } else {
                this.log(WARN,'---> rps dto -- could not find rps data');
            }
            this._isLoading = false;
        } else if (error) {
            this._isLoading = false;
            this.log(ERROR,'--> error retriving rps dto',error);
            this.error = reduceErrors(error);
            this.showToast('', 'Problem retrieving rps wrapper data: ' + this.error, 'error');
        }
    }

    modifyRpsProcessingStatus() {
        let changeDate = new Date();
        let rpsRecord = {
            [RPS_ID_FIELD.fieldApiName] : this.rpsId,
            [RPS_PROCESSING_STATUS_FIELD.fieldApiName] : RPS_PROCESSING_STATUS_COMPLETED_FILL,
            [RPS_PROCESSING_STATUS_CHANGED_BY_FIELD.fieldApiName] : this._userId,
            [RPS_PROCESSING_STATUS_CHANGED_DATE_FIELD.fieldApiName] : changeDate
        };
        this.updRpsStatus(rpsRecord);
    }

    updRpsStatus(rps) {

        let params = { rps: rps };
        this.log(DEBUG,'---> calling updateRpsStatus with params',params);
        this._isRunningUpdate = true;

        updateRpsStatus( params )
            .then(dto => {
                this._isRunningUpdate = false;
                if (dto.isSuccess) {
                    this.rpsWrapper = this._accelUtils.getMapValue(MAP_KEY_RPS_DATA,dto.values);
                    this.showToast('',dto.message,'success');
                } else {
                    this.log(ERROR,'---> error on update',dto);
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                this._isRunningUpdate = false;
                this.error = reduceErrors(error);
                this.showToast('','Problem updating rps status: '+this.error,'error');
                this.log(ERROR,'--> sys error on update',error);
            });
    }

    handleSubmitFillComplete(evt) {
       this.modifyRpsProcessingStatus()
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
            if(!this.urlStateParameters || !this.urlStateParameters.rpsId) {
                this._invalidParameters = true;
                this._isLoading = false;
                this.rpsWrapper = null;
                return;
            }
            if (this.urlStateParameters.rpsId) {
                if(this.urlStateParameters.rpsId != null) {
                    this._invalidParameters = false;
                    this.rpsId = this.urlStateParameters.rpsId;
                }
            }
            if (this.urlStateParameters.rsGroupDate) {
                if(this.urlStateParameters.rsGroupDate != null) {
                    this.rsGroupDate = this.urlStateParameters.rsGroupDate;
                }
            }
        }
    }

    handleBackClicked(evt) {
        this.navigate(PAGE_PROCESSING_FILL_COLLECTIONS,this.rsId);
    }

    get showBackButton() {
        return this.pageMdt && this.pageMdt.Show_Back_Button__c;
    }

    get isAlreadyCompleted() {
        return this.rpsWrapper && this.rpsWrapper.rps.Processing_Status__c === RPS_PROCESSING_STATUS_COMPLETED_FILL;
    }
    get showFillButton() {
        return !this._isRunningUpdate && !this.isAlreadyCompleted;
    }
    get completedMsg() {
        let msg;
        if(this.isAlreadyCompleted) {
            let rps = this.rpsWrapper.rps;
            let name = rps.Processing_Status_Changed_By__r ? rps.Processing_Status_Changed_By__r.Name : '';
            let changedDate;
            if(rps.Processing_Status_Changed_Date__c) {
                changedDate = new Date(rps.Processing_Status_Changed_Date__c).toLocaleString();
            }
            msg = 'Marked '+rps.Processing_Status__c + ' by ' + name + ' on ' + changedDate + '.';
        }
        return msg;
    }

    get fillDateFormatted() {
        let formattedDate = this.labels.lblCardTitleFill+': ';
        if(this.rpsWrapper && this.rpsWrapper.fillDateFormatted) {
            formattedDate += this.rpsWrapper.fillDateFormatted;
        }
        return formattedDate;
    }

    get collectionDateFormatted() {
        let formattedDate = this.labels.lblCardTitleCollection+': ';
        if(this.rpsWrapper && this.rpsWrapper.collectionDateFormatted) {
            formattedDate += this.rpsWrapper.collectionDateFormatted;
        }
        return formattedDate;
    }

    get cardThirdSubTitle() {
        let value;
        if(this.rpsWrapper && this.rpsWrapper.redemptionType) {
            value = this.labels.lblCardTitleRedemption+': '+this.rpsWrapper.redemptionType;
        }
        return value;
    }

    get showNoData() {
        !this._isLoading && !this.rpsWrapper;
    }

    get disableAddressClick() {
        let disableIt = true;
        if(this.pageMdt && this.pageMdt.Allow_Address_Click_to_Google_Maps__c) {
            disableIt = false;
        }
        return disableIt;
    }

    /**
     *
     * @param pageName
     * @todo the nav mix in is buggy with communities and caching.
     */
    navigate(pageName,rsId) {
        try {
            this.log(DEBUG,'attempting to nav to pageName:'+pageName);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {
                    rsId: rsId,
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