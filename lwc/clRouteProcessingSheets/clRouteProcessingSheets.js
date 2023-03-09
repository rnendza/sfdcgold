import {LightningElement, track, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {reduceErrors} from 'c/ldsUtils';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {refreshApex} from "@salesforce/apex";
import {loadScript, loadStyle} from "lightning/platformResourceLoader";

import Id from '@salesforce/user/Id';
import { getConstants } from 'c/clConstantUtil';
import retrieveRouteProcessingSheets   from '@salesforce/apex/clRouteProcessingSheetsController.retrieveRouteProcessingSheets';
import retrieveRouteScheduleData   from '@salesforce/apex/clRouteProcessingSheetsController.retrieveRouteScheduleData';
import retrieveUserDetails from '@salesforce/apex/clUserController.retrieveUserDetails';
import retrieveMdt from '@salesforce/apex/clRouteProcessingSheetsController.retrieveMdt';
import doRouteScheduleStart  from '@salesforce/apex/clRouteProcessingSheetsController.doRouteScheduleStart';
import doRouteScheduleEnd  from '@salesforce/apex/clRouteProcessingSheetsController.doRouteScheduleEnd';
import doRouteProcessingSheetStatusUpdate from '@salesforce/apex/clRouteProcessingSheetsController.doRouteProcessingSheetStatusUpdate';
import doUpdateStopNumbers from '@salesforce/apex/clRouteProcessingSheetsController.doUpdateStopNumbers';
import doSendRouteEmail from '@salesforce/apex/clRouteProcessingSheetsController.doSendRouteEndEmail';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import { themeOverrider} from "./clRouteProcessingSheetsThemeOverrides";
// import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_stripped_down';
import SORTABLE  from '@salesforce/resourceUrl/sortable';
import lblCardTitle from '@salesforce/label/c.CL_Collector_Home_Card_Title';
import lblMissingVehicleInfo from '@salesforce/label/c.CL_Collector_Home_Missing_Vehicle_Info';
import lblRtModel from '@salesforce/label/c.CL_Collector_Label_RT_Model';
import lblMissingVehicleEnding from '@salesforce/label/c.CL_Collector_Home_Missing_Vehicle_Ending';
import lblSendRouteEndEmailLinkDesc from '@salesforce/label/c.CL_Collector_Home_Action_Send_Email_Link_Desc';
import lblSendRouteEndEmailDialogButtonConfirm from '@salesforce/label/c.CL_Collector_Home_Action_Send_Email_Dialog_Button_Confirm';
import lblSendRouteEndEmailDialogButtonCancel from '@salesforce/label/c.CL_Collector_Home_Action_Send_Email_Dialog_Button_Cancel';
import lblSendRouteEndEmailDialogIcon from '@salesforce/label/c.CL_Collector_Home_Action_Send_Email_Dialog_Icon';
import lblSendRouteEndEmailDialogTitle from '@salesforce/label/c.CL_Collector_Home_Action_Send_Email_Dialog_Title';
import lblSendRouteEndEmailDialogMsg from '@salesforce/label/c.CL_Collector_Home_Action_Send_Email_Dialog_Msg';



import mainTemplate from './clRouteProcessingSheets.html';
import stencil from './clRouteProcessingSheetsStencil.html';

const GLOBAL_CONSTANTS = getConstants();

const MAP_KEY_RPS_DATA = 'RPS_WRAPS';
const MAP_KEY_ROUTE_DATA = 'ROUTE_DATA';
const MAP_KEY_ROUTE_SCHEDULE_DATA = 'ROUTE_SCHEDULE_DATA';
const MAP_KEY_ROUTE_SCHEDULE_ID = 'ROUTE_SCHEDULE_ID';
const METERS_PAGE_NAME = 'meters';
const PAGE_METER_READINGS = 'meterreadings';
const PAGE_ROUTE_SELECTION = 'routeselection';
const COLLECTION_COMPLETED_STATUS = 'COMPLETED COLLECTION';

const FORM_CLASS = 'accel-theme_shade';
const RECORD_TYPE_VGT = 'VGT';
const RECORD_TYPE_REDEMPTION = 'Redemption';
const MDT_DEV_NAME = 'Route_Processing_Sheet';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const CONSOLE_GREEN_MSG = 'color:green; font-weight:bold';
const PLATFORM_EVENT_CHANNEL = 'Route_Schedule_Change_PE__e';
const PE_PUBLISHING_PROCESS_NAME = 'clFillSvc';
const REORDER_DOWN = 'down';
const REORDER_UP = 'up';

export default class ClRouteProcessingSheets extends NavigationMixin(LightningElement)  {

    labels = {
        lblCardTitle, lblMissingVehicleInfo,lblMissingVehicleEnding, lblSendRouteEndEmailLinkDesc,
        lblSendRouteEndEmailDialogIcon,lblSendRouteEndEmailDialogButtonConfirm,lblSendRouteEndEmailDialogMsg,
        lblSendRouteEndEmailDialogTitle,lblSendRouteEndEmailDialogButtonCancel,lblRtModel
    };

    //Variables to control modal window
    @track showModal = false;
    @track showNegativeButton;
    @track showPositiveButton = true;
    @track positiveButtonLabel = 'Close';

    closeModal() {
        this.showModal = false;
    }

    showModalPopup() {
        this.showModal = true;
    }

    @api rpsCardTitle = this.labels.lblCardTitle;
    //@api allowDragDrop;

    @track routeId;
    @track routeScheduleId;
    @track rpsData;
    @track originalRpsData;
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
    @track rpsMdt;
    @track sendRouteEndEmailDialogVisible;

    currentPageReference = null;
    urlStateParameters = null;

    _reorderStopsClicked = false;
    _reorderStopsCancelClicked = false;
    _cacheBust;
    _allowDragDrop = false;
    _wiredRpsDto;
    _wiredRouteScheduleDto;
    _wiredRpsMdt;
    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _lastMouseOverListId = null;
    _listNodes = [];
    _userId = Id;
    _doneSearching = false;
    _isProcessing = true;
    _allDataLoaded = false;
    _collectionDate = new Date(new Date().setHours(0,0,0,0));
    _changedTemplateSize = false;
    _openVehicleForm = false;
    _prevTemplateSize = 'SMALL';
    _selectedRpsId;
    _rpsMdtDevName = MDT_DEV_NAME;
    _sortable;
    _self = this;
    _dndOnEndMsg;
    _hasOverrodeSfdcCss;

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingSheets',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        //this.showToast('Developer Note','Reorder stops DEV In Progress','info');
    }

    get showCardActions() {
        return this.cardActions && this.cardActions.length > 0;
    }

    /**
     * Builds Card actions (ie menu option in dropdown in top right!
     * @returns {*[]}  an Array of actions for the menu drop down.
     */
    get cardActions() {
        let actions = [];
        if(this.showReOrderStopsButton && this.allowDnd) {
            let option = {id: 'reorderstops', label:'Reorder Stops',value:'reorderstops', prefixIconName: 'utility:sort'};
            actions.push(option);
        }
        if(this.showSendEndRouteEmail) {
            let option = {
                id: 'sendendrouteemail', label:this.labels.lblSendRouteEndEmailLinkDesc,
                value:'sendendrouteemail', prefixIconName: 'utility:email'
            };
            actions.push(option);
        }
        return actions;
    }

    render() {
        return this._allDataLoaded ? mainTemplate : stencil;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            this.loadFontAwesome();
        }
        if(!this._hasOverrodeSfdcCss) {
            this.buildSfdcCoreOverrideCss();
        }
    }

    /**
     * Get full user details (as opposed to just userId, in case it's needed)
     * @param error
     * @param data
     */
    @wire(retrieveUserDetails, { userId: '$_userId' })
    wiredUserDetails({ error, data }) {
        if (data) {
            this.runningUser = data;
        } else if (error) {
            this._doneSearching = true;
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving user information: '+this.error,'error');
        }
    }
    /**
     * Retrieve all route processing sheets for the userId and todays date.
     * @param wiredDto
     */
    @wire(retrieveRouteProcessingSheets, {userId: '$_userId', collectionDate: '$_collectionDate', cacheBust: '$_cacheBust'})
    retrieveRpsData(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const { data, error } = this._wiredRpsDto;

        if(data) {
            this._doneSearching = true;
            if(data.isSuccess) {
                console.log('---> rps dto=',data);
                let tmpRpsData = [...this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, data.values)];
                let tmpRpsData2 = [...this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, data.values)];
                this.routeData = this._accelUtils.getMapValue(MAP_KEY_ROUTE_DATA,data.values);
                this.routeScheduleId = this._accelUtils.getMapValue(MAP_KEY_ROUTE_SCHEDULE_ID,data.values );
                if(tmpRpsData) {
                    this.rpsData =  tmpRpsData.map( (rps,index) => {
                        let disableUpArrow =  index === 0;
                        let disableDownArrow  = index === (tmpRpsData.length - 1);
                        return  {...rps, disableUpArrow : disableUpArrow, disableDownArrow : disableDownArrow}
                    });
                    this.originalRpsData =  tmpRpsData2.map(element => Object.assign({},element));
                }
                this._isProcessing = false;
                this._allDataLoaded = true;
                //  Pop toast of more then one route schedule for today assigned to this user!
                if(data.severity && data.severity === 'warning') {
                    this.showToast('',data.message,'warning');
                    console.warn(data.technicalMsg);
                }
            } else {
                console.log('---> rps dto=',data);
                //----> obsolete this req has been trashed.
                //---------------------------------------this.navigate(PAGE_ROUTE_SELECTION);
                //@TODO We will always have the custom mdt at this time?
                if(this.rpsMdt && this.rpsMdt.Allow_Collector_Route_Selection__c) {
                    this.navigate(PAGE_ROUTE_SELECTION);
                } else {
                    this.rpsData = undefined;
                    this.emptyBodyText = data.message;
                    this._allDataLoaded = true;
                    this.uiErrorMsg.body = data.message + '. Please contact an administrator [email addy?]';
                }
            }
        } else if (error) {
            this._doneSearching = true;
            this.error = reduceErrors(error);
            //this.showToast('','Problem retrieving data: '+this.error,'error');
            console.error('---> getting rpsData error',this.error);
            console.error('--->',error);
            this.uiErrorMsg.body = this.error;
            this._isProcessing = false;
            this._allDataLoaded = true;
        }
    }

    /**
     * Retrieve the route schedule data by Route_Schedule__c.Id.
     * @param wiredDto
     */
    @wire(retrieveRouteScheduleData, { routeScheduleId: '$routeScheduleId',cacheBust: '$_cacheBust'})
    retrieveRouteScheduleData(wiredDto) {
        this._wiredRouteScheduleDto = wiredDto;
        const { data, error } = this._wiredRouteScheduleDto;
        if(data) {
            this._doneSearching = true;
            console.log('---> rsdata retrieve result',data.isSuccess);
            if(data.isSuccess) {
                this.routeScheduleData = this._accelUtils.getMapValue(MAP_KEY_ROUTE_SCHEDULE_DATA,data.values);
                if(this.routeScheduleData) {
                    if(this.missingVehicleStartInfo || this.missingVehicleEndingMileage) {
                        this.openVehicleForm = true;
                    }
                }
            } else {
                this.showToast('',data.message,'error');
            }
            this._isProcessing = false;
        } else if (error) {
            this._doneSearching = true;
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving data: '+this.error,'error');
            this.uiErrorMsg.body = this.error;
            this._isProcessing = false;
        }
    }

    /**
     *  Get the route processing sheets custom meta-data.
     * @param wiredData
     */
    @wire(retrieveMdt, { mdtDevName: '$_rpsMdtDevName' })
    wiredMdt(wiredData) {
        this._wiredRpsMdt = wiredData;
        const { data, error } = wiredData;
        this._cacheBust = Math.random();
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
        } else if (data) {
            if(data.isSuccess) {
                this.rpsMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
                if(this.allowDnd) {
                    this.loadSortable();
                }
            } else {
                console.info('-- counld not find mdt:',data);
            }
        }
    }

    /**
     * Get url state for purposes of navigating to other pages and returning back.
     * @param currentPageReference
     */
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            //console.log('xxxx cpr state='+JSON.stringify(currentPageReference.state));
            this.urlStateParameters = currentPageReference.state;
            if(this.urlStateParameters) {
                this.setParametersBasedOnUrl();
                //  @todo DOUBLE CHECK THIS IS. THIS GOOD?
                // console.info('----> CURRENT STATE EXISTS! FORCING dto REFRESH!');
                // this.rpsData = [];
                // this.routeData = {};
                // refreshApex(this._wiredRpsDto);
                // refreshApex(this._wiredRouteScheduleDto);
            } else {

            }
        }
    }

    /**
     * Fire the queueable that sends the email. Toast a result.
     * @param rs The Route_Schedule__c sObject
     */
    sendRouteEmail(rs) {
        let params = {routeSchedule:rs};
        console.log('---> calling send email with params,',params);
        doSendRouteEmail(params)
            .then((dto) => {
                console.log('----> email dto', JSON.parse(JSON.stringify(dto)));
                this.showToast('',dto.message,dto.severity);
            })
            .catch((error) => {
                console.error(error);
                this.error = reduceErrors(error);
                this.showToast('','error sending email '+this.error,'error');
            });
    }

    updateRpsStatus(status) {
        let params = {rpsId:this._selectedRpsId, status:status};
        console.log('---> calling update rps status,',params);
        doRouteProcessingSheetStatusUpdate(params)
            .then((result) => {
                console.info('----> opt dto', JSON.parse(JSON.stringify(result)));
                this._cacheBust = Math.random();
                refreshApex(this._wiredRpsDto);
                //this.retrieveRpsImperative();
            })
            .catch((error) => {
                console.error(error);
                this.error = reduceErrors(error);
            });
    }

    /**
     * 1. Create new Route_Processing_Sheet__c sObject objects to send to server for update with
     *    Id and Stop_Number__c properties.
     * 2. Call Server Side Imperative update.
     */
    updateStopNumbers() {
        let rpsUpdate = [];

        this.rpsData.forEach(rps => {
           let updRps = { 'sobjectType':'Route_Processing_Sheet__c'};
           updRps.Id = rps.rpsId;
           updRps.Stop_Number__c = rps.rpsStopNumber;
           updRps.Route_Schedule_Account__c = rps.rps.Route_Schedule_Account__c;
           rpsUpdate.push(updRps);
        });
        console.log('---> sending rps records for update:',rpsUpdate);

        let params = { allRpss:rpsUpdate };
        doUpdateStopNumbers(params)
            .then((result) => {
                console.info('----> update dto', JSON.parse(JSON.stringify(result)));
            })
            .catch((error) => {
                console.error(error);
                this.error = reduceErrors(error);
            });
    }


    /**
     * Start the route schedule (ie set time stamps)
     * @todo not yet implemented server side.
     */
    startRouteSchedule() {
        let params = {routeScheduleId: this.routeScheduleId};
        console.log('---> calling startRouteSchedule,',params);
        this._isProcessing = true;
        doRouteScheduleStart(params)
            .then((result) => {
                console.info('----> opt dto', JSON.parse(JSON.stringify(result)));
                refreshApex(this._wiredRouteScheduleDto);
                //this.retrieveRSDataImperative();
                this.showToast('',result.message,'success');
                this._isProcessing = false;
            })
            .catch((error) => {
                console.error(error);
                this.error = reduceErrors(error);
            });
    }

    /**
     * End the route schedule (ie set time stamps)
     */
    endRouteSchedule() {
        let params = {routeScheduleId: this.routeScheduleId};
        console.log('---> calling endRouteSchedule,',params);
        this._isProcessing = true;
        doRouteScheduleEnd(params)
            .then((result) => {
                refreshApex(this._wiredRouteScheduleDto);
                //this.retrieveRSDataImperative();
                this.showToast('',result.message,'success');
                this._isProcessing = false;
            })
            .catch((error) => {
                console.error(error);
                this.error = reduceErrors(error);
            });
    }

    /**
     * Stop the clicked event from propagating the clicked event of the parent ul tag.
     * @param evt
     */
    handleHaltClick(evt){
        evt.stopPropagation();
    }
    handleStartRoute(evt) {
        this.startRouteSchedule();
    }
    handleEndRoute(evt) {
        this.endRouteSchedule();
    }
    /**
     * Handle the rps card selected event.
     * @param evt
     */
    handleItemSelected(evt) {
        if(this.showReOrderStopsCancelButton) {
            return;
        }
        if(this.missingVehicleStartInfo) {
            this.showToast('','Please Enter Vehicle Information First.','warning');
            return;
        }
        if(this.showRouteStartButton) {
            this.showToast('','Please click Start Route before clicking a location.','warning');
            return;
        }
        const rpsId = evt.currentTarget.dataset.rpsid
        this._selectedRpsId = rpsId;
        const accountId = evt.currentTarget.dataset.accountid;
        const rpsStatus = evt.currentTarget.dataset.rpsstatus;
        evt.preventDefault();
        evt.stopPropagation();
        //this.startRouteSchedule();
        if(rpsStatus != 'Complete' && rpsStatus != 'Skipped') {
            this.updateRpsStatus('In Progress');
        }
        this.navigate(PAGE_METER_READINGS,rpsId,accountId,this.routeId,RECORD_TYPE_VGT);
    }

    handleAlertLinkClick(evt) {
        let alertName;
        if(evt.detail && evt.detail.name) {
            alertName = evt.detail.name;
        }
        if(alertName == 'go_routeschedule_listview') {
            this.navigateInternalListView('Route_Schedule__c','');
        }
    }

    /**
     * Handle the Assign to me confirmation of the assign action.  if confirmed.
     * caLl selectRouteSchedule with selected route schedule id.
     * @param evt
     */
    handleSendRouteEndEmail(evt) {
        if(evt.detail !== 1){
            const detail = evt.detail.originalMessage;
            if(evt.detail.status === 'confirm') {
                this.sendRouteEmail(this.routeScheduleData);
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.sendRouteEndEmailDialogVisible = false;
    }

    /**
     * Handles the fact that the missing vehicle info form was saved / refreshes the route schedule data.
     *
     * @param evt
     */
    handleVehicleFormSubmitted(evt) {
        this.openVehicleForm = false;
        this._cacheBust = Math.random();
        refreshApex(this._wiredRouteScheduleDto);
        //this.retrieveRSDataImperative();
    }

    handleAddyClick(evt) {
        const url = evt.currentTarget.dataset.url;
        evt.stopPropagation();
        evt.preventDefault();
        window.open(url,'_blank');
    }
    handleContactClick(evt) {
        evt.stopPropagation();
        // evt.preventDefault();
    }

    /**
     * Handles the fact that the missing vehicle info form was closed / removes form from the DOM.
     * @param evt
     */
    handleFormCloseClicked(evt) {
        this.openVehicleForm = false;
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

    navigateToPageNoState(pageName) {
        this[NavigationMixin.Navigate]({type: 'comm__namedPage', attributes: {pageName: pageName}});
    }

    /**
     * @param pageName
     */
    navigate(pageName,rpsId,accountId,routeId,view) {
        try {
            //override view. just make it random so the cached page doesn't pull up.
            view = new Date();
            console.log('attempting to nav to pageName:'+pageName + '... rpsId='+rpsId+'... acountId='+accountId+'..view='+view);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {
                    routeId: routeId,
                    rpsId: rpsId,
                    accountId: accountId
                }
            });
            /*      view:view */
        } catch (e) {
            console.error(e);
        }
    }


    /**
     *
     * @param objectApiName
     * @param filterName
     */
    navigateInternalListView(objectApiName,filterName) {
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: objectApiName,
                    actionName: 'list'
                },
                state: {
                    filterName: filterName
                }
            });
        } catch (e) {
            console.error(e);
        }
    }
    setParametersBasedOnUrl() {
        if(!this._disconnectCb) {
            if (this.urlStateParameters.routeId) {
                this.routeId = this.urlStateParameters.routeId;
            }
        }
    }
    get showRouteStartedDate() {
        return this.routeScheduleData && this.routeScheduleData.Route_Start_Timestamp__c ;
    }

    get showRouteEndedDate() {
        return this.routeScheduleData && this.routeScheduleData.Route_End_Timestamp__c;
    }

    get showRouteStartButton() {
        return this.routeScheduleData && !this.routeScheduleData.Route_Start_Timestamp__c && !this.showReOrderStopsButtons;
    }
    get showRouteEndButton() {
        let showIt = this.routeScheduleData && !this.routeScheduleData.Route_End_Timestamp__c
            && this.routeScheduleData.Collection_Status__c == COLLECTION_COMPLETED_STATUS
            && (this.routeScheduleData.Ending_Vehicle_Milage__c);
        if(showIt === undefined) {
            showIt = false;
        }
        console.info('---> showRouteEndButton='+showIt);
        return showIt;
    }
    get isSysAdmin() {
        return this.runningUser && this.runningUser.Profile && this.runningUser.Profile.Name == 'System Administrator';
    }
    get isRouteScheduleComplete() {
        return this.routeScheduleData && this.routeScheduleData.Collection_Status__c == COLLECTION_COMPLETED_STATUS;
    }
    get showRpsData() {
        return this.rpsData && this._allDataLoaded;
    }

    get showRpsRtModel() {
        return this.rpsData && this.rpsData.rpsRtModel;
    }

    get showDistance() {
        return this.rpsMdt && this.rpsMdt.Display_Location_Distance__c;
    }

    get missingVehicleStartInfo() {
        let showIt = this.routeScheduleData && this.routeScheduleData.Missing_Vehicle_Start_Info__c;
        return showIt;
    }

    /**
     * If the over status (collection status) on the route schedule is Completed and there is
     * no Ending_Vehicle_Milage__c value on the route_schedule, show the red alert at the top and
     * auto open the vehicle form displaying all of the vehicle fields as well as the ending mileage field.
     * @return {boolean}
     */
    get missingVehicleEndingMileage() {
        let showIt = this.routeScheduleData && this.routeScheduleData.Collection_Status__c == COLLECTION_COMPLETED_STATUS
            && !this.routeScheduleData.Ending_Vehicle_Milage__c;
        return showIt;
        // let missingIt;
        // missingIt = this.routeScheduleData
        //             && this.routeScheduleData.Collection_Status__c == COLLECTION_COMPLETED_STATUS
        //             && !this.routeScheduleData.Ending_Vehicle_Milage__c;
        // if(missingIt) {
        //     this.openVehicleForm = true;
        // }
        // return missingIt;
    }



    handleToggleVehicleLink(evt) {
        this.openVehicleForm = evt.target.dataset.showit === 'true';
    }

    handleVehicleAlertContainerClick(evt) {
        //this.openVehicleForm = evt.target.d
        this.openVehicleForm = !this.openVehicleForm;
    }

    handleVehicleEndingMileageAlertContainerClick(evt) {
        //this.openVehicleForm = evt.target.d
        this.openVehicleForm = !this.openVehicleForm;
        // this._cacheBust = Math.random();
        // refreshApex(this._wiredRouteScheduleDto);
    }

    handleMissingVehicleLinkClick(evt) {
        evt.preventDefault();
        //this.openVehicleForm = evt.target.dataset.showit === 'true';
    }

    get vehicleLinkText() {
        let text;
        if(!this.missingVehicleStartInfo && this.routeScheduleData) {
            text = this.routeScheduleData.Vehicle__c + ' - ' + this.routeScheduleData.Vehicle_License__c;
        }
        return text;
    }
    get showEndingMileage() {
        return this.routeScheduleData && this.routeScheduleData.Collection_Status__c == COLLECTION_COMPLETED_STATUS;
    }
    get vehicleFormStyle() {
        return this.openVehicleForm ? 'display:block' : 'display:none';
    }
    get formClass() {
        return FORM_CLASS;
    }

    get showNoData() {
        let showIt;
        showIt = (!this.rpsData || this.rpsData.length < 1) && this.emptyBodyText;
        return showIt;
    }

    get showTotalAccounts() {
        return this.routeScheduleData && this.routeScheduleData.Total_Accounts__c;
    }

    get formHelpMsg() {
        let text = '';
        if(this.missingVehicleStartInfo) {
            text = 'Please enter missing vehicle data and hit save to continue.';
        } else {
            text = 'Please modify vehicle data and hit save.';
        }
        return text;
    }

    get missingVehicleStartInfoText() {
        return this.labels.lblMissingVehicleInfo;
    }
    get missingVehicleEndingMileageText() {
        return this.labels.lblMissingVehicleEnding;
    }
    get rpsCardSubtitle() {
        return this.routeData ? this.routeData.Name : null;
    }

    get allowLongPolling() {
        return this.rpsMdt && this.rpsMdt.Allow_Long_polling__c;
    }
    get allowStopRecorder() {
        return this.rpsMdt && this.rpsMdt.Allow_RPS_Reorder__c;
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

    handleTileDragEnd(evt) {

    }
    handleTileDragEnter(evt) {

    }

    handleTileTouchStart(evt) {
        console.log('---> touchstart handler');
        //this.cancel(evt);
    }
    handleTileTouchMove(evt) {
        console.log('---> touchmove handler');
        //this.cancel(evt);
    }
    handleTileTouchEnd(evt) {
        console.log('---> touchend handler');
        //this.cancel(evt);
    }
    //Set the style to indicate the element is being dragged over
    addDragOverStyle() {
        let draggableElement = this.template.querySelector('[data-role="drop-target"]');
        draggableElement.classList.add('accel-drag-over');
    }

    //Reset the style
    removeDragOverStyle() {
        let draggableElement = this.template.querySelector('[data-role="drop-target"]');
        draggableElement.classList.remove('accel-drag-over');
    }

    get showReOrderStopsButton() {
        let ret = false;
        ret  = this.rpsData && !this.missingVehicleStartInfo && !this._reorderStopsClicked;
        return ret;
    }

    get showBvTypes() {
        return this.rpsMdt && this.rpsMdt.Show_BV_Types__c;
    }

    get showPhoneAsHelptext() {
        return this.rpsMdt && this.rpsMdt.Show_Phone_As_Helptext__c;
    }
    get showCollectionNotes() {
        return this.rpsMdt && this.rpsMdt.Show_Collection_Notes__c;
    }

    get allowDnd() {
        return this.rpsMdt && this.rpsMdt.Allow_RPS_Drag_And_Drop__c;
    }

    get showReOrderStopsButtons() {
        return this.showReOrderStopsCancelButton || this.showReOrderStopsSaveButton && this.allowDnd;
    }
    get isDndActive() {
        return this.showReOrderStopsCancelButton;
    }
    get showReOrderStopsCancelButton() {
        return this.rpsData && !this.missingVehicleStartInfo && this._reorderStopsClicked;
    }
    get showReOrderStopsSaveButton() {
        return this.showReOrderStopsCancelButton;
    }

    /**
     * Adds Send email option to drop down menu i CL Exp Cloud Settings / RouteProcessingSheets Show_Send_Route_End_Email_Menu_Item__c is checked.
     * @returns {boolean}
     */
    get showSendEndRouteEmail() {
        let showIt = this.routeScheduleData && this.rpsMdt && this.rpsMdt.Show_Send_Route_End_Email_Menu_Item__c;
        return showIt;
    }


    //Function to cancel drag n drop events
    cancel(evt) {
        if (evt.stopPropagation) evt.stopPropagation();
        if (evt.preventDefault) evt.preventDefault();
        return false;
    };

    handleReOrderStopsClick(evt){
        let tileCards = this.template.querySelectorAll('[data-role="drop-target"]');
        if(tileCards) {
            this._reorderStopsClicked = true;
            tileCards.forEach(( tile, index) => {
                tile.classList.add('accel-draggable-tile');
            });
            this.registerDragDropEvents();
        }
        //evt.classList.toggle('SelectedBorderOrgType');
    }
    handleReOrderContainerClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();
    }

    /**
     * 1. Block propagation and default (card click events). Determine which card was clicked.
     * 2. Find the current card clicked and it's index in the array.
     * 3. Find the next or previous card (pending on the button clicked and find it's stop number and idx)
     * 3. Swap stop number values.
     * 4. Resort all rps cards (client side).
     * 5. Display top and bottom card up / down buttons.
     * 6. Call async server side update.
     *
     * @param evt
     */
    handleReOrderArrowClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();

        const rpsId = evt.currentTarget.dataset.rpsid
        const reorderType = evt.currentTarget.dataset.reordertype;

        if (rpsId) {

            let rpsClicked = this.rpsData.find(rps => rps.rpsId === rpsId);
            let rpsClickedIdx = this.rpsData.findIndex(rps => rps.rpsId === rpsId);
            const oldStopNumber = rpsClicked.rpsStopNumber.valueOf();
            console.log('---> rpsClicked==',JSON.parse(JSON.stringify(rpsClicked)));
            console.log('--> rpsClicked idx='+rpsClickedIdx + ' .. stop#='+rpsClicked.rpsStopNumber);

            if (rpsClicked) {
                //console.log('rps clicked id='+rpsClicked.)
                if (reorderType === REORDER_DOWN) {
                    let nextRpsIdx = rpsClickedIdx + 1;
                    let nextRps = this.rpsData[nextRpsIdx];
                    const newStopNumber = nextRps.rpsStopNumber.valueOf();

                    console.log('--> nextRps idx='+nextRpsIdx + ' .. stop#='+nextRps.rpsStopNumber);
                    rpsClicked.rpsStopNumber = newStopNumber;
                    nextRps.rpsStopNumber = oldStopNumber;
                    nextRps.locName = '(' + nextRps.rpsStopNumber + ') ' + nextRps.locFullName;
                } else {
                    let prevRpsIdx = rpsClickedIdx - 1;
                    let prevRps = this.rpsData[prevRpsIdx];
                    const newStopNumber = prevRps.rpsStopNumber.valueOf();

                    rpsClicked.rpsStopNumber = newStopNumber;
                    prevRps.rpsStopNumber = oldStopNumber;
                    prevRps.locName = '(' + prevRps.rpsStopNumber + ') ' + prevRps.locFullName;
                }
                rpsClicked.locName = '(' + rpsClicked.rpsStopNumber + ') ' + rpsClicked.locFullName;

                this.reSortRpsSheets();
                this.disableRpsSheetArrowButtons();
                this.updateStopNumbers();
            }
        }
    }

    findNextStopRps(rpsClicked) {
        const tmpRpsData = [...this.rpsData];

    }


    // handleDndOnEnd(evt) {
    //     console.log('on end rpsId', evt.item.dataset.rpsid);
    //     const rpsId = evt.item.dataset.rpsid;
    //     if (rpsId) {
    //         let rpsDragged = this.rpsData.find(rps => rps.rpsId === rpsId);
    //         if(evt.newIndex !== evt.oldIndex) {
    //             let fromStop = Number(evt.oldIndex) + 1;
    //             let toStop = Number(evt.newIndex) + 1;
    //             this._dndOnEndMsg = 'Moved '+rpsDragged.locFullName + ' from stop ' + fromStop  +' to stop '+toStop;
    //             //console.log('Moved '+rpsDragged.locFullName + ' from stop ' + fromStop  +' to stop '+toStop);
    //         }
    //         rpsDragged.rpsStopNumber = evt.newIndex + 1;
    //         rpsDragged.locName = '(' + rpsDragged.rpsStopNumber + ') ' + rpsDragged.locFullName;
    //         let iNumItems = this.rpsData.length;
    //
    //         let allListItems = this.template.querySelectorAll('[data-role="drop-target"]');
    //         allListItems.forEach((ele, index) => {
    //             let id = ele.dataset.rpsid;
    //             let rps = this.rpsData.find(rps => rps.rpsId == id);
    //             rps.rpsStopNumber = index + 1;
    //             rps.locName = '(' + rps.rpsStopNumber + ') ' + rps.locFullName;
    //         });
    //     }
    //     console.log(rpsId);
    // }


    handleReOrderStopsCancelClick(evt){
        let tileCards = this.template.querySelectorAll('[data-role="drop-target"]');
        if(tileCards) {
            //this._reorderStopsCancelClicked = true;
            this._reorderStopsClicked = false;
            this.rpsData = this.originalRpsData;
            this.reSortRpsSheets();
            //  this._cacheBust = Math.random();
            //  refreshApex(this._wiredRpsDto);
            //this.rps
            tileCards.forEach(( tile, index) => {
                tile.classList.remove('accel-draggable-tile');
            });
            this.unregisterDragDropEvents();

        }
        //evt.classList.toggle('SelectedBorderOrgType');
    }

    handleReOrderStopsSaveClick(evt){
        let tileCards = this.template.querySelectorAll('[data-role="drop-target"]');
        if(tileCards) {
            //this._reorderStopsCancelClicked = true;
            this._reorderStopsClicked = false;
            tileCards.forEach(( tile, index) => {
                tile.classList.remove('accel-draggable-tile');
            });
            this.unregisterDragDropEvents();
        }
        this.showToast('DEV NOTE', 'Save not yet implemented','info');
        //evt.classList.toggle('SelectedBorderOrgType');
    }

    /**
     * Handle all card menu option selections and delegate to specific handler.
     * @param evt
     */
    handleCardMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        switch (selectedItemValue) {
            case 'reorderstops' :
                this.handleReOrderStopsClick(evt);
                break;
            case 'sendendrouteemail' :
                this.handleSendRouteEndEmailClick(evt);
                break;
        }
    }

    /**
     * Pops the Send route end email dialog.
     * @param evt
     */
    handleSendRouteEndEmailClick(evt) {
        this.sendRouteEndEmailDialogVisible = true;
    }

    registerDragDropEvents() {
        console.log('---> registerDragDrop');
        let tileContainer = this.template.querySelector('.accel-tile-container');
        let config = {
            animation: 150,
            delay: 100,
            delayOnTouchOnly: true,
            easing: 'cubic-bezier(.17,.67,.83,.67)',
            ghostClass: 'accel-dnd-ghost',
            chosenClass: 'accel-dnd-chosen',
            dragoverBubble: true,
            onEnd: this.handleDndOnEnd.bind(this),
            onMove: this.handleDndOnMove.bind(this),
            onChange: this.handleDndOnChange.bind(this)
        }
        this._sortable = Sortable.create(tileContainer,config);
    }

    unregisterDragDropEvents() {
        console.log('---> unregisterDragDrop');
        // if(this._sortable) {
        //     this._sortable.option("disabled",true);
        // }
        let tileCards = this.template.querySelectorAll('[data-role="drop-target"]');
        if(tileCards) {
            // this._allowDragDrop = false;
            tileCards.forEach(( tile, index) => {
                tile.classList.remove('accel-draggable-tile','dropzone', 'draggable-dropzone--occupied', 'item');
                // tile.removeEventListener( "ondragstart", this.handleTileDragStart);
                // tile.removeEventListener( "ondragend", this.handleTileDragEnd);

            });
        }
    }
    handleDndOnMove(evt) {
        // const draggedRpsId = evt.dragged.dataset.rpsid;
        // const replacedRpsId = evt.related.dataset.rpsid;
        // if(replacedRpsId) {
        //     let replacedRps = this.rpsData.find(rps => rps.rpsId === replacedRpsId);
        // }
        console.log('on move ');
        //const rpsId = evt.item.dataset.rpsid;
    }

    /**
     * Trigger by sortableJs. Finds the dragged list element and it's associated item in the saved array.
     * Changes it's rpsStopNumber to the (dragged to) idx in the array.
     * @param evt
     */
    handleDndOnEnd(evt) {
        console.log('on end rpsId', evt.item.dataset.rpsid +'..oldIdx='+evt.oldIndex + '.. new idx='+evt.newIndex);
        const rpsId = evt.item.dataset.rpsid;
        if (rpsId) {
            let rpsDragged = this.rpsData.find(rps => rps.rpsId === rpsId);
            if(evt.newIndex !== evt.oldIndex) {
                let fromStop = Number(evt.oldIndex) + 1;
                let toStop = Number(evt.newIndex) + 1;
                this._dndOnEndMsg = 'Moved '+rpsDragged.locFullName + ' from stop ' + fromStop  +' to stop '+toStop;
                //console.log('Moved '+rpsDragged.locFullName + ' from stop ' + fromStop  +' to stop '+toStop);
            }
            rpsDragged.rpsStopNumber = evt.newIndex + 1;
            rpsDragged.locName = '(' + rpsDragged.rpsStopNumber + ') ' + rpsDragged.locFullName;
            let iNumItems = this.rpsData.length;

            let allListItems = this.template.querySelectorAll('[data-role="drop-target"]');
            allListItems.forEach((ele, index) => {
                let id = ele.dataset.rpsid;
                let rps = this.rpsData.find(rps => rps.rpsId == id);
                rps.rpsStopNumber = index + 1;
                rps.locName = '(' + rps.rpsStopNumber + ') ' + rps.locFullName;
            });
        }
        console.log(rpsId);
    }

    handleDndOnChange(evt) {
        console.log('on change');
    }

    /**
     * Gets around LWC shadow DOM limitations.
     */
    buildSfdcCoreOverrideCss() {
        themeOverrider.buildSfdcCoreOverrideCss(this);
    }

    loadSortable() {
        loadScript(this, SORTABLE + '/Sortable.min.js')
            .then(() => {
                console.log('----> sortable loaded!');
            })
            .catch(error => {
                alert(error);
            });
    }

    /**
     * Loads font awesome js and css for fonts not available in SLDS.
     */
    loadFontAwesome() {
        //alert('calling load fa');
        Promise.all([
            //loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/style.css'),
        ])
            .then(() => {
                console.log('fa loaded');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }
    disableRpsSheetArrowButtons() {
        this.rpsData.forEach( (rps,index) => {
            rps.disableUpArrow =  index === 0;
            rps.disableDownArrow = index === this.rpsData.length - 1;
        });
    }
    reSortRpsSheets() {
        this.rpsData.sort((a,b) => (a.rpsStopNumber > b.rpsStopNumber) ? 1 : -1);
    }

    get platformEventChannel() {
        return PLATFORM_EVENT_CHANNEL;
    }

    /**
     * Handle the subscription to the Route_Schedule_Change__c platform event. (child cmp).
     *
     * 1. Ensure the PE sent route schedule ids.
     * 2. Check to ensure one of the ids in the array equals the current Route Schedule Id in context.
     * 3. If so. refresh the rps view and show a toast informing the user a location has been added.
     *
     * @param evt The Custom Event fired from the child component containing the PE payload.
     * @see cl-exp-cloud-event-subscriber
     */
    handleAdditionalFillPlatformEvent(evt) {
        if (evt.detail && evt.detail.data) {
            let payload = evt.detail.data.payload;
            let rsIds = payload.Route_Schedule_Ids__c;
            if (payload && rsIds) {
                if (payload && payload.Publishing_Process_Name__c == PE_PUBLISHING_PROCESS_NAME) {
                    let arrRsIds = rsIds.split(',');
                    let currentSchedule = arrRsIds.includes(this.routeScheduleId);
                    if (currentSchedule) {
                        console.info('---> SERVER SIDE PAYLOAD RECEIVED', payload);
                        if (payload && payload.Object_JSON__c) {
                            console.info('---> RPS RECORDS ADDED=', JSON.parse(payload.Object_JSON__c));
                        }
                        this._cacheBust = Math.random();
                        refreshApex(this._wiredRpsDto);
                        this.showToast('',payload.Ui_Message__c, 'success');
                    }
                }
            }
        }
    }
}