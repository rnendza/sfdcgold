import {LightningElement, wire,track,api} from 'lwc';
import {reduceErrors} from 'c/ldsUtils';
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {uiHelper} from "./accelSecurityAuditUiHelper";
import retrieveAllProfiles from '@salesforce/apex/SecurityAuditFiltersController.retrieveAllProfiles';
import retrieveAllPermsets from '@salesforce/apex/SecurityAuditFiltersController.retrieveAllPermissionSets';
import retrieveAllSObjects from '@salesforce/apex/SecurityAuditFiltersController.retrieveAllSObjects';

const   GLOBAL_CONSTANTS            = getConstants();
const   MAP_KEY_PROFILE_DATA        = 'MAP_KEY_PROFILE_DATA';
const   MAP_KEY_PERMSET_DATA        = 'MAP_KEY_PERMSET_DATA';
const   MAP_KEY_SOBJECT_DATA        = 'MAP_KEY_SOBJECT_DATA';

export default class AccelSecurityAuditFilters extends LightningElement {

    @api defaultSelections;

    _wiredProfilesDto;
    _wiredPermSetsDto;
    _wiredSObjectsDto;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    @track profileData;
    @track pillIcon;
    @track profileOptions;
    @track defaultProfileSelections;
    @track permSetData;
    @track permSetOptions;
    @track defaultPermSetSelections;
    @track sObjectData;
    @track sObjectOptions;
    @track defaultSObjectSelections;
    @track profilePillIcon;
    @track permSetPillIcon;
    @track sObjectPillIcon;

    constructor() {
        super();
        console.info('%c----> /lwc/accelSecurityAuditFilters',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
    }

    connectedCallback() {
        if(this.defaultSelections) {
            this.defaultProfileSelections = this.defaultSelections.profiles;
            this.defaultPermSetSelections = this.defaultSelections.permSets;
            this.defaultSObjectSelections = this.defaultSelections.sObjects;
            this.profilePillIcon = 'custom:custom77';
            this.permSetPillIcon = 'standard:user_role';
            this.sObjectPillIcon = 'standard:sobject';

            console.log('---> cc default selections',JSON.parse(JSON.stringify(this.defaultSelections)));
        }


    }

    @wire(retrieveAllProfiles)
    wiredProfiles(wiredData) {
        this._wiredProfilesDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            console.log('---> dto',JSON.parse(JSON.stringify(data)));
            this.profileData = this._accelUtils.getMapValue(MAP_KEY_PROFILE_DATA, data.values);
            if(data.isSuccess) {
                this.generateProfileOptions();
            }
        }
    }

    @wire(retrieveAllPermsets)
    wiredPermSets(wiredData) {
        this._wiredPermSetsDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            console.log('---> dto',JSON.parse(JSON.stringify(data)));
            this.permSetData = this._accelUtils.getMapValue(MAP_KEY_PERMSET_DATA, data.values);
            if(data.isSuccess) {
                this.generatePermsetOptions()
            }
        }
    }

    @wire(retrieveAllSObjects)
    wiredSObjects(wiredData) {
        this._wiredSObjectsDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            console.log('---> dto',JSON.parse(JSON.stringify(data)));
            this.sObjectData = this._accelUtils.getMapValue(MAP_KEY_SOBJECT_DATA, data.values);
            if(data.isSuccess) {
                this.generateSobjectOptions();
            }
        }
    }

    generateProfileOptions() {
        if(this.profileData) {
            let options = [];
            this.profileData.forEach(item => {
                let option = {label:item.Name, value:item.Name};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.label < b.label ? -1 : 1;
            });
            this.profileOptions = options;
        }
    }

    generatePermsetOptions() {
        if(this.permSetData) {
            let options = [];
            this.permSetData.forEach(item => {
                let option = {label:item.Label, value:item.Name};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.label < b.label ? -1 : 1;
            });
            this.permSetOptions = options;
        }
    }

    generateSobjectOptions() {
        if(this.sObjectData) {
            let options = [];
            this.sObjectData.forEach(item => {
                let option = { label:item.label, value:item.apiName};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.label < b.label ? -1 : 1;
            });
            this.sObjectOptions = options;
        }
    }

    handleSelect(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                this.dispatchEvent(new CustomEvent('select', {
                    detail: {
                        'name' :  evt.detail.name,
                        'payloadType' : 'multi-select',
                        'payload' : {
                            'value' : payload.value,
                            'values' : payload.values
                        }
                    }
                }));
            }
        }
    }
    handleOptionsRemoved(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                console.log('forwarding opttion removed from recieved payload',JSON.parse(JSON.stringify(payload)));
                let arrValuesRemoved = [];
                if(payload.optionsRemoved) {
                    payload.optionsRemoved.forEach( option => {arrValuesRemoved.push(option.value)});
                }
                this.dispatchEvent(new CustomEvent('remove', {
                    detail: {
                        'name' :  evt.detail.name,
                        'payloadType' : 'multi-select',
                        'payload' : {
                            'optionsRemoved' : arrValuesRemoved
                        }
                    }
                }));
            }
        }
    }

    get isLoading() {
        let isIt =  !this.sObjectOptions || !this.permSetOptions || !this.profileOptions;
        return isIt;
    }
    get showStencil() {
       return this.isLoading;
    }

}