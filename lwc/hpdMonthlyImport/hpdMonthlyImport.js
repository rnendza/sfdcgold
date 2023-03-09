import {LightningElement, track, api, wire} from 'lwc';
import Id from '@salesforce/user/Id';
import fireBatchTransferHpdMonthlies from '@salesforce/apex/BatchUiController.fireBatchTransferHpdMonthlies';
import retrieveUserDetails from '@salesforce/apex/BatchUiController.retrieveUserDetails';
import userSearch from '@salesforce/apex/LookupUserController.search';
import Logger from "c/logger";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {CurrentPageReference} from "lightning/navigation";
import { NavigationMixin } from 'lightning/navigation';

import {fireEvent} from 'c/pubSub';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';


export default class HpdMonthlyImport extends NavigationMixin(LightningElement) {

    @api notifyViaAlerts = false;

    @track isMultiEntry = false;
    @track initialSelection = [
        {
            id: 'na',
            sObjectType: 'na',
            icon: 'standard:lightning_component',
            title: 'Initial selection',
            subtitle: 'Not a valid record'
        }
    ];
    @track errors = [];

    @track contactAccounts;
    @track apexClassNames = [];
    @track displayBatchStatus = false;
    @track displayExecuteForm = true;
    @track rowOffset = 0;
    @track isProcessing = false;
    @track commitTrans = false;
    @track chainBatchJobs = false;
    @track batchSize = 20;
    @track statusRefreshInterval = 1;
    @track targetAccountSelected;
    @track sourceAccountSelected;
    @track userSelected;
    @track jobParams = {};
    @track activeTabValue = 'Execute';
    @track batchId;
    @track asyncJobName;
    @track recipientEmailUserId;
    @track defaultRecipientEmailUser;
    @track defaultUserIdSelected = null;
    @track fullUserSelected;
    @track showAdvancedOptions = false;
    @track userWasSelected = false;
    @track allValid = false;
    @track batchJobTriggered = false;
    @track triggerFirstInputFocus = false;
    @track completedAccountId;
    @track showCompletedData = false;
    @track helpFile;
    @track contentDocumentId ='06911000001OQ5d';

    //  General Utility / Logging stuff
    _hasRendered    = false;
    _debugConsole   = true;
    _className      = 'ContactAccountDisplay';
    _logger         = new Logger(this._debugConsole);
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);
    _inputStyle;
    _userId;
    _defaultRecipientUserName = '';
    _userIdSelected;
    _advancedOptionsColClass = 'slds-col slds-size--1-of-1 slds-medium-size--3-of-8 slds-large-size--3-of-8 slds-p-top--small';
    _toggleContainerClass = 'slds-col slds-size--1-of-1 slds-medium-size--5-of-8 slds-large-size--5-of-8 slds-p-top--small';
    _basicOptionsColClass = 'slds-col slds-size--1-of-1 slds-medium-size--1-of-1 slds-large-size--1-of-1 slds-p-top--small';


    @wire(CurrentPageReference) pageRef;

    constructor() {
        super();
        this.buildInputOverrideCss();
    }
    renderedCallback() {
        if (!this._hasRendered) {
            this.isMultiEntry = true;
            this._hasRendered = true;
            this.chainBatchJobs = true;
            this.commitTrans = true;
            this.displayBatchStatus = true;
            let eleCommitToggle  = this.template.querySelector('[data-id="commitToggle"]');
            if(eleCommitToggle) {
                eleCommitToggle.checked = this.commitTrans;
            }
            this.buildSecondaryTabOverrideCss();
        }
    }
    connectedCallback() {
        this._userId = Id;
    }

    // fireBatchTransferHpdMonthliesJob() {
    //     this.isProcessing = true;
    //     this.recipientEmailUserId = null;
    //     if(this.userSelected) {
    //         this.recipientEmailUserId = this.userSelected.id;
    //     }
    //     let params = {
    //         batchSize: this.batchSize,
    //         sourceAcctId: this.sourceAccountSelected.id,
    //         targetAcctId: this.targetAccountSelected.id,
    //         recipientEmailUserId : this.recipientEmailUserId,
    //         commitTrans: this.commitTrans,
    //         chainJobs: this.chainBatchJobs
    //     };
    //     this.jobParams = null;
    //     this.jobParams = Object.assign({},params);
    //     this.jobParams.statusRefreshInterval = this.statusRefreshInterval;
    //     this.log('info','firing batch job with params:'+JSON.stringify(params));
    //     fireBatchTransferHpdMonthlies(params)
    //         .then(result => {
    //             let dto = result;
    //             this.isProcessing = false;
    //             if(dto.isSuccess) {
    //                 this.activeTabValue = 'Job Status';
    //                 this.apexClassNames.push('BatchTransferHpdMonthlies','BatchTransferHpdMonthlyAcctLookups','BatchTransferHpdTotalMonthlyAcctLookups');
    //                 this.template.querySelector('lightning-tabset').activeTabValue = 'Job Status';
    //                 this.displayExecuteForm = false;
    //                 this.batchId = (this._accelUtils.getMapValue('batchId', dto.values));
    //                 this.asyncJobName = (this._accelUtils.getMapValue('async_job_name',dto.values));
    //
    //                 let msg = 'Job Id: '+this.batchId + ' successfully submitted. ';
    //                 let childCmp = this.template.querySelector("c-batch-jobs-status");
    //                 if(childCmp) {
    //                     childCmp.handleBatchJobTriggered();
    //                 }
    //                 this.dispatchEvent(
    //                     new ShowToastEvent({
    //                         title: 'Success',
    //                         message: msg,
    //                         variant: 'success',
    //                     }),
    //                 );
    //             }
    //         })
    //         .catch(error => {
    //             this.isProcessing = false;
    //             console.error(JSON.stringify(error));
    //             this.dispatchEvent(
    //                 new ShowToastEvent({
    //                     title: 'Error while updating record',
    //                     message: error.message,
    //                     variant: 'error',
    //                 }),
    //             );
    //         });
    // }

    @api
    get defaultUserName() { return this._defaultRecipientUserName; }
    set defaultUserName(val) {
        if (val) {
            this._defaultRecipientUserName = val;
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
            this.defaultRecipientEmailUser = data;
            if(this.defaultRecipientEmailUser) {
                this.defaultUserName = this.defaultRecipientEmailUser.Name;
                this.defaultUserIdSelected = this.defaultRecipientEmailUser.Id;
            }
        } else if (error) {
            //this.error = error;
        }
    }
    /**
     * Get full user details (as opposed to just userId, in case it's needed)
     * @param error
     * @param data
     */
    @wire(retrieveUserDetails, { userId: '$_userIdSelected' })
    wiredSelectedUserDetails({ error, data }) {
        if (data) {
            this.fullUserSelected = data;
        } else if (error) {
            //this.error = error;
        }
    }
    handleSearch(event) {
        userSearch(event.detail)
            .then(results => {
                this.template
                    .querySelector('c-lookup')
                    .setSearchResults(results);
            })
            .catch(error => {
                this.notifyUser(
                    'Lookup Error',
                    'An error occured while searching with the lookup field.',
                    'error'
                );
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.errors = [error];
            });
    }
    handleLookupTypeChange(event) {
        this.initialSelection = [];
        this.errors = [];
        this.isMultiEntry = event.target.checked;
    }
    handleSelectionChange() {
        this.errors = [];
    }

    checkForErrors() {
        const selection = this.template
            .querySelector('c-lookup')
            .getSelection();
        if (selection.length === 0) {
            this.errors = [
                { message: 'You must make a selection before submitting!' },
                { message: 'Please make a selection and try again.' }
            ];
        } else {
            this.errors = [];
        }
    }
    handleUserEmailSelected(event) {
        let record = event.detail.value;
        if(record && record.id) {
            this.userWasSelected = true;
            this.userSelected = record;
            this._userIdSelected = record.id;
        } else {
            this.userWasSelected = false;
        }
        this.checkFormValidity();
    }
    handleCommitToggleChange(event) {
        this.commitTrans = event.target.checked;
    }
    handleChainToggleChange(event) {
        this.chainBatchJobs = event.target.checked;
    }
    handleExecute(event) {
        event.preventDefault();
        this.checkFormValidity();
        if(this.allValid) {
            // this.isProcessing = true;
            // this.batchJobTriggered = true;
            // this.fireBatchTransferHpdMonthliesJob();
        } else {
            let msg = 'One or more required fields have not been entered.';
            this.showToast('Error',msg,'error');
            console.error('something not valid '+msg);
        }

    }
    checkFormValidity() {
        let _self = this;
        const allInputs = this.template.querySelectorAll("lightning-input");
        if(!this.sourceAccountSelected || !this.targetAccountSelected || !this.userSelected) {
            this.allValid = false;
        } else {
            this.allValid = true;
        }
        allInputs.forEach(function(ele){
            if(!ele.checkValidity()) {
                ele.reportValidity();
                _self.allValid = false;
            }
        });
    }
    handleSliderChangeRefreshInterval(event) {
        this.statusRefreshInterval = event.target.value;
    }
    handleSliderChangeBatchSize(event) {
        this.batchSize = event.target.value;
    }
    handleTabSelect(event) {
        let tab = event.target.label;
        this.triggerFirstInputFocus = tab === 'Execute';
    }
    @api
    get userEmailWhereCriteria() {
        let whereCriteria = ' ( Profile.Name =  \'System Administrator\' OR Profile.Name = \'Accel Super User\' )';
        return whereCriteria;
    }
    @api
    get userEmailInputLabel() {
        let label ='<span class="fa-stack" style="font-size:.75em">' +
            '    <span class="far fa-circle fa-stack-2x"></span>' +
            '    <strong class="fa-stack-1x">' +
            '        3' +
            '    </strong>' +
            '</span>'
        label += '<span class="slds-p-left_xxx-small">Select a user to email results to</span>';
        return label;
    }
    @api
    get rowCount() {
        let count = 0;
        if(this.contactAccounts && Array.isArray(this.contactAccounts)) {
            count = this.contactAccounts.length;
        }
        return count;
    }
    @api
    get commitToggleLabel() {
        let label ='';
        label += '<span class="slds-p-left_xxx-small">Commit all changes when complete?</span>';
        return label;
    }
    @api
    get autocompleteContainerClass() {
        return this.showAdvancedOptions ? this._advancedOptionsColClass : this._basicOptionsColClass;
    }
    navigateToHelpVideo() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                selectedRecordId:this.contentDocumentId
            }
        })
    }
    handleAllJobsCompleted(event) {
        this.showCompletedData = true;
        this.completedAccountId = this.targetAccountSelected.id;
    }
    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts) {
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
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
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
    buildSecondaryTabOverrideCss() {
        let css = '.accel-secondary-tab-set .slds-tabs_default__nav {font-size:.875rem}';
        const style = document.createElement('style');
        style.innerText = css;
        let target = this.template.querySelector('.tab-theme-overrides-class');
        target.appendChild(style);
    }
    buildInputOverrideCss() {
        let css = '@media only screen and (min-width: 768px) {';
        css += '.c3llc-autocomplete-container .slds-input { background-color: rgb(255, 255, 255);width: 100%;display: inline-block;height: 40px; ';
        css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
        css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;';
        css += 'padding-left:35px';
        css+= '}';
        this._inputStyle = document.createElement('style');
        this._inputStyle.innerText = css;
    }
    /**
     *
     * @param logType  The type of log (see the constants). (optional)
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
            if(msg) {
                if(this._className) {
                    msg = this._className + ' - ' + msg;
                }
            }
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