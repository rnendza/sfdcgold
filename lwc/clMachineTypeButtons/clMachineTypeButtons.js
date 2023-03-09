import {api, track, LightningElement} from 'lwc';
import retrieveUserSetting from '@salesforce/apex/clUserSettingsController.retrieveUserSettings';
import updateUserSetting from '@salesforce/apex/clUserSettingsController.updateSetting';
import insertUserSetting from '@salesforce/apex/clUserSettingsController.insertSetting';
import {reduceErrors} from "c/ldsUtils";
import Id from '@salesforce/user/Id';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import { getConstants } from 'c/clConstantUtil';

const MAP_KEY_USER_SETTING = 'USER_SETTING';
//  The below is used if all else fails and no machine type can be found (ie apex error).
const DEFAULT_SELECTED_MACHINE_TYPE = 'VGT';

const RT_BUTTON = [
    'Regular - RT & VGT',
    'Additional Fill – RT & VGT',
    'Additional Fill – RT Only',
    'Regular - 2nd RT',
    'Regular - RT Only' // 9/22/2022 https://accel-entertainment.monday.com/boards/1300348967/pulses/3181062708
];
const VGT_BUTTON = [
    'Regular - RT & VGT',
    'Additional Fill – RT & VGT',
    'Additional Fill – VGT Only',
    'Regular - VGT Only' // 9/22/2022 https://accel-entertainment.monday.com/boards/1300348967/pulses/3181062708
];
const GLOBAL_CONSTANTS = getConstants();

export default class ClMachineTypeButtons extends LightningElement {

    @api selectedButtonVariant = 'brand';
    @api unselectedButtonVariant = 'neutral';


    /**
     * RPS Passed in from the parent to decipher collection type.
     * Re-trigger setViewData to manip defaulted button and buttons shown accordingly.
     *
     * @param val  The Route_Processing_Sheet__c.
     * @see CL-37 https://accel-entertainment.monday.com/boards/1300348967/pulses/1779260597?asset_id=330796710
     */
    @api
    set rpsRecord(val) {
        if(val) {
            console.log('--> buttons setter for rpsRecord called:',JSON.parse(JSON.stringify(val)));
            this._rpsRecord = val;
            this.setViewData();
        }
    }
    get rpsRecord() {
        return this._rpsRecord;
    }

    @track machineTypeOptions;

    _rpsRecord;
    _machineTypeSelected;
    _userSetting;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _userId = Id;

    constructor() {
        super();
        console.info('%c----> /lwc/clMachineTypeButtons',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }
    /**
     *  Retrieve SS settings on connected callback as opposed to wire as userId is unlike to trigger a refresh
     *  and communities is weird with this.
     */
    connectedCallback() {
        this.doRetrieveUserSettings();
    }

    /**
     * Imperatively query of CL_User_Setting__c. uses this value to set the default selected button while building the
     * buttons array.
     *
     * @see setViewData
     */
    doRetrieveUserSettings() {
        let params = {userId: this._userId};
        retrieveUserSetting(params)
            .then(dto => {
                if(dto.isSuccess) {
                    this._userSetting = this._accelUtils.getMapValue(MAP_KEY_USER_SETTING, dto.values);
                    console.log('--- user setting',JSON.stringify(this._userSetting));
                    if (this._userSetting && this._userSetting.Selected_Machine_Type__c) {
                        this.setViewData();
                    }
                } else {
                    if(dto.technicalMsg == 'notfound') {
                        this.createSetting();
                    } else {
                        console.error(dto.message + dto.technicalMsg, dto);
                        this.setDefaultMachineType();
                    }
                }
            })
            .catch(error => {
                this.setDefaultMachineType();
                console.error(JSON.stringify(error));
                this.error = reduceErrors(error);
                console.error(this.error);
            });
    }

    /**
     * Only use this if all else fails and we can't find a selected machine type!
     */
    setDefaultMachineType() {
        this._userSetting = {};
        this._userSetting.Selected_Machine_Type__c = DEFAULT_SELECTED_MACHINE_TYPE;
        this.setViewData();
    }
    /**
     * Update CL_User_Setting__c.Selected_Machine_Type__c with user selection in order to persist this value.
     */
    modifySetting() {
        let params = { id : this._userSetting.Id, machineType: this._machineTypeSelected };
        console.log('--> calling updateSetting with params:', params);
        updateUserSetting(params)
            .then(dto => {
                console.log('--> returned dto=' + JSON.stringify(dto));
                if (dto.isSuccess) {
                    console.info(' success in update' + JSON.stringify(dto));
                } else {
                    console.info(' no cl setting found' + JSON.stringify(dto));
                    this.createSetting();
                }
            })
            .catch(error => {
                this.error = reduceErrors(error);
                console.error(this.error);
            });
    }

    /**
     * Insert CL_User_Setting__c.Selected_Machine_Type__c with user selection and user id in order to persist this value.
     */
    createSetting() {
        let params = { userId : this._userId, machineType: DEFAULT_SELECTED_MACHINE_TYPE };
        console.info('--> calling insert with params:', params);
        insertUserSetting(params)
            .then(dto => {
                console.log('--> returned dto=' + JSON.stringify(dto));
                if (dto.isSuccess) {
                    console.info(' success on insert' + JSON.stringify(dto));
                    this._userSetting = this._accelUtils.getMapValue(MAP_KEY_USER_SETTING, dto.values);
                    this.setViewData();
                } else {
                    console.error(' error on insert' + JSON.stringify(dto));
                }
            })
            .catch(error => {
                this.error = reduceErrors(error);
                console.error(this.error);
            });
    }

    /**
     * Build picklist options using the persisted machine type as the defaulted value.
     * Fire custom evt to parent to handle view switching.
     */
    setViewData() {
        if(!this._machineTypeSelected) {
            this._machineTypeSelected = this._userSetting ? this._userSetting.Selected_Machine_Type__c : null;
            console.log('--> buttons no machine type selected attempting to set to user stored val:'+this._machineTypeSelected);
        }
        this.buildMachineTypePlOptions();
        const detail =  { machineType: this._machineTypeSelected };
        console.log('---> buttons firing evt to parent with pl',detail);
        this.dispatchEvent( new CustomEvent('machinetypeselected', {detail:detail}) );
    }

    /**
     * Handle the button click. Update the persisted value on the server.
     * Fire custom evt to parent to handle view switching.
     *
     * @param evt
     */
    handleClick(evt){
        let buttonId = evt.target.dataset.id;
        if(buttonId) {
            this._machineTypeSelected = buttonId;
            this.modifySetting();
            const detail =  { machineType: this._machineTypeSelected };
            console.log('--- in handleClick firing machine type selected with ',detail);
            this.dispatchEvent( new CustomEvent('machinetypeselected', {detail:detail}) );
            this.toggleMachineTypeButtons();
        }
    }
    doesArrayHaveValue(arr,val) {
        let hasIt = false;
        if(arr) {
            hasIt = arr.map(value => value.toLowerCase()).includes(val.toLowerCase());
        }
        return hasIt;
    }

    /**
     * Build button available options based on Route_Processing_Sheet__c.Collection_Type__c.
     * This cannot be called till we have _rpsRecord in context (passed from parent cmp) See
     * public api setting above. if we are only showing say the RT button but the user has the default
     * selected setting of VGT we must override that since VGT is not showing. (this is trigger an event to the
     * parent component to switch views ass well as highlight the button and update the cl user setting)
     *
     * @todo pull from custom mdt.
     * @see CL-37 https://accel-entertainment.monday.com/boards/1300348967/pulses/1779260597?asset_id=330796710
     */
    buildMachineTypePlOptions() {
        this.machineTypeOptions = [];
        console.log('----> rpsRecord:'+JSON.stringify(this._rpsRecord));
        if (this._rpsRecord) {
            let collectionType = this._rpsRecord.Collection_Type__c;
            console.log('----> collection type:'+collectionType);
            if (VGT_BUTTON.includes(collectionType)) {
                this.machineTypeOptions.push({value: 'VGT', label: 'VGT', selected: false})
            }
            if (RT_BUTTON.includes(collectionType)) {
                this.machineTypeOptions.push({value: 'Redemption', label: 'RT', selected: false})
            }
            // There is only one button on the screen we have to trigger it as selected and regardless of default selected value
            // is in CL_User_Settings__c
            if(this.machineTypeOptions.length === 1) {
                this._machineTypeSelected = this.machineTypeOptions[0].value;
                console.log('setting machineTypeSelected',this._machineTypeSelected);
            }
        }
        this.toggleMachineTypeButtons();
    }


    /**
     * Sets selected a variant values on options array.
     */
    toggleMachineTypeButtons() {
        if(this.machineTypeOptions) {
            this.machineTypeOptions.forEach((plOption) => {
                if (plOption.value == this._machineTypeSelected) {
                    plOption.selected = true;
                    plOption.variant =  this.selectedButtonVariant;
                } else {
                    plOption.selected = false;
                    plOption.variant = this.unselectedButtonVariant;
                }
            });
        }
    }

}