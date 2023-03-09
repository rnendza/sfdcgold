import {LightningElement,api,track,wire} from 'lwc';
import COLLECTOR_1_FIELD from '@salesforce/schema/Route_Schedule__c.Collector_1__c'
import COLLECTOR_2_FIELD from '@salesforce/schema/Route_Schedule__c.User__c';
import ASSIGNED_DRIVER_FIELD from '@salesforce/schema/Route_Schedule__c.Assigned_Driver__c'
import { getConstants } from 'c/clConstantUtil';
import { updateRecord,getRecord} from "lightning/uiRecordApi";
import {refreshApex} from "@salesforce/apex";

const GLOBAL_CONSTANTS = getConstants();

export default class ClAdminRouteScheduleCollectorForm extends LightningElement {

    @api rsId;

    _fields;
    _isLoading = true;
    _editFormStyle = '';
    _collector1Field = COLLECTOR_1_FIELD;
    _collector2Field = COLLECTOR_2_FIELD;
    _assignedDriverField = ASSIGNED_DRIVER_FIELD;
    showEditForm = false;
    formClass;
    formDensity;
    _routeScheduleRecord = {};

    connectedCallback() {
        this._editFormStyle = 'slds-show';
    }

    /**
     * Load any existing values into the routeScheduleRecord using the load of the record-edit-form
     * @param evt
     */
    handleLoad(evt) {
        console.log('load');
        let record = evt.detail.records;
        this._fields = record[this.rsId].fields;
        this._routeScheduleRecord[this._collector1Field.fieldApiName] = this._fields[this._collector1Field.fieldApiName].value;
        this._routeScheduleRecord[this._collector2Field.fieldApiName] = this._fields[this._collector2Field.fieldApiName].value;
        this._routeScheduleRecord[this._assignedDriverField.fieldApiName] = this._fields[this._assignedDriverField.fieldApiName].value;
        this._isLoading = false;
    }

    /**
     * Get the name of the field and the value and fire an update.
     * @param evt
     */
    handleInputChange(evt){
        let name = evt.target.fieldName;
        let value = evt.detail.value[0];
        this._routeScheduleRecord[name] = value;
        this.updateRecord(name);
    }

    handleSuccess(event) {
        this._isSaving = false;
        console.log('success');
        this.dispatchEvent( new CustomEvent('schedulecollectorformsubmitted', {detail: { success: true }}) );
    }

    handleError(event) {
        this._isSaving = false;
        console.log(JSON.stringify(event.error));
        alert('handleError()--->'+JSON.stringify(event));
    }

    get showForm() {
        return this.rsId;
    }

    get showStencil() {
        return this._isLoading || this._isSaving;
    }

    get inputsClass() {
        return this.showStencil ? 'slds-hide' : '';
    }

    @wire(getRecord, { recordId: '$rpsId', fields: ['Route_Schedule__c.Id'] })
    rsRecord;

    /**
     * User lds to run the update for each change of a field.
     */
    updateRecord(fieldApiName) {
        try {
            let toUpdate = {fields: {Id: this.rsId}};
            toUpdate.fields[fieldApiName] = this._routeScheduleRecord[fieldApiName];

            updateRecord(toUpdate)
                .then(() => {
                    console.log('update success');
                    //  Reload the cache.
                    refreshApex(this.rsRecord).catch(e => console.log(e));
                })
                .catch(error => {
                    alert(error);
                });
        } catch(e) {
            console.error(e);
        }
    }
}