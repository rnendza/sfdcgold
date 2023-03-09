import {LightningElement, api, wire, track} from 'lwc';
import {themeOverrider} from './clRouteScheduleAdminOnlyThemeOverrides'
import stencil from './clRouteScheduleAdminOnlyStencil.html';
import mainTemplate from './clRouteScheduleAdminOnly.html';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {getRecord, getFieldValue, getRecordNotifyChange} from 'lightning/uiRecordApi';
import TOTAL_RPS_RECS_FIELD from '@salesforce/schema/Route_Schedule__c.Total_Processing_Sheets__c'
import TOTAL_METER_READINGS_FIELD from '@salesforce/schema/Route_Schedule__c.Total_Meter_Readings__c'
import TOTAL_ACCOUNTS_FIELD from '@salesforce/schema/Route_Schedule__c.Total_Accounts__c';
import RPS_NAME from '@salesforce/schema/Route_Schedule__c.Name';
import COLLECTOR1_FIELD from '@salesforce/schema/Route_Schedule__c.Collector_1__c';
import COLLECTOR2_FIELD from '@salesforce/schema/Route_Schedule__c.User__c';
import ASSIGNED_DRIVER_FIELD from '@salesforce/schema/Route_Schedule__c.Assigned_Driver__c';
import ROUTE_COLLECTION_DATE_FIELD from '@salesforce/schema/Route_Schedule__c.Route_Collection_Date__c';
import ROUTE_FILL_DATE_FIELD from '@salesforce/schema/Route_Schedule__c.Route_Fill_Date__c';
import REGION_FIELD from '@salesforce/schema/Route_Schedule__c.Processing_Location__c';
import deleteRpsData from '@salesforce/apex/clRouteProcessingSheetsController.deleteRpsAndMeters';
import deleteMetersData from '@salesforce/apex/clRouteProcessingSheetsController.deleteMeters';
import createRpsData from '@salesforce/apex/clRouteProcessingSheetsController.createRpsAndMeters';
import createRsData from '@salesforce/apex/clRouteProcessingSheetsController.createRouteSchedules';
import retrieveRouteData from '@salesforce/apex/clRouteSchAdminOnly.retrieveRoutes';
import cloneRoute from '@salesforce/apex/clRouteSchAdminOnly.cloneRoute';
import updateNextCycleNumber from '@salesforce/apex/clRouteProcessingSheetsController.updateNextCycleNumber';
import retrieveMdt   from '@salesforce/apex/clRouteProcessingSheetsController.retrieveMdt';
import {refreshApex} from "@salesforce/apex";
import {reduceErrors} from 'c/ldsUtils';
import AccelUtilsSvc from 'c/accelUtilsSvc';



const  RPS_FIELDS = [
    TOTAL_RPS_RECS_FIELD,TOTAL_ACCOUNTS_FIELD,RPS_NAME,TOTAL_METER_READINGS_FIELD,
    COLLECTOR1_FIELD,COLLECTOR2_FIELD,ASSIGNED_DRIVER_FIELD,ROUTE_COLLECTION_DATE_FIELD,ROUTE_FILL_DATE_FIELD,
    REGION_FIELD
];
const  MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const  MAP_KEY_ROUTES = 'ROUTE_DATA';
const  MAP_KEY_ROUTE = 'ROUTE';
const  SCHEDULE_MDT_DEV_NAME = 'Scheduler';
const  DEFAULT_REGION = 'Burr Ridge';

import {NavigationMixin} from "lightning/navigation";

export default class ClRouteScheduleAdminOnly extends NavigationMixin(LightningElement) {

    @api recordId;

    error = {};
    _wiredRoutes;
    _wiredRps;
    _wiredScheduleMdt;
    _hasRendered;
    _hasOverrodeSfdcCss;
    _isLoading = true;
    _isBatchJobRunning = false;
    _totalNumberRpsRecords = 0;
    _totalNumberOfAccounts = 0;
    _totalMeterReadings = 0;
    _collector1;
    _collector2;
    _assignedDriver;
    _region = DEFAULT_REGION;
    _fillDate;
    _collectionDate;
    _processingLocation = 'Burr Ridge';
    _routeCycleNumber = 0;
    _scheduleMdtDevName = SCHEDULE_MDT_DEV_NAME;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _activeTabValue = 'tab_rps';
    _activeSubTabValue = '';
    _selectedRouteId;
    _newRouteName = '';
    _isUpdating = false;
    _showRouteLink = true;


    @track routeOptions;
    @track route;
    @track routeData;
    @track isDialogVisible = false;
    @track originalMessage;
    @track displayMessage = 'Are you sure you wish to delete all rps and meters data?';
    @track scheduleMdt;
    @track scheduleNextCycle;
    @track rpsName;

    constructor() {
        super();
    }

    render() {
        return this._isLoading || this._isUpdating ? stencil : mainTemplate;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
        }
        this.overrideThemes();
    }

    createRpsAndMeters(recordId,region) {
        let params = {routeScheduleId: recordId, region : region};
        createRpsData( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                this.showToast('',dto.message, dto.severity);
            })
            .catch( error => {
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
                this.showToast('',dto.message, dto.severity);
            })
            .catch( error => {
                this._isLoading = false;
                this.error = reduceErrors(error);
                this.showToast('','Problem firing job to create route schedule data: '+this.error,'error');
                console.error(this.error);
            });
    }

    deleteRpsAndMeters(recordId) {
        let params = {routeScheduleId: recordId};
        this._isLoading = true;
        deleteRpsData( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    refreshApex(this._wiredRps);
                    getRecordNotifyChange([{recordId: this.recordId}]);
                } else {

                }
                this.showToast('',dto.message, dto.severity);
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this._isLoading = false;
                this.showToast('','Problem deleting rps data: '+this.error,'error');
                console.error(this.error);
            });
    }

    deleteMeters(recordId) {
        let params = {routeScheduleId: recordId};
        this._isLoading = true;
        deleteMetersData( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    refreshApex(this._wiredRps);
                    getRecordNotifyChange([{recordId: this.recordId}]);
                } else {

                }
                this.showToast('',dto.message, dto.severity);
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this._isLoading = false;
                this.showToast('','Problem deleting meters data: '+this.error,'error');
                console.error(this.error);
            });
    }

    get tomorrowsDateFormatted() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate() + 1);
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        let yyyyMmDd = rightNow.toISOString().slice(0,10);
        return yyyyMmDd;
    }

    updateCycleNumber( nextCycleNumber) {
        let params = {nextCycleNumber: nextCycleNumber};

        updateNextCycleNumber( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    refreshApex(this._wiredRps);
                    getRecordNotifyChange([{recordId: this.recordId}]);
                } else {

                }
                this.showToast('',dto.message, dto.severity);
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this._isLoading = false;
                this.showToast('','Problem firing job to update next cycle number: '+this.error,'error');
                console.error(this.error);
            });
    }

    cloneTheRoute() {

        let params = {
            oldRouteId: this._selectedRouteId,
            newRouteName: this._newRouteName,
            iRouteCycleNumber: Number(this._routeCycleNumber),
            processingLocation: this._processingLocation
        };
        console.log('---> calling cloneRoute with params:',params);
        // Id oldRouteId, String newRouteName,
        //     Integer iRouteCycleNumber,String processingLocation, Date collectionDate)

        cloneRoute( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    this.showToast('',dto.message,'success');
                    refreshApex(this._wiredRoutes);
                    this.route = this._accelUtils.getMapValue(MAP_KEY_ROUTE, dto.values);
                    this._newRouteName = null;
                    this._selectedRouteId = null;
                    this._routeCycleNumber = 0;
                } else {
                    this.showToast('','Problem cloning the route: '+dto.message,'error');
                }
                this._isUpdating = false;
                this.showToast('',dto.message, dto.severity);
            })
            .catch( error => {
                console.log('raw error',error);
                this.error = reduceErrors(error);
                this._isLoading = false;
                this._isUpdating = false;
                this.showToast('','Error cloning the route: '+this.error,'error');
                console.error(this.error);
            });
    }

    @wire(getRecord, { recordId: '$recordId', fields: RPS_FIELDS })
    wiredRecord(wiredData) {
        this._wiredRps = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this._isLoading = false;
        } else if (data) {
            this._isLoading = false;
            this._totalNumberRpsRecords = getFieldValue(data,TOTAL_RPS_RECS_FIELD);
            this._totalNumberOfAccounts = getFieldValue(data,TOTAL_ACCOUNTS_FIELD);
            this._totalMeterReadings    = getFieldValue(data,TOTAL_METER_READINGS_FIELD);
            this._collector1            = getFieldValue(data,COLLECTOR1_FIELD);
            this._collector2            = getFieldValue(data,COLLECTOR2_FIELD);
            this._assignedDriver        = getFieldValue(data,ASSIGNED_DRIVER_FIELD);
            this._collectionDate        = getFieldValue(data,ROUTE_COLLECTION_DATE_FIELD);
            this._fillDate              = getFieldValue(data,ROUTE_FILL_DATE_FIELD);
            this._region                = getFieldValue(data,REGION_FIELD);
            this.rpsName                = getFieldValue(data,RPS_NAME);
        }
    }

    @wire(retrieveMdt, { mdtDevName: '$_scheduleMdtDevName' })
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

    @wire(retrieveRouteData)
    wiredRouteData(wiredData) {
        this._wiredRoutes = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            this.showToast('', 'Problem getting routes: ' + this.error, 'error');
            console.error(this.error);
        } else if (data) {
            if(data.isSuccess) {
                this.routeData = this._accelUtils.getMapValue(MAP_KEY_ROUTES, data.values);
                this.buildRoutePlOptions(this.routeData,this._selectedRouteId);
            } else {
                this.showToast('',data.message,'error');
            }
        }
    }
    get showNoCollectorInfo() {
        let showIt = false;
        showIt = this._totalNumberRpsRecords < 1 && this._totalNumberOfAccounts > 0;
        if(showIt) {
            showIt = this.checkNoCollectorInfo();
        }
        return showIt;
    }
    get showRpsCreateButton() {
        return this._totalNumberRpsRecords < 1 && this._totalNumberOfAccounts > 0;
    }
    get showNoAccountsMessage() {
        return !this._totalNumberOfAccounts || this._totalNumberOfAccounts < 1;
    }
    get showRpsDeleteButton() {
        return this._totalNumberRpsRecords > 0;
    }

    get showMetersDeleteButton() {
        return this._totalMeterReadings > 0;
    }

    get showDeleteTab() {
        return this.showMetersDeleteButton || this.showRpsDeleteButton;
    }

    get showExistingRpsInfo() {
        return !this.showRpsCreateButton && !this.showNoAccountsMessage;
    }

    get showCycleNumberForm() {
        return this.scheduleMdt;
    }

    checkNoCollectorInfo() {
        return !this._collector1 && !this._collector2 && !this._assignedDriver;
    }

    handleRsCreateClick() {
        this._isBatchJobRunning = true;
        this.createRs(this.scheduleNextCycle, this._routeCollectionDate);
    }

    handleRpsCreateClick() {
        this._isBatchJobRunning = true;
        this.createRpsAndMeters(this.recordId,this._region);
    }

    handleScheduleNumberChange(evt) {
        this._showRouteLink = false;
        this.scheduleNextCycle = evt.target.value;
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
    handleRouteSelected(evt) {
        this._showRouteLink = false;
        this._selectedRouteId = evt.target.value;

    }
    handleScheduleMdtUpdateClick(evt) {
        this._isBatchJobRunning = true;
        this.updateCycleNumber(this.scheduleNextCycle);
    }

    handleRouteCloneClick(evt) {
        if(!this._selectedRouteId) {
            this.showToast('','Please select a route to clone.','error');
            return;
        }
        if(!this._newRouteName) {
            this.showToast('','Please enter a new name for the route.','error');
            return;
        }
        if(!this._routeCycleNumber || this._routeCycleNumber === 0) {
            this.showToast('','Please enter a new route cycle #.','error');
            return;
        }
        if(!this._routeCollectionDate || this._routeCollectionDate === 0) {
            this.showToast('','Please enter a route collection date.','error');
            return;
        }
        this.cloneTheRoute();
    }

    handleDeleteConfirmClick(evt) {
        if(evt.detail !== 1){
            this.displayMessage = 'Status: ' + evt.detail.status + '.';
            const detail = evt.detail.originalMessage;
            this.isDialogVisible = false;
            if(evt.detail.status === 'confirm') {
                if(detail.action){
                    if(detail.action == 'rpsdelete') {
                        this.deleteRpsAndMeters(this.recordId);
                    } else if (detail.action == 'metersdelete') {
                        this.deleteMeters(this.recordId);
                    }
                }
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.isDialogVisible = false;
    }

    handleBatchJobCompleted(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
        }
        this._isBatchJobRunning = false;
    }

    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
    }

    handleSubTabClick(evt) {
        this._activeSubTabValue = evt.target.value;
    }

    handleRpsDeleteClick() {
        const payload = {routeScheduleId:  this.recordId, action: 'rpsdelete' };
        this.originalMessage = payload;
        this.displayMessage = 'Are you sure you wish to delete all rps and meters data?';
        this.isDialogVisible = true;
    }

    handleMetersDeleteClick() {
        const payload = {routeScheduleId:  this.recordId, action: 'metersdelete' };
        this.originalMessage = payload;
        this.displayMessage = 'Are you sure you wish to delete all meters data?';
        this.isDialogVisible = true;
    }
    handleNavToListView(evt) {
        this.navigateToListView();
    }
    handleRouteNavToRecordView(evt) {
        this.navigateToRecordView('Route__c',)
    }

    navigateToListView() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Route_Schedule__c',
                actionName: 'list'
            },
            state: {
                filterName: 'All'
            }
        });
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

    overrideThemes() {
        if(!this._hasOverrodeSfdcCss) {
            this.buildSfdcCoreOverrideCss();
        }
    }

    buildSfdcCoreOverrideCss() {
        themeOverrider.buildSfdcCoreOverrideCss(this);
    }

    buildRoutePlOptions( routes, selectedRouteId ) {

        if(routes && Array.isArray(routes)) {

            this.routeOptions = [];
            this.routeOptions.push({value: -1, label: 'Select a route', selected:true});
            routes.forEach(x =>  {
                let optionSelected = false;
                if(this.selectedRouteId) {
                    optionSelected = x === this.selectedRouteId;
                }
                let label = x.routeName + ' ('+x.totalAccounts+')';
                let option = {value: x.routeId, label:label, selected:optionSelected };
                this.routeOptions.push(option);
            });
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