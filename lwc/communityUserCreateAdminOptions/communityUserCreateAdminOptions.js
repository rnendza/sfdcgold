import {LightningElement, track, api, wire} from 'lwc';
import Id from '@salesforce/user/Id';
import retrieveTriggerSettings from '@salesforce/apex/ContactsAccountsController.retrieveTriggerSettings';
import retrieveOrgBatchSettings from '@salesforce/apex/ContactsAccountsController.retrieveOrgBatchSettings';
import upsertTriggerSettings from '@salesforce/apex/ContactsAccountsController.updateTriggerSettings';
import upsertBatchSettings from '@salesforce/apex/ContactsAccountsController.updateBatchSettings';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import AccelUtilsSvc from 'c/accelUtilsSvc';

export default class CommunityUserCreateAdminOptions extends LightningElement {

    _userId = Id;
    _wiredBatchSettings;
    _wiredTriggerSettings;
    _debugConsole   = true;
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);

    @track triggerSettings;
    @track batchSettings;

    @api pwGenTypeValue;
    @api allowUserTriggerToSetPw = false;
    @api allowButtonToSetPw = false;

    @api
    get pwGenTypeOptions() {
        return [
            { label: 'Random Generation', value: 'random' },
            { label: 'Predefined Password', value: 'predefined' },
            { label: 'Named Credential', value: 'namedcred' },
            { label: 'Stored / Encrypted', value: 'storedencrypted' }
        ];
    }
    @api
    get displayTriggerSettings() {
        return this.triggerSettings;
    }
    @api
    get displayBatchSettings() {
        return this.batchSettings;
    }
    constructor() {
        super();
    }

    @wire(retrieveTriggerSettings,{userId: '$_userId'})
    wiredResults(wiredData) {
        this._wiredTriggerSettings = wiredData;
        const { data, error } = this._wiredTriggerSettings;
        if(data) {
            this.triggerSettings = Object.assign({},data);
            this.allowUserTriggerToSetPw = this.triggerSettings.Portal_User_SetPassword_Active__c;
            console.log(JSON.stringify(this.triggerSettings));
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }
    @wire(retrieveOrgBatchSettings)
    wiredBatchResults(wiredData) {
        this._wiredBatchSettings = wiredData;
        const { data, error } = this._wiredBatchSettings;
        if(data) {
            this.batchSettings = Object.assign({},data);
            console.log(JSON.stringify(this.batchSettings));
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }
    upsertTriggerSettings( triggerSettings ) {
        let params = { triggerSettings: triggerSettings };
        upsertTriggerSettings(params)
            .then(result => {
                let dto = result;
                if(dto.isSuccess) {
                    let ts = this._accelUtils.getMapValue('ts', dto.values);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: dto.message,
                            variant: 'success',
                        }),
                    );
                } else {

                }
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while updating record',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    upsertBatchSettings( batchSettings ) {
        let params = { batchSettings: batchSettings };
        upsertBatchSettings(params)
            .then(result => {
                let dto = result;
                if(dto.isSuccess) {
                    this.batchSettings = Object.assign({},this._accelUtils.getMapValue('batch', dto.values));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: dto.message,
                            variant: 'success',
                        }),
                    );
                } else {

                }
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while updating record',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    handlePwGenTypeOptions(event) {
        if(event.detail.value !== 'random') {
            alert(' Only Random Generation is currently supported');
            this.template.querySelector('[data-id="pwGenType"]').value="random";
            this.pwGenTypeValue = 'random';
            return;
        }
        this.pwGenTypeValue = event.detail.value;
        this.dispatchEvent(new CustomEvent('pwgentypeselected', {bubbles: false, detail: {value: this.pwGenTypeValue}}))
    }

    handleAllowUserTriggerToSetPw(event) {
        this.allowUserTriggerToSetPw = event.target.checked;
        this.triggerSettings.Portal_User_SetPassword_Active__c = this.allowUserTriggerToSetPw;
        this.pwGenTypeValue = 'random';
        this.upsertTriggerSettings(this.triggerSettings);
        this.dispatchEvent(new CustomEvent('pwsendoptionselected', {bubbles: false, detail: {value: this.allowUserTriggerToSetPw}}))
    }
    handleChangeMostRecentHpdDate(event) {
        this.batchSettings.Most_Recent_Hpd_Date__c = event.detail.value;
        this.upsertBatchSettings(this.batchSettings);
        // this.pwGenTypeValue = event.detail.value;
        // this.dispatchEvent(new CustomEvent('pwgentypeselected', {bubbles: false, detail: {value: this.pwGenTypeValue}}))
    }
}