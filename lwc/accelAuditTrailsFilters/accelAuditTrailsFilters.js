import {LightningElement,track,api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
import Logger from 'c/logger'
import {uiHelper} from "c/accelAuditTrailsUiHelper";
import retrieveAllAdminUsers from '@salesforce/apex/AuditTrailController.retrieveAdminUsers';
import retrieveWestMonroeUsers from '@salesforce/apex/AuditTrailController.retrieveWestMonroeUsers';
import retrieveAllProfiles from '@salesforce/apex/AuditTrailController.retrieveAllProfiles';
import {plValuesHelper} from "./accelAuditTrailsFiltersPlValues";

const   GLOBAL_CONSTANTS            = getConstants();
const   MAP_KEY_USER_WRAPS             = 'USER_WRAPS';
const   MAP_KEY_PROFILE_WRAPS             = 'PROFILE_WRAPS';
const   ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class AccelAuditTrailsFilters extends LightningElement {

    @api defaultSelections;
    @api allowInputHighlight;
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}


    @track pillIcon;
    @track userPillIcon;
    @track actionPillIcon;
    @track profilePillIcon;

    @track userOptions;
    @track wmpUserOptions;
    @track actionOptions;
    @track profileOptions;

    @track loginTypeOptions;
    @track sessionTypeOptions;
    @track defaultSessionTypeSelections;
    @track defaultLoginTypeSelections;
    @track defaultUserSelections;
    @track defaultWmpUserSelections;
    @track defaultActionSelections;
    @track defaultProfileSelections;
    @track authSessionObjectInfo;
    @track users;
    @track wmpUsers;
    @track userTypeOptions;
    @track profiles;

    @track selectedStartDateTimeValue;
    @track selectedEndDateTimeValue;
    @track selectedUserTypeValue;

    _debugConsole;

    constructor() {
        super();
        console.info('%c----> /lwc/accelAuditTrailsFilters',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
        this.generateUserTypeOptions();
        this.doRetrieveWestMonroeUsers();
        this.doRetrieveAdminUsers();
    }

    connectedCallback() {
        this.allowInputHighlight = true;
        if(this.defaultSelections) {
            this.defaultUserSelections = this.defaultSelections.users;
            this.defaultWmpUserSelections = this.defaultSelections.wmpUsers;
            this.defaultActionSelections = this.defaultSelections.actions;
            this.userPillIcon = 'standard:user';
            this.profilePillIcon = 'standard:profile';
            this.actionPillIcon = 'standard:section';
            this.generateActionOptions();
            this.generateDefaultDates();
            this.log(DEBUG,'---> cc default selections',this.defaultSelections);
        }
    }

    doRetrieveAdminUsers() {
        this._isLoading = true;
        this.log(DEBUG,'calling doRetrieveAdminUsers');
        retrieveAllAdminUsers()
            .then((data) => {
                this.log(DEBUG,'admin users dto->', data);
                this.users = uiHelper.getMapValue(MAP_KEY_USER_WRAPS,data.values);
                this.userOptions = this.generateUserOptions(this.users);
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

    doRetrieveWestMonroeUsers() {
        this._isLoading = true;
        this.log(DEBUG,'calling doRetrieveWestMontroeUsers');
        retrieveWestMonroeUsers()
            .then((data) => {
                this.log(DEBUG,'west monroe users dto->', data);
                this.wmpUsers = uiHelper.getMapValue(MAP_KEY_USER_WRAPS,data.values);
                let tmpWmpUserSelections = [];
                this.wmpUsers.forEach( user => {
                   tmpWmpUserSelections.push(user.userId);
                });
                this.wmpUserOptions = this.generateUserOptions(this.wmpUsers);
                // this.dispatchEvent(new CustomEvent('select', {
                //     detail: {
                //         'name' :  'wmpUserSelect',
                //         'payloadType' : 'multi-select',
                //         'payload' : {'values' : tmpWmpUserSelections}
                //     }
                // }));

            })
            .catch((error) => {
                this.error = error;
                this.log(ERROR,'Error',error);
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading wmp users filter: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    generateUserOptions(users) {
        let userOptions;
        if(users) {
            let options = [];
            users.forEach(item => {
                let option = {label:item.userName, value:item.userId};
                options.push(option);
            });
            options = options.sort((a,b) =>  {
                return a.label < b.label ? -1 : 1;
            });
            userOptions = options;
        }
        return userOptions;
    }


    generateUserTypeOptions() {
        let plOptions = [
            {label:'-- Select One --', value:'-1', selected:true},
            {label:'System Admins', value:'systemadmins'},
            {label:'West Monroe Users',value:'westmonroe'}
        ];
        this.userTypeOptions = plOptions;
    }

    generateActionOptions() {
        this.actionOptions = plValuesHelper.getActionOptions();
    }

    generateDefaultDates() {
        this.selectedStartDateTimeValue = this.defaultStartDateTime;
        this.selectedEndDateTimeValue = this.defaultEndDateTime;
        this.dispatchEvent(new CustomEvent('startdatechange', {
            detail: {
                'name' :  'startdatechange',
                'payloadType' : 'date',
                'payload' : {
                    'value' : this.selectedStartDateTimeValue
                }
            }
        }));
        this.dispatchEvent(new CustomEvent('enddatechange', {
            detail: {
                'name' :  'enddatechange',
                'payloadType' : 'date',
                'payload' : {
                    'value' : this.selectedEndDateTimeValue
                }
            }
        }));
    }

    handleUserTypeSelect(evt) {
        const value = evt.target.value;
        this.selectedUserTypeValue = value;

        if(value === 'westmonroe') {
            let tmpWmpUserSelections = [];
            this.wmpUsers.forEach( user => {
                tmpWmpUserSelections.push(user.userId);
            });
            this.dispatchEvent(new CustomEvent('select', {
                detail: {
                    'name' :  'wmpUserSelect',
                    'payloadType' : 'multi-select',
                    'payload' : {'values' : tmpWmpUserSelections}
                }
            }));
        } else {
            this.dispatchEvent(new CustomEvent('select', {
                detail: {
                    'name' :  'userSelect',
                    'payloadType' : 'multi-select',
                    'payload' : {'values' : []}
                }
            }));
        }
    }

    handleDateChange(evt) {
        const field = evt.currentTarget.dataset.id;
        let evtName = '';
        let selectedDateValue;
        if(field === 'startdate') {
            this.selectedStartDateTimeValue = evt.target.value;
            evtName = 'startdatechange'
            selectedDateValue = this.selectedStartDateTimeValue;
        } else if (field === 'enddate') {
            evtName = 'enddatechange';
            this.selectedEndDateTimeValue = evt.target.value;
            selectedDateValue = this.selectedEndDateTimeValue;
        }
        this.dispatchEvent(new CustomEvent(evtName, {
            detail: {'name' :  evtName, 'payloadType' : 'date', 'payload' : {'value' :selectedDateValue}}
        }));
    }

    handleSelect(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                const classList = evt.currentTarget.classList;
                classList.add('lgc-highlight');
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
    handleOptionsRemoved(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                this.log(DEBUG,'forwarding option removed from recieved payload',payload);
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
    get isUserTypeSelected() {
        return this.selectedUserTypeValue && this.selectedUserTypeValue !== '-1';
    }
    get isAdminsUserTypeSelected() {
        return this.isUserTypeSelected && this.selectedUserTypeValue === 'systemadmins';
    }
    get isWmpUserTypeSelected() {
        return this.isUserTypeSelected && this.selectedUserTypeValue === 'westmonroe';
    }
    get isLoading() {
        let isIt =  !this.userOptions;
        return isIt;
    }
    get showStencil() {
        return this.isLoading;
    }

    get defaultStartDateTime() {
        let d = new Date();
        d = new Date(d.setDate(d.getDate()));
        d.setHours(0,0,0,0)
        return d.toISOString();
    }

    get defaultEndDateTime() {
        let d = new Date();
        return d.toISOString();
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