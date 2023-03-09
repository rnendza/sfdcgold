import {LightningElement, track, api, wire} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
import Logger from 'c/logger'
import {uiHelper} from "c/accelLoginHistoryUiHelper";
import {plValuesHelper} from "./accelLoginHistoriesFiltersPlValues";
import retrieveUsers from '@salesforce/apex/LoginHistoryController.retrieveUsers';
import {reduceErrors} from "c/ldsUtils";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import USER_TYPE_FIELD from '@salesforce/schema/User.UserType';

const   GLOBAL_CONSTANTS            = getConstants();
const   MAP_KEY_USER_WRAPS             = 'USER_WRAPS';
const   MAX_USER_RESULTS = 5000;
const   ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class AccelLoginHistoriesFilters extends LightningElement {

    @api defaultSelections;
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}


    @track pillIcon;
    @track userPillIcon;
    @track loginTypePillIcon;
    @track sessionTypePillIcon;
    @track userTypePillIcon;
    @track statusPillIcon;
    @track activeInactiveCboxOptions;

    @track userOptions;
    @track userTypeOptions;
    @track statusOptions;
    @track loginTypeOptions;
    @track sessionTypeOptions;
    @track defaultSessionTypeSelections;
    @track defaultStatusSelections;
    @track defaultLoginTypeSelections;
    @track defaultUserSelections;
    @track defaultUserTypeSelections;
    @track defaultActiveInactiveSelections;
    @track authSessionObjectInfo;
    @track users;

    _debugConsole;
    _isLoading;
    @track _selectedActiveInactiveOptions = [];


    @track userSearchParams = {
        iLimit : MAX_USER_RESULTS,
        userIds : [],
        userTypes : [],
        activeInactives : []
    }

    constructor() {
        super();
        console.info('%c----> /lwc/accelLoginHistoriesFilters',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
        this.buildActiveInactiveCboxOptions();
    }

    connectedCallback() {
        if(this.defaultSelections) {
            this.defaultSessionTypeSelections = this.defaultSelections.sessionTypes;
            this.defaultLoginTypeSelections = this.defaultSelections.loginTypes;
            this.defaultUserSelections = this.defaultSelections.users;
            this.defaultUserTypeSelections = this.defaultSelections.userTypes;
            this.userSearchParams.userTypes  = this.defaultUserTypeSelections.userTypes;
            this._selectedActiveInactiveOptions = this.defaultSelections.activeInactives;
            this.userSearchParams.activeInactives = this._selectedActiveInactiveOptions;
            this.userSearchParams.userTypes = this.defaultUserTypeSelections;
            this.sessionTypePillIcon = 'standard:sobject';
            this.userPillIcon = 'standard:user';
            this.loginTypePillIcon = 'custom:custom77';
            this.userTypePillIcon = 'standard:user_role';
            // this.generateSessionTypeOptions();
            // this.generateLoginTypeOptions();
            this.doRetrieveUsers();
            this.log(DEBUG,'---> cc default selections',this.defaultSelections);
        }
    }


    @wire(getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName:USER_TYPE_FIELD })
    wiredUserTypeData(wiredData) {
        const { data, error } = wiredData;
        console.log('---> wired2');
        if (error) {
            console.error(error);
            //this.error = reduceErrors(error);
            this._isLoading = false;
        } else if (data) {
            console.log('data1',JSON.parse(JSON.stringify(data)));
            this.generateUserTypeOptions(data.values);
        }
    }

    doRetrieveUsers() {
        this._isLoading = true;
        this.log(DEBUG,'calling doRetrieveUsers params:',this.userSearchParams);
        retrieveUsers({params: this.userSearchParams})
            .then((data) => {
                this.log(DEBUG,'userssearrchdto->', data);
                this.users = uiHelper.getMapValue(MAP_KEY_USER_WRAPS,data.values);
                this.generateUserOptions();
            })
            .catch((error) => {
                this.error = error;
                this.log(ERROR,'Error',error);
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading users filter: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }


    get selectUserTypeLabel() {
        let lbl = 'Select User Type';
        if(this.userTypeOptions) {
            lbl += 's';
        }
        return lbl;
    }

    get userStatusLabel() {
        return 'Select User Statuses';
    }

    generateUserTypeOptions(plValues) {
        let options = [];
        if(plValues) {
            plValues.forEach( pl => {
                let option = {label:pl.label, value:pl.value};
                options.push(option);
            });
        }
        this.userTypeOptions = options;
    }

    generateUserOptions() {
        if(this.users) {
            let options = [];
            this.users.forEach(item => {
                let option = {label:item.userName, value:item.userId};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.label < b.label ? -1 : 1;
            });
            this.userOptions = options;
        }
    }


    buildActiveInactiveCboxOptions() {
        this.activeInactiveCboxOptions = [
            {value: 'active',label:'Active'},
            {value: 'inactive',label:'InActive'},
        ];

    }

    handleSelect(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                this.log(DEBUG,'forwarding option selected payload',payload);
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
    /**
     * Handle the change event of the picklist and fire an event so the parent can listen.
     * Note: the checkbox group change evt contains all selected values and not just the most recently selected one!
     * @param evt
     */
    handleActiveInActiveChkBoxChange(evt) {
        let values = evt.target.value;
        const name = evt.target.name;
        this._selectedActiveInactiveOptions = values;
        this.log(DEBUG,'selected cbox values',this._selectedActiveInactiveOptions);
        this.userSearchParams.activeInactives = this._selectedActiveInactiveOptions;
        this.doRetrieveUsers();
        // let option = {name: name, valuesSelected: this.selectedVarianceOptions};
        // this.dispatchEvent(new CustomEvent('varianceoptionsselected', {detail: option}));
    }
    handleOptionsRemoved(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                this.log(DEBUG,'forwarding opttion removed from recieved payload',payload);
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
        return this._isLoading;
    }
    get showStencil() {
        return this.isLoading;
    }

    /**
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger && this.debugConsole) {
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