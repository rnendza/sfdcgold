import {LightningElement, api, wire, track} from 'lwc';
import stencil from './clAdminRouteCloneStencil.html';
import mainTemplate from './clAdminRouteClone.html';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import cloneRoute from '@salesforce/apex/clRouteSchAdminOnly.cloneRoute';
import retrieveRouteData from '@salesforce/apex/clRouteSchAdminOnly.retrieveRoutes';
import {refreshApex} from "@salesforce/apex";
import {reduceErrors} from 'c/ldsUtils';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {themeOverrider} from 'c/clAdminOnlyCardTheme';
import {NavigationMixin} from "lightning/navigation";
// import {animationHelper} from "../clMeterReadings/clMeterReadingsAnimation";

const  MAP_KEY_ROUTES = 'ROUTE_DATA';
const  MAP_KEY_ROUTE = 'ROUTE';
const  RESULT_MSG_TEXT_DISPLAY_TIME = 10000;
const  MIN_CARD_HEIGHT = '33em';

export default class ClAdminRouteClone extends NavigationMixin(LightningElement) {

    @track routeOptions;
    @track routeData;
    @track route;
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
    _minCardHeight = MIN_CARD_HEIGHT;
    _wiredRoutes;
    _wiredScheduleMdt;
    _isLoading = false;
    _isUpdating = false;
    _isBatchJobRunning = false;
    _routeCycleNumber;
    _hasRendered = false;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _newRouteName;
    _selectedRouteId;
    _showRouteLink = false;
    _routeCycleNumber;
    _activeTabValue = 'tab_rtclone'
    _processingLocation = 'Burr Ridge';
    error = {};

    constructor() {
        super();
    }

    render() {
        return mainTemplate;
    }
    connectedCallback() {
        this._isLoading = true;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            themeOverrider.buildAdminCardOverrideCss(this);
        }
    }


    @wire(retrieveRouteData)
    wiredRouteData(wiredData) {
        this._wiredRoutes = wiredData;
        const { data, error } = wiredData;
        this._isLoading = false;
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

    cloneTheRoute() {

        let params = {
            oldRouteId: this._selectedRouteId,
            newRouteName: this._newRouteName,
            iRouteCycleNumber: Number(this._routeCycleNumber),
            processingLocation: this._processingLocation
        };
        console.log('---> calling cloneRoute with params:',params);
        this._isUpdating = true;
        cloneRoute( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                this._isUpdating = false;
                if (dto.isSuccess) {

                    this.showToast('',dto.message,'success');
                    // this.scopedMsg.message = dto.message;
                    // this.scopedMsg.theme = 'success';
                    // this.scopedMsg.iconVariant = 'inverse';
                    // setTimeout(() => { this.scopedMsg.reset()},RESULT_MSG_TEXT_DISPLAY_TIME);
                    refreshApex(this._wiredRoutes);
                    this.route = this._accelUtils.getMapValue(MAP_KEY_ROUTE, dto.values);
                    console.log('----> route = ',JSON.stringify(this.route));
                    this._showRouteLink = true;
                    this.resetForm();
                    this.buildRoutePlOptions(this.routeData,this._selectedRouteId);
                } else {
                    this.showToast('','Problem cloning the route: '+dto.message,'error');
                }
                //this.showToast('',dto.message, dto.severity);

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
        this.cloneTheRoute();
    }
    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
    }
    handleMenuSelect(evt) {
        // retrieve the selected item's value
        const selectedItemValue = evt.detail.value;
    }
    handleNewRouteNameChange(evt) {
        this._showRouteLink = false;
        this._newRouteName = evt.target.value;
    }

    handleRouteCycleNumberChange(evt) {
        this._showRouteLink = false;
        this._routeCycleNumber = evt.target.value;
    }
    handleRouteNavToRecordView(evt) {
        this.navigateToRecordView('Route__c',this.route.routeId)
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
    buildRoutePlOptions( routes, selectedRouteId ) {

        if(routes && Array.isArray(routes)) {

            this.routeOptions = [];
            this.routeOptions.push({value: -1, label: 'Select a route to clone', selected:true});
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
    get cardTitleStyle() {
        return themeOverrider.getCardTitleStyle(this);
    }

    handleRouteSelected(evt) {
        this._showRouteLink = false;
        this._selectedRouteId = evt.target.value;

    }
    get showRouteCloneButton () {
        return !this._isUpdating;
    }
    resetForm() {
        this._selectedRouteId = null;
        this._newRouteName = null;
        this._routeCycleNumber = null;
    }

    get showRouteSelectOptions() {
        return this.routeOptions;
    }
    get showScopedMsg() {
        return this.scopedMsg && this.scopedMsg.message && this.scopedMsg.message != '';
    }
    get todaysDateFormatted() {
        let rightNow = new Date();
        rightNow.setDate(rightNow.getDate());
        rightNow.setMinutes(new Date().getMinutes() - new Date().getTimezoneOffset());
        let yyyyMmDd = rightNow.toISOString().slice(0,10);
        return yyyyMmDd;
    }
    get cardOptions() {
        let options;
        // options = [
        //     {
        //         id: 'collapseall',
        //         label: 'Collapse card',
        //         value: 'collapseall',
        //     },
        //     {
        //         id: 'expandall',
        //         label: 'Expand card',
        //         value: 'expandall',
        //     },
        // ];
        return options;
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