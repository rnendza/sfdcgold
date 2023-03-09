import {LightningElement,wire,track,api} from 'lwc';
import {reduceErrors} from "c/ldsUtils";
import Id from '@salesforce/user/Id';
import retrieveRouteSchedules from '@salesforce/apex/clRouteScheduleSelection.retrieveRouteSchedules';
import retrieveRegionRouteSchedules from '@salesforce/apex/clRouteScheduleSelection.retrieveRegionRouteSchedules';
import doRouteScheduleSelection from '@salesforce/apex/clRouteScheduleSelection.doRouteScheduleSelection';
import {uiHelper} from "./clRouteScheduleSelectionUiHelper";
import {getConstants} from "c/clConstantUtil";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {NavigationMixin} from "lightning/navigation";
import lblWelcomeMsg from '@salesforce/label/c.CL_Route_Selection_Welcome_Message';
import Logger from 'c/logger'

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_ROUTE_SCHEDULE_WRAPPERS = 'ROUTE_SCHEDULE_WRAPPERS';
const PAGE_HOME = 'home';
const PLATFORM_EVENT_CHANNEL = 'Route_Schedule_Change_PE__e';
const PE_PUBLISHER_CHECK_SCH_ASSIGNMENTS = 'clRouteScheduleTriggerHandler_checkScheduleAssignments';

export default class ClRouteScheduleSelection extends NavigationMixin(LightningElement) {

    @api allRegionLabel = ' - All Regions - ';
    @api allRegionsValue = '*';
    @api showRegionSelector;
    @api regionSelectLabel = 'Collector Location';

    @api
    get suppressedRegionValues() { return this._suppressedRegionValues;}
    set suppressedRegionValues(val) { this.parseSuppressedRegionValues(val); }
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    @track routeSchedules;
    @track routeProcessingSheets;
    @track noDataMsg = {header: '', body : ''};
    @track rsFields = {fieldALabel:null,fieldAValue:null};
    @track isDialogVisible = false;
    @track dialogPayload;
    @track confirmDisplayMsg;
    @track testMessage;
    @track regionSelected;

    labels = {lblWelcomeMsg};

    _numRouteSchedules;
    _isAccordionProcessing;
    _isLoading;
    _isRegionReload;
    _userId = Id;
    _collectionDate;
    _regionCollectionDate;
    _wiredRsDto;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _totalRps = 0;
    _suppressedRegionValues;

    constructor(){
        super();
        console.info('%c----> /lwc/clRouteScheduleSelection',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this.showRegionSelector = true;
        this.debugConsole = true;
        this._suppressedRegionValues = null;
    }

    connectedCallback() {
        this._isLoading = true;
        if(!this.showRegionSelector) {
            this._collectionDate = new Date(new Date().setHours(0,0,0,0));
        } else {
            this._regionCollectionDate = new Date(new Date().setHours(0,0,0,0));
            if(!this.regionSelected) {
                this.regionSelected = this.allRegionsValue;
            }
        }
        this._logger.logDebug('----> connectedCbk collection date',this._collectionDate);
        this._logger.logDebug('----> connectedCbk regioncollection date',this._regionCollectionDate);
    }

    renderedCallback() {

    }

    /**
     * Take comma delim string prop and parse into array for suppressed region names.
     * @param vals
     */
    parseSuppressedRegionValues(vals) {
        this._logger.logDebug('--> parsesuppressedRegionValues',vals);
        if(vals) {
            this._suppressedRegionValues =  vals.split(',');
        } else {
            this._suppressedRegionValues = null;
        }
        this._logger.logDebug('--> suppressedRegionValues',this._suppressedRegionValues);
    }

    /**
     * Find all route schedules for the collection date and region selected.
     * @param wiredDto  The wired data transfer object.
     */
    @wire(retrieveRegionRouteSchedules, {
        collectionDate: '$_regionCollectionDate',
        region: '$regionSelected',
        suppressedValues: '$_suppressedRegionValues'
    })
    retrieveRegionData(wiredDto) {
        this._wiredRsDto = wiredDto;
        const { data, error } = this._wiredRsDto;
        if(data) {
            const dto = data;
            this._logger.logDebug('--> retrieveRegionRouteSchedules',dto);
            this._isRegionReload = false;
            if(dto.isSuccess) {
                this.shapeRouteScheduleData(this._accelUtils.getMapValue(MAP_KEY_ROUTE_SCHEDULE_WRAPPERS, dto.values));
            } else {
                this.routeSchedules = null;
                this._numRouteSchedules = 0;
                let header ='No route schedules found for today';
                if(this.showRegionSelector) {
                    if(this.regionSelected !== this.allRegionsValue) {
                        header += ' for '+this.regionSelected + '.';
                        this.noDataMsg.bodyText = null;
                    } else {
                        header += ' for all regions.';
                        if(this._suppressedRegionValues) {
                            this.noDataMsg.bodyText = ' The following regions are not active: '+this._suppressedRegionValues;
                        }
                    }
                } else {
                    header +='.';
                }
                this.noDataMsg.header = header;
                if(!this.noDataMsg.bodyText) {
                    this.noDataMsg.bodyText = 'Please contact your administrator';
                }
            }
            this._isLoading = false;
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            uiHelper.showToast(this,'','Problem retrieving route schedule data: '+this.error,'error');
            this._isLoading = false;
            this._isRegionReload = false;
        }
    }

    /**
     * Find all route schedules for the collection date.
     * @param wiredDto  The wired data transfer object.
     */
    @wire(retrieveRouteSchedules, {collectionDate: '$_collectionDate'})
    retrieveData(wiredDto) {
        this._wiredRsDto = wiredDto;
        const { data, error } = this._wiredRsDto;
        if(data) {
            const dto = data;
            console.log('data',JSON.stringify(dto));
            if(dto.isSuccess) {
                this.shapeRouteScheduleData(this._accelUtils.getMapValue(MAP_KEY_ROUTE_SCHEDULE_WRAPPERS, dto.values));
            } else {
                this.noDataMsg.header = 'No route schedules found for today.'
                this.noDataMsg.bodyText = 'Please contact your administrator';
            }
            this._isLoading = false;
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            uiHelper.showToast(this,'','Problem retrieving route schedule data: '+this.error,'error');
            this._isLoading = false;
        }
    }


    /**
     * Shape the data for display / modification purposes.
     * @param routeSchedules
     */
    shapeRouteScheduleData(routeSchedules) {
        this._numRouteSchedules = routeSchedules.length;
        let newRss = [];
        let totalRouteProcessingSheets = 0;

        routeSchedules.forEach(rs => {
            this._totalRps += rs.rsTotalRps;
            let newRs = Object.assign({},rs);
            newRs.rsDisableButton = newRs.rsFullyAssigned;
            if(!newRs.rsDisableButton) {
                newRs.rsDisableButton = newRs.rsTotalRps === 0 ? true : false;
            }
            if(newRs.rsTotalLocs === 0) {
                newRs.rsLocStyle = 'color:red';
            }
            if(newRs.rsFullyAssigned) {
                newRs.rsFullyAssignedMsg = rs.rsName +' is already assigned!';
            }
            let col1Val,col2Val,col1Style,col2Style,col1ShowIcon,col2ShowIcon;

            if(rs.rsCollector1Name) {
                col1Val = rs.rsCollector1Name;
                col1ShowIcon = true;
            } else {
                col1Val = 'Unassigned';
                col1Style = 'font-size:.70rem;color:gray;';
            }
            if(rs.rsCollector2Name) {
                col2Val = rs.rsCollector2Name;
                col2ShowIcon = true;
            } else {
                col2Val = 'Unassigned';
                col2Style = 'font-size:.70rem;color:gray;';
            }
            newRs.dynaA = {label:'Collector 1',value:col1Val, style:col1Style,showIcon:col1ShowIcon};
            newRs.dynaB = {label:'Collector 2',value:col2Val, style:col2Style,showIcon:col2ShowIcon};
            newRss.push(newRs);
        });
        this.routeSchedules = newRss;
        if(this._totalRps === 0) {
            this.handleNoRps();
        }
    }

    handleNoRps() {
        uiHelper.showToast(this,'','There are no route processing sheets for today. Please contact your administrator','warning');
    }

    handleRegionSelected(evt) {
        this._logger.logDebug('----> region selected',evt.detail);
        const optSelected = evt.detail;
        this._isRegionReload = true;
        if(optSelected !== '-1') {
            this._isLoading = true;
            this.regionSelected = evt.detail;
        }
    }

    /**
     * Fire update to select the route schedule. A SS check will be enforced and either
     * Route_Schedule__c.Collector_1__c or Route_Schedule__c.User__c will be populated depending on which is currently
     * null. If both are not null by time of update. and error will be received.
     */
    selectRouteSchedule(routeScheduleId) {
        let params = { userId: this._userId, routeScheduleId: routeScheduleId };
        //alert('@todo fire update with params '+JSON.stringify(params));
        doRouteScheduleSelection( params )
            .then(dto => {
                if (dto.isSuccess) {
                    uiHelper.showToast(this,'',dto.message,'success');
                    uiHelper.navigateToPageNoState(this,PAGE_HOME);
                } else {
                    console.error(' error in update' + JSON.stringify(dto));
                    uiHelper.showToast(this,'', dto.message, 'error');
                }
            })
            .catch(error => {
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'','Problem updating route schedule: '+this.error,'error');
                console.error(this.error);
            });
    }

    /**
     * Process the card menu option selected.
     * @param evt
     */
    handleCardMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        if(selectedItemValue == 'collapseall' || selectedItemValue == 'expandall') {
            uiHelper.processAccordionAll(this,selectedItemValue);
        }
    }

    /**
     * Handle the Assign to me button click / fire a confirmation modal.
     * @param evt
     */
    handleAssignToMe(evt) {
        evt.preventDefault();
        evt.stopPropagation();

        const rsId = evt.currentTarget.dataset.routescheduleid;
        const rsName = evt.currentTarget.dataset.routeschedulename;
        const payload = {routeScheduleId: rsId, action: 'assign'};
        this.dialogPayload = payload;
        this.confirmDisplayMessage = 'You have indicated that you wish to be assigned to ' + rsName + '.  Are you sure?';
        this.isDialogVisible = true;
        //this.selectRouteSchedule(rsId);
    }

    /**
     * Handle the Assign to me confirmation of the assign action.  if confirmed.
     * caLl selectRouteSchedule with selected route schedule id.
     * @param evt
     */
    handleAssignConfirmClick(evt) {
        if(evt.detail !== 1){
            this.confirmDisplayMessage = 'tst message'; // = 'Status: ' + evt.detail.status + '.';
            const detail = evt.detail.originalMessage;
            this.isDialogVisible = false;
            if(evt.detail.status === 'confirm') {
                if(detail.action){
                    if(detail.action == 'assign') {
                        if(detail.routeScheduleId) {
                            this.selectRouteSchedule(detail.routeScheduleId);
                        }
                    }
                }
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.isDialogVisible = false;
    }

    /**
     * Handle collapse / expand of a section.
     * @param evt
     */
    handleSectionClick(evt) {
        if(this._isAccordionProcessing) //  prevent double click
            return;
        let sectionTitleId = evt.currentTarget.dataset.sectiontitleid;
        uiHelper.processAccordion(this,sectionTitleId);
    }

    get showRouteScheduleData() {
        return this.routeSchedules;
    }

    get showNoDataMsg() {
        return !this._isLoading && !this.routeSchedules;
    }

    get showStencil() {
        return this._isLoading;
    }

    get showCardActions() {
        return this.cardActions && this.cardActions.length > 0;
    }

    get showPageHelp() {
        !this._isLoading && this._totalRps >= 1;
    }

    get displayRegionSelector() {
        return this.showRegionSelector;
    }

    get cardSubTitle() {
        let subTitle;
        if(this._numRouteSchedules) {
            subTitle = this._numRouteSchedules + ' routes today';
            if(this.regionSelected) {
                if(this.regionSelected !== this.allRegionsValue) {
                    subTitle += ' - '+this.regionSelected;
                } else {
                    subTitle += this.allRegionLabel;
                }
            }
        }
        return subTitle;
    }

    get cardActions() {
        let actions;
        if(this.showRouteScheduleData) {
            actions = [];
            let option1 = {id: 'expandall', label: 'Expand All', value: 'expandall', prefixIconName: 'utility:expand_all'};
            let option2 = {
                id: 'collapseall',
                label: 'Collapse All',
                value: 'collapseall',
                prefixIconName: 'utility:collapse_all'
            };
            actions.push(option1);
            actions.push(option2);
        }
        return actions;
    }

    get platformEventChannel() {
        return PLATFORM_EVENT_CHANNEL;
    }

    get helpMsg() {
        return lblWelcomeMsg;
    }

    /**
     * Fired from child component listener which is listening for Platform Events fired upon change of a route
     * schedule in regard to collector 1 / collector 2.
     * @param evt
     */
    handlePlatformEvent(evt) {
        if (evt.detail && evt.detail.data) {
            const payload = evt.detail.data.payload;
            if (payload && payload.Publishing_Process_Name__c === PE_PUBLISHER_CHECK_SCH_ASSIGNMENTS) {
                this.processAssignmentChange(payload);
            }
        }
    }

    /**
     * Roll through the modified route schedule ids and 'touch' the reactive array so that the view can be
     * refreshed to .. in this case. reflect a new assignment of a collector 1 / collector 2.
     *
     * @param payload  The payload received via CometD from the Platform Event.
     */
    processAssignmentChange(payload) {
        if(payload.Route_Schedule_Ids__c) {
            try {
                const idArray = payload.Route_Schedule_Ids__c.split(',');
                if (idArray && Array.isArray(idArray)) {
                    idArray.forEach(id => {
                        console.log(id);
                        //  @todo. find routeschedule tracked array and touch!
                    });
                }
            } catch (e) {
                console.error(e);
            }
        }
    }
}