import {LightningElement,track,api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
import Logger from 'c/logger'
import {uiHelper} from "c/accelAuthSessionUiHelper";
import {plValuesHelper} from "./accelAuthSessionFiltersPlValues";
import retrieveAllActiveLoggedInUsers from '@salesforce/apex/AuthSessionController.retrieveActiveLoggedInUsers';

const   GLOBAL_CONSTANTS            = getConstants();
const   MAP_KEY_USER_WRAPS             = 'USER_WRAPS';
const   ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class AccelSecurityAuditFilters extends LightningElement {

    @api defaultSelections;
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}


    @track pillIcon;
    @track userPillIcon;
    @track loginTypePillIcon;
    @track sessionTypePillIcon;

    @track userOptions;
    @track loginTypeOptions;
    @track sessionTypeOptions;
    @track defaultSessionTypeSelections;
    @track defaultLoginTypeSelections;
    @track defaultUserSelections;
    @track authSessionObjectInfo;
    @track users;

    _debugConsole;

    constructor() {
        super();
        console.info('%c----> /lwc/accelAuthSessionFilters',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
        this.doRetrieveActiveLoggedInUsers();
    }

    connectedCallback() {
        if(this.defaultSelections) {
            this.defaultSessionTypeSelections = this.defaultSelections.sessionTypes;
            this.defaultLoginTypeSelections = this.defaultSelections.loginTypes;
            this.defaultUserSelections = this.defaultSelections.users;
            this.sessionTypePillIcon = 'standard:sobject';
            this.userPillIcon = 'standard:user';
            this.loginTypePillIcon = 'custom:custom77';
            this.generateSessionTypeOptions();
            this.generateLoginTypeOptions();
            this.log(DEBUG,'---> cc default selections',this.defaultSelections);
        }
    }

    doRetrieveActiveLoggedInUsers() {
        this._isLoading = true;
        this.log(DEBUG,'calling doRetrieveActiveLoggedInUsers:');
        retrieveAllActiveLoggedInUsers()
            .then((data) => {
                this.log(DEBUG,'logged in users dto->', data);
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

    generateSessionTypeOptions() {
        this.sessionTypeOptions = plValuesHelper.getSessionTypeOptions();
    }

    generateLoginTypeOptions() {
        this.loginTypeOptions = plValuesHelper.getLoginTypePlOptions();
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
        let isIt =  !this.sessionTypeOptions;
        return isIt;
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