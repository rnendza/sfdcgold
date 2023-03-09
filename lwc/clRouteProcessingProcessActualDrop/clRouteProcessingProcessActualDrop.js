import {LightningElement, track, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from "lightning/navigation";
import Id from '@salesforce/user/Id';
import AccelUtilsSvc from "c/accelUtilsSvc";
import retrieveRpsData from '@salesforce/apex/clRouteProcessingFillOutbound.retrieveRpsWrapper';
import updateRpsStatus from '@salesforce/apex/clRouteProcessingFillOutbound.updateRpsStatus';
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';

import {reduceErrors} from "c/ldsUtils";
import { getConstants } from 'c/clConstantUtil';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import mainTemplate from './clRouteProcessingProcessActualDrop.html';
import stencil from './clkRouteProcessingFillActualDropStencil.html';
import RPS_ID_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Id';
import RPS_PROCESSING_STATUS_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Processing_Status__c';
import RPS_PROCESSING_STATUS_CHANGED_DATE_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Processing_Status_Changed_Date__c';
import RPS_PROCESSING_STATUS_CHANGED_BY_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Processing_Status_Changed_By__c';
import USER_ID_FIELD from '@salesforce/schema/User.Id';

import lblCardTitleCollection from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Card_Title_Collection'
import lblCardTitleFill from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Card_Title_Fill'
import lblCardTitleRedemption from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Card_Title_Redemption'
import lblButtonFillComplete from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Action_Button_Fill_Completed';
import lblFormCardTitle from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Form_Title';

const MAP_KEY_RPS_DATA = 'RPS_WRAPPER_DATA';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const MAP_KEY_USER_RECORD = 'USER_RECORD';
const RPS_PROCESSING_STATUS_COMPLETED_PROCESSING = 'COMPLETED PROCESSING';
const RECORD_TYPE_VGT = 'VGT';
const RECORD_TYPE_REDEMPTION = 'Redemption';

const PAGE_PROCESSING_PROCESS_COLLECTIONS = 'processing-process-collections';

const MDT_DEV_NAME = 'Route_Processing_Fill';
const GLOBAL_CONSTANTS = getConstants();

export default class ClRouteProcessingProcessActualDrop extends NavigationMixin(LightningElement) {

    @track emptyBodyText = 'No rps info found.'
    @track urlStateParameters;
    @track currentPageReference;
    @track rpsId;
    @track rsId;
    @track rsGroupDate;
    @track rpsWrapper;
    @track pageMdt;
    @track user;

    labels = {lblCardTitleCollection,lblCardTitleFill,lblCardTitleRedemption,lblButtonFillComplete,lblFormCardTitle};
    _wiredPageMdt;
    _wiredRpsDto;
    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _currentPageReference;
    _isLoading = true;
    _pageMdtDevName = MDT_DEV_NAME;
    _isRunningUpdate = false;
    _isMachineTypeSwitch;
    _machineTypeSelected;
    _userId = Id;
    _view = 'Redemption';
    _invalidParamters = false;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingProcessActualDrop',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }
    connectedCallback() {
    }

    render() {
        return !this._isLoading ? mainTemplate : stencil;
    }

    @wire(retrieveRpsData,{rpsId : '$rpsId'})
    retrieveRpsWraps(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const {data, error} = this._wiredRpsDto;
        if(data) {
            if(data.isSuccess) {
                this.rpsWrapper = this._accelUtils.getMapValue(MAP_KEY_RPS_DATA,data.values);
                this.rsId = this.rpsWrapper.routeScheduleId;
                // console.log('--> rps wraps',JSON.stringify(this.rpsWrapper));
            } else {
                console.error(' could not find rps data');
            }
            this._isLoading = false;
        } else if (error) {
            this._isLoading = false;
            console.error(JSON.stringify(error));
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
        console.log('--> calling updateRpsStatus with params:' + JSON.stringify(params));
        this._isRunningUpdate = true;

        updateRpsStatus( params )
            .then(dto => {
                // console.log('--> returned dto='+JSON.stringify(dto));
                this._isRunningUpdate = false;
                if (dto.isSuccess) {
                    this.rpsWrapper = this._accelUtils.getMapValue(MAP_KEY_RPS_DATA,dto.values);
                    // console.log('---> current rpsWrap='+JSON.stringify(this.rpsWrapper));
                    this.showToast('',dto.message,'success');
                } else {
                    console.log(' error in update' + JSON.stringify(dto));
                    console.log(dto.technicalMsg);
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                this._isRunningUpdate = false;
                this.error = reduceErrors(error);
                this.showToast('','Problem updating rps status: '+this.error,'error');
                console.error(this.error);
            });
    }

    handleSubmitFillComplete(evt) {
        this.modifyRpsProcessingStatus()
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

    handleMachineTypeSelected(evt) {

        let typeSelected = evt.detail.machineType;
        this._machineTypeSelected = typeSelected;
        this._isMachineTypeSwitch = true;
        if (typeSelected != RECORD_TYPE_VGT) {

        } else {

            this._isMachineTypeSwitch = false;
        }
    }
    get showMenuActions() {
        console.log('--> showMenuActions');
        return !this._isLoading && this._machineTypeSelected && this._machineTypeSelected == RECORD_TYPE_VGT;
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

    setParametersBasedOnUrl() {
        if(!this._disconnectCb) {
            if(!this.urlStateParameters || !this.urlStateParameters.rpsId) {
                this._invalidParamters = true;
                this._isLoading = false;
                return;
            }
            if (this.urlStateParameters.rpsId) {
                if(this.urlStateParameters.rpsId != null) {
                    this._invalidParamters = false;
                    this.rpsId = this.urlStateParameters.rpsId;
                }
            }
            if (this.urlStateParameters.rsGroupDate) {
                if(this.urlStateParameters.rsGroupDate != null) {
                    this._invalidParamters = false;
                    this.rsGroupDate = this.urlStateParameters.rsGroupDate;
                }
            }
        }
    }

    handleBackClicked(evt) {
        this.navigate(PAGE_PROCESSING_PROCESS_COLLECTIONS,this.rsId);
    }

    handleSubmitProcessingComplete(evt) {
        this.showToast('','@todo.. handle this','info');
    }
    handleMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        this.showToast('','todo handle click','info');

    }

    get showVgts() {
        let showIt =  !this._isLoading && this._machineTypeSelected === RECORD_TYPE_VGT && !this._isMachineTypeSwitch;
        return showIt;
    }

    get showRts() {
        let showIt = !this.isLoading && this._machineTypeSelected === RECORD_TYPE_REDEMPTION;
        return showIt;
    }

    get showProcessingCompleteButton() {
        return !this.isAlreadyCompleted;
    }

    get showBackButton() {
        return this.pageMdt && this.pageMdt.Show_Back_Button__c;
    }

    get isAlreadyCompleted() {
        return this.rpsWrapper && this.rpsWrapper.rps.Processing_Process_Status__c == RPS_PROCESSING_STATUS_COMPLETED_PROCESSING;
    }
    get showFillButton() {
        return !this._isRunningUpdate && !this.isAlreadyCompleted;
    }
    get completedMsg() {
        let msg;
        if(this.isAlreadyCompleted) {
            let rps = this.rpsWrapper.rps;
            let name = rps.Processing_Process_Changed_By__r ? rps.Processing_Process_Changed_By__r.Name : '';
            let changedDate;
            if(rps.Processing_Process_Changed_Date__c) {
                changedDate = new Date(rps.Processing_Process_Changed_Date__c).toLocaleString();
            }
            msg = 'Marked '+rps.Processing_Process_Status__c + ' by ' + name + ' on ' + changedDate + '.';
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
    get cardFourthSubTitle() {
        let value;
        if(this.rpsWrapper && this.rpsWrapper.replenishmentType){
            value = this.rpsWrapper.replenishmentType;
        }
        return value;
    }
    get showNoData() {
        let ret = !this._isLoading && (!this.rpsWrapper || this._invalidParamters);
        return ret;
    }

    get disableAddressClick() {
        let disableIt = true;
        if(this.pageMdt && this.pageMdt.Allow_Address_Click_to_Google_Maps__c) {
            disableIt = false;
        }
        return disableIt;
    }
    get options() {
        let options;
        // if(this._machineTypeSelected == RECORD_TYPE_VGT) {
        //     options = [
        //         {
        //             id: 'collapseall',
        //             label: 'Collapse all readings',
        //             value: 'collapseall',
        //         },
        //         {
        //             id: 'expandall',
        //             label: 'Expand all readings',
        //             value: 'expandall',
        //         },
        //     ];
        // }
        return options;
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
                state: {rsId: rsId,rsGroupDate : this.rsGroupDate}
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
}