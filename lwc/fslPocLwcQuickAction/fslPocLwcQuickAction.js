import {LightningElement, api, track,wire} from 'lwc';
import { getObjectInfos } from 'lightning/uiObjectInfoApi';
import FORM_FACTOR from "@salesforce/client/formFactor";
import WO_OBJECT from '@salesforce/schema/WorkOrder';
import SA_OBJECT from '@salesforce/schema/ServiceAppointment';
import CASE_OBJECT from '@salesforce/schema/Case';
import { getConstants } from 'c/clConstantUtil';
import Logger from 'c/logger';
import { uiHelper } from 'c/fslUiHelper';
import retrieveNotifications from '@salesforce/apex/FslPocQuickActionController.retrieveSaCustomNotifications';
import {NavigationMixin} from "lightning/navigation";
import {fireEvent} from 'c/pubSub';
import { CurrentPageReference } from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import USER_ID from '@salesforce/user/Id';
import {refreshApex} from "@salesforce/apex";

const GLOBAL_CONSTANTS = getConstants();
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';
const MAP_KEY_NOTIFICATION_WRAPS = 'NOTIFICATION_WRAPS';


export default class FslPocLwcQuickAction extends NavigationMixin(LightningElement)
{

    @api recordId;  // the service appointment id  (needs to be on service appointment page)
    @api headerTitlePlural = 'Notifications';
    @api headerTitleSingular = 'Notification';
    @api headerIcon = 'custom:custom28';
    @api customNotificationsApiName = 'None';
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @track notificationData;
    @track dtRecords;

    sObjectApiNames = [WO_OBJECT,SA_OBJECT,CASE_OBJECT];
    sObjectInfos;
    @wire(CurrentPageReference) pageRef;

    _wiredNotificationData;
    _debugConsole;
    _logger;
    _isLoading;
    _userIdSelected;
    _runningUserId = USER_ID;
    //_runningUserId;
    _formView = 'viewrecords';
    _lookupFocused;
    _lookupFieldFocused;
    _saIdSelected;
    _userFieldLevelHelp = 'Please select a user.'


    constructor() {
        super();
        console.info('%c----> /lwc/fslPocLwcQuickAction', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
    }

    connectedCallback() {
        this.debugConsole = true;
        //this.recordId = '08p1I0000028c0lQAA';  //use for testing outside of sa context
        if(!this.recordId) {
            //this.recordId = '08p1I0000028c0lQAA';
            this._isLoading = false;
        } else {
            this._saIdSelected = this.recordId;
            this._isLoading = true;
        }
        this._userIdSelected = this._runningUserId;
        uiHelper.log(this,DEBUG,'form factor',FORM_FACTOR);
    }
    handleInputFocused(evt) {
        uiHelper.log(this,DEBUG,'--> parent handle lookup focused detail',evt.detail);
        this._lookupFocused = true;
        this._lookupFieldFocused = evt.detail.customId;
    }
    handleInputFocusedOut(evt) {
        uiHelper.log(this,DEBUG,'handle lookup focused out');
        this._lookupFocused = false;
        this._lookupFieldFocused = null;
    }
    get showOtherFormFields() {
        return !this._lookupFieldFocused;
    }

    get showUserLookup() {
        return !this._lookupFieldFocused || this._lookupFieldFocused === 'userLookup';
    }

    get showSaLookup() {
        return !this._lookupFieldFocused || this._lookupFieldFocused === 'saLookup';
    }

    /**
     * Retrieves custom_notification_sent__c records for the service appointment in context.
     * @param wiredData
     */
    @wire(retrieveNotifications, {saId:'$recordId'})
    notificationsHandler(wiredData) {
        this._wiredNotificationData = wiredData;
        const {data,error} = wiredData;
        if(data) {
            this.notificationData = uiHelper.getMapValue(MAP_KEY_NOTIFICATION_WRAPS,data.values);
            this.dtRecords = this.notificationData;
            uiHelper.log(this,DEBUG,'notification wraps',this.notificationData);
            this._isLoading = false;
        }
        if(error) {
            this.handleError(error);
            this._isLoading = false;
        }
    }

    /**
     * Let's key ui info about key Service Objects.
     * @param data
     * @param error
     */
    @wire(getObjectInfos, {objectApiNames:'$sObjectApiNames'})
    getObjectHandler({data,error}) {
        if(data) {
            this.objectInfosCallback(data);
        }
        if(error) {
            this.handleError(error);
        }
    }

    /**
     * Just demos some functions in uiHelper not pertinent.
     * @param results
     */
    objectInfosCallback(results) {
       this.sObjectInfos = results;
       uiHelper.log(this,DEBUG,'sObjectInfos',this.sObjectInfos);
       const caseObjectInfo = uiHelper.findObjectInfo(CASE_OBJECT.objectApiName,this.sObjectInfos);
       uiHelper.log(this,DEBUG,'case stuff',caseObjectInfo);
       const callCenterRtId = uiHelper.findRecordTypeId(caseObjectInfo.result.recordTypeInfos,'Call Center');
       uiHelper.log(this,DEBUG,'rt id for call center ',callCenterRtId);
    }


    handleTileRowAction(evt) {
        const recordId = evt.target.dataset.recordid;
        if(recordId && this.isFslMobile) {
            uiHelper.navigateToFslRecordView(this, recordId);
        }
    }

    /**
     * @param event
     */
    fireOuterContainerClick(event) {
        uiHelper.log(this,DEBUG,'fire eventOuterContainerClick');
        fireEvent(this.pageRef, 'eventOuterContainerClicked', 'outercontainerclick');
    }

    handleFormSubmit(evt) {
        uiHelper.log(this,DEBUG,'handle form submit 1: ');
        evt.preventDefault();
        uiHelper.log(this,DEBUG,'handle form submit 2: ');
        const fields = evt.detail.fields;

        uiHelper.log(this,DEBUG,'handle form submit 3: ');
        fields.Service_Appointment__c = this.recordId;
        fields.Custom_Notification_Api_Name__c = this.customNotificationsApiName;
        fields.User__c = this._userIdSelected;
        fields.Service_Appointment__c = this._saIdSelected;

        uiHelper.log(this,DEBUG,'handle form submit 4:  fields=',fields);
        if(fields.User__c) {
            this._isLoading = true;
            uiHelper.log(this,DEBUG,'handle form submit 5: ');
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
    }
    handleRecordSelected(evt) {
        let recordSelected = evt.detail.value;
        uiHelper.log(this,DEBUG,'--> parent handle recordSelected',recordSelected);
        if(recordSelected) {
            if(recordSelected.customId === 'userLookup') {
                if(recordSelected.recordClicked) {
                    this._userIdSelected = recordSelected.recordClicked.id;
                } else {
                    this._userIdSelected = null;
                }
                uiHelper.log(this,DEBUG,'--> user lookup val set to ',this._userIdSelected);
            } else if (recordSelected.customId === 'saLookup') {
                if(recordSelected.recordClicked) {
                    this._saIdSelected = recordSelected.recordClicked.id;
                    this.recordId = this._saIdSelected;
                } else {
                    this._saIdSelected = null;
                    this.recordId = null;
                }
                uiHelper.log(this,DEBUG,'--> sa lookup val set to ',this._saIdSelected);
            }
        }

    }
    handleFormLoad(evt) {

    }
    handleFormError(evt) {
        this._isLoading = false;
        uiHelper.log(this,ERROR,'error',evt.detail)
    }

    handlePageAction(evt) {
        if (evt && evt.currentTarget && evt.currentTarget.dataset) {
            const buttonId = evt.currentTarget.dataset.id;
            switch (buttonId) {
                case 'btnCreateNew':
                    this._formView = 'createnew';
                    break;
            }
            switch (buttonId) {
                case 'btnSave':
                   // this._formView = 'createnew';
                    break;
            }
        }
    }

    handleError(error) {
        console.error(error);
    }
    handleBackClick(evt) {
        evt.preventDefault();
        evt.stopPropagation();
        this._formView = 'viewrecords';
    }
    handleFormSuccess(evt) {
        this._isLoading = false;
        const fields = evt.detail.fields;
        uiHelper.log(this,DEBUG,'fields onsuccess',fields);
        this._formView = 'viewrecords';
        if(!this.isFslMobile) {
            let toastEvt;
            toastEvt = new ShowToastEvent({
                title: '',
                message: 'Record Created!',
                variant: 'success'
            });
            this.dispatchEvent(toastEvt);
        }
        refreshApex(this._wiredNotificationData);
    }

    get headerDynaTitle() {
        let title = '';
        if(this._formView === 'createnew') {
            title += 'Create '+this.headerTitleSingular;
        } else {
            title += 'View '+this.headerTitlePlural;
        }
        return title;
    }

    get noRecordsHeaderText() {
        return 'No '+this.headerTitlePlural + ' Found.'
    }
    get noRecordsBodyText() {
        return 'Could not find any '+this.headerTitlePlural + ' for the current service appointment.';
    }

    get showDatatable() {
        return this.dtRecords;
    }

    get showNoData() {
        return !this._isLoading && (!this.dtRecords || this.dtRecords.length < 1) && this.showRecords;
    }

    get showStencil() {
        return this._isLoading;
    }

    get showRecords() {
        return this._formView === 'viewrecords';
    }

    get showCreateNewBtn() {
        return this.showRecords;
    }
    get showSaveBtn() {
        return this.showForm;
    }
    get showBackBtn() {
        return this.showSaveBtn;
    }
    get otherFormFieldsCssClass() {
        return this.showOtherFormFields ? 'slds-show' : 'slds-hide';
    }
    get userLookupCssClass() {
        return this.showUserLookup ? 'slds-show' : 'slds-hide';
    }
    get saLookupCssClass() {
        return this.showSaLookup ? 'slds-show' : 'slds-hide ';
    }
    /**
     * @todo need something better than this!
     * @returns {boolean}
     */
    get isFslMobile() {
        return FORM_FACTOR === 'Small';
    }

    get showForm() {
        return !this._isLoading && this._formView === 'createnew';
    }

    get showStaticHeader() {
        return !this._lookupFocused;
    }
}