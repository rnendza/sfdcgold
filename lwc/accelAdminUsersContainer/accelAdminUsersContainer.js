import {LightningElement,api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
const GLOBAL_CONSTANTS = getConstants();

export default class AccelAdminUsersContainer extends LightningElement {
    @api debugConsole;
    @api showAssistance;

    _activeTabValue = 'tab_utils_auth_sessions';

    constructor() {
        super();
        console.info('%c----> /lwc/accelAdminUsersContainer', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.debugConsole = true;
        this.showAssistance = true;
    }

    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
    }

    handleModuleSelected(evt) {

    }
}