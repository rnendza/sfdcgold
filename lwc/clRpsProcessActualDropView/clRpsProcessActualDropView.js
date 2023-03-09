import {LightningElement,api,track} from 'lwc';
import mainTemplate from "./clRpsProcessActualDropView.html";
import RPS_PROCESS_RT_STATUS_FIELD  from '@salesforce/schema/Route_Processing_Sheet__c.Processor_RT_Status__c';
import RPS_PROCESS_REPLENISHMENT_TYPE_FIELD  from '@salesforce/schema/Route_Processing_Sheet__c.Replenishment_Type__c';
import PROCESSING_PROCESS_STATUS_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Processing_Process_Status__c';
import PROCESSING_TOTAL_DROP_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Total_Drop__c';
import RPS_COLLECTION_TYPE_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Collection_Type__c';

import {getConstants} from "c/clConstantUtil";
import Id from "@salesforce/user/Id";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";

const RPS_PROCESSING_STATUS_COMPLETED_PROCESSING = 'COMPLETED PROCESSING';
const RPS_PROCESSOR_RT_STATUS = 'Complete';
const GLOBAL_CONSTANTS = getConstants();
const COL_TYPES_TO_SHOW_BV_VALUE = new Set(
    ['Regular - 2nd RT',
        'Additional Fill – RT Only',
        'Regular - RT Only' // 9/22/2022 https://accel-entertainment.monday.com/boards/1300348967/pulses/3181062708
    ]
);

export default class ClRpsProcessActualDropView extends NavigationMixin(LightningElement) {
    @api formDensity = 'auto';
    @api processStatus;
    @api replenishmentType;
    @api processCompletedMsg;
    @api routeScheduleId;
    @api objectApiName = 'Route_Processing_Sheet__c';
    @api formClass = 'xxxslds-box slds-theme_shade';
    @api formHelpMsg;
    @api formName = 'rpsInboundForm';
    @api formTitle;
    @api allFieldsRequired;
    @api useOverridedInputStyles;
    @api formButtonLabel = 'Save RTs';
    @api rpsId;
    @track loadedFields;


    optionalFields = ['Processing_Process_Status__c','Replenishment_Type__c','Total_Drop__c'];
    showEditForm = false;
    showOverflowFields;

    _rpsProcessStatusField = PROCESSING_PROCESS_STATUS_FIELD;
    _isLoading = true;
    _isSaving;
    _hasRendered;
    _buildCssOverrides;
    _userId = Id;
    _processCompletedMsg;
    _editFormStyle = '';
    _viewFormStyle = '';
    showBvValue;

    static delegatesFocus = true;

    constructor() {
        super();
        console.info('%c----> /lwc/clRpsProcessingActualDropView',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.useOverridedInputStyles = true;
        this.allFieldsRequired = true;

        // 3/29/2022 Removed per business desire to show edit at all times..
        //let showEdit = this.processStatus ? this.processStatus != RPS_PROCESSOR_RT_STATUS : true;
        let showEdit = true;
        this._editFormStyle = showEdit  ? 'slds-show' : 'slds-hide';
        this._viewFormStyle = !showEdit ? 'slds-show' : 'slds-hide';
    }

    render() {
        return mainTemplate;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
        }
    }

    handleLoad(event) {
        console.log('--> being handle load');
        const recordUi = event.detail;
        let fields = Object.values(event.detail.records)[0].fields;
        this.loadedFields = fields;
        console.log('--- handleLoad fields',fields);
        const status = fields[RPS_PROCESS_RT_STATUS_FIELD.fieldApiName].value;

        // 3/29/2022 Removed per business desire to show edit at all times..
        let showEdit = true;
        //let showEdit = status ? status != RPS_PROCESSOR_RT_STATUS : true;

        const rpsCollectionType = fields[RPS_COLLECTION_TYPE_FIELD.fieldApiName].value;
        this.showOverflowFields = this.replenishmentType && this.replenishmentType === 'Cash Fill';
        // try {
        //     console.log('fields',fields);
        //     const replenishmentType = fields[RPS_PROCESS_REPLENISHMENT_TYPE_FIELD.fieldApiName].value;
        //     if (replenishmentType && replenishmentType === 'Cash Fill') {
        //         this.showOverflowFields = true;
        //     }
        // } catch(e) {
        //     console.error(e);
        // }
        this.showBvValue = COL_TYPES_TO_SHOW_BV_VALUE.has(rpsCollectionType);

        this._editFormStyle = showEdit  ? 'slds-show' : 'slds-hide';
        this._viewFormStyle = !showEdit ? 'slds-show' : 'slds-hide';

        if(status === RPS_PROCESSOR_RT_STATUS) {

            // const oChangedBy = fields['Processing_Process_Changed_By__r']
            // let changedBy = '';
            // if(oChangedBy) {
            //     changedBy = oChangedBy.displayValue;
            // }
            // let changedDate = fields[PROCESSING_PROCESS_CHANGED_DATE_FIELD.fieldApiName].value;
            // if(changedDate) {
            //     changedDate = new Date(changedDate).toLocaleString();
            // }
            // let msg = 'Marked '+status + ' by ' + changedBy;
            // if(changedDate) {
            //     msg += ' on ' + changedDate + '.';
            // }
            let msg = ' RT Status is currently '+status;
            this._processCompletedMsg = msg;
        }

        // if(status === RPS_PROCESSING_STATUS_COMPLETED_PROCESSING) {
        //
        //     const oChangedBy = fields['Processing_Process_Changed_By__r']
        //     let changedBy = '';
        //     if(oChangedBy) {
        //         changedBy = oChangedBy.displayValue;
        //     }
        //     let changedDate = fields[PROCESSING_PROCESS_CHANGED_DATE_FIELD.fieldApiName].value;
        //     if(changedDate) {
        //         changedDate = new Date(changedDate).toLocaleString();
        //     }
        //     let msg = 'Marked '+status + ' by ' + changedBy;
        //     if(changedDate) {
        //         msg += ' on ' + changedDate + '.';
        //     }
        //     this._processCompletedMsg = msg;
        // }
        if(!this._buildCssOverrides) {
            this.buildFormThemeOverrideCss();
            this._buildCssOverrides = true;
            this._isLoading = false;
        } else {
            this._isLoading = false;
        }
        console.log('---> end handle load');
    }
    handleInputBlur(evt) {
        console.log('blur');
    }

    handleSubmit(event) {
        event.preventDefault();
        console.log('---> handleSubmit');
        let fields = event.detail.fields;
        if(!this.validateFields(fields)) {
            //   dont submit!
        } else {
            this._isSaving = true;
            try {
                fields[RPS_PROCESS_RT_STATUS_FIELD.fieldApiName] = RPS_PROCESSOR_RT_STATUS;
            } catch (e) {
                 console.error(e);
            }
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
    }

    validateFields(fields) {
        // let valid = fields.Enter_Total_Drop__c
        //     && fields.Cassette_1_Note_Count_Drop__c && fields.Cassette_5_Note_Count_Drop__c
        //     && fields.Cassette_20_Note_Count_Drop__c && fields.Cassette_50_Note_Count_Drop__c
        //     && fields.Cassette_100_Note_Count_Drop__c && fields.Reject_Drop_Total__c;
        let valid = this.fieldValid(fields.Enter_Total_Drop__c)
            && this.fieldValid(fields.Cassette_1_Note_Count_Drop__c)
            && this.fieldValid(fields.Cassette_5_Note_Count_Drop__c)
            && this.fieldValid(fields.Cassette_20_Note_Count_Drop__c)
            && this.fieldValid(fields.Cassette_50_Note_Count_Drop__c)
            && this.fieldValid(fields.Cassette_100_Note_Count_Drop__c)
            && this.fieldValid(fields.Reject_Drop_Total__c);
        console.log('--> validate all req fields exist='+valid);

        if (valid) {
            let totalDrop = this.calcTotalDrop(fields);
            let enterTotalDrop = fields.Enter_Total_Drop__c;
            if (totalDrop != enterTotalDrop) {
                console.warn(' The Entered Total Drop Field value of ' + enterTotalDrop + ' does not equal to the'
                    + ' calculated total drop of ' + totalDrop);

                let msg = 'Entered Total Not Valid, Must Equal Cassettes Summed Value';
                this.dispatchEvent(new ShowToastEvent({message: msg, variant: "error"}));
                valid = false;
            }
        } else {
            let msg = 'Please enter values in all required fields.';
            this.dispatchEvent(new ShowToastEvent({message: msg, variant: "error"}));
        }
        return valid;
    }

    fieldValid(field) {
        return field  || field === 0;
    }


    // /**
    //  * The bus definition of what fields are required has been defined as the valid variable.
    //  *
    //  * @param fields
    //  * @returns {*}
    //  */
    // validateFields(fields) {
    //     let valid = fields.Enter_Total_Drop__c
    //         && fields.Cassette_1_Note_Count_Drop__c && fields.Cassette_5_Note_Count_Drop__c
    //         && fields.Cassette_20_Note_Count_Drop__c && fields.Cassette_50_Note_Count_Drop__c
    //         && fields.Cassette_100_Note_Count_Drop__c && fields.Reject_Drop_Total__c;
    //     console.log('--> validate all req fields exist='+valid);
    //
    //     if (valid) {
    //         let totalDrop = this.calcTotalDrop(fields);
    //         let enterTotalDrop = fields.Enter_Total_Drop__c;
    //         if (totalDrop != enterTotalDrop) {
    //             console.warn(' The Entered Total Drop Field value of ' + enterTotalDrop + ' does not equal to the'
    //                 + ' calculated total drop of ' + totalDrop);
    //
    //             let msg = 'Entered Total Not Valid, Must Equal Cassettes Summed Value';
    //             this.dispatchEvent(new ShowToastEvent({message: msg, variant: "error"}));
    //             valid = false;
    //         }
    //     } else {
    //         let msg = 'Please enter values in all required fields.';
    //         this.dispatchEvent(new ShowToastEvent({message: msg, variant: "error"}));
    //     }
    //     return valid;
    // }

    /**
     *
     * @param fields
     * @returns {*}
     */
    calcTotalDrop(fields) {
        let totalDrop;
        console.log('fields',fields);
        totalDrop = Number(fields.Cassette_1_Note_Count_Drop__c * 1) + Number(fields.Cassette_5_Note_Count_Drop__c * 5)
            + Number(fields.Cassette_20_Note_Count_Drop__c * 20)     + Number(fields.Cassette_50_Note_Count_Drop__c * 50)
            + Number(fields.Cassette_100_Note_Count_Drop__c * 100)    + Number(fields.Reject_Drop_Total__c);
        console.log('---> calculated total drop='+totalDrop);
        return totalDrop;
    }

    manualFormSubmit(evt) {
        const btn = this.template.querySelector( ".accel-form-submit-hide" );
        if( btn ){
            btn.click();
        }
    }

    // handleSubmit(event) {
    //     event.preventDefault();
    //     console.log('---> handleSubmit');
    //     let fields = event.detail.fields;
    //     //let fields = Object.values(event.detail.records)[0].fields;
    //     console.log('fields',fields);
    //     if(!this.validateFields(fields)) {
    //         const toast = new ShowToastEvent({
    //             message: "Review all error messages below to correct your data.",
    //             variant: "error",
    //         });
    //         this.dispatchEvent(toast);
    //     } else {
    //         this._isSaving = true;
    //         //  Stop the form from submitting and do shit if necessary!
    //         try {
    //             fields[RPS_PROCESS_RT_STATUS_FIELD.fieldApiName] = RPS_PROCESSOR_RT_STATUS;
    //         } catch (e) {
    //             alert(e);
    //         }
    //         this.template.querySelector('lightning-record-edit-form').submit(fields);
    //     }
    // }

    handleSuccess(event) {
        console.log('handleSuccess rps inbound form fields. : '+JSON.stringify(event.detail.fields));
        this._isSaving = false;
        let toastEvt;
        toastEvt = new ShowToastEvent({
            title: '',
            message: 'RT information saved successfully!',
            variant: 'success'
        });
        this.showEditForm = false;
        this.dispatchEvent(toastEvt);
        this.dispatchEvent( new CustomEvent('rpsinboundformsubmitted', {detail: { success: true }}) );

        try {
            this.debugFieldValues(event.detail.fields);
        } catch (e) {

        }
    }

    handleError(event) {
        this._isSaving = false;
        console.log(JSON.stringify(event.error));
        alert('handleError()--->'+JSON.stringify(event));
    }

    handleCloseClicked(evt) {
        this.dispatchEvent( new CustomEvent('formcloseclicked', {detail: { name: this.formName }})  );
    }

    get showForm() {
        return this.rpsId;
    }

    get showStencil() {
        return this._isLoading || this._isSaving;
    }

    get inputsClass() {
        return this.showStencil ? 'slds-hide' : '';
    }

    buildFormThemeOverrideCss() {
        let css = '.slds-form-element_label {color:black!important;font-weight:bold!important}';
        const style = document.createElement('style');
        if(this.useOverridedInputStyles) {
            // css += '.accel-form_container .slds-input {width: 100%;display: inline-block;height: 40px; ';
            // css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
            // css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;}';
            css += '.accel-form_container .slds-form-element__label {font-weight:bold!important; }';
            css += '';
        }
        style.innerText = css;
        let target = this.template.querySelector('.form-theme-overrides-class');
        target.appendChild(style);
    }

    debugFieldValues(fields) {
        fields.forEach(item => {
            console.log('name='+JSON.stringify(item));
        });
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