import {LightningElement, api, wire} from 'lwc';
import {getConstants} from "c/clConstantUtil";
import AccelUtilsSvc from 'c/accelUtilsSvc';

const DISPLAY_TYPE_TILE = 'Tile';
const DISPLAY_TYPE_LIST = 'List';
const GLOBAL_CONSTANTS = getConstants();

export default class AccountAssets extends LightningElement {

    @api recordId;
    @api cardTitle;
    @api cardIcon;
    @api displayType;
    @api parentAccountApiName;
    @api accountFieldsToDisplay;
    @api showVgtInfoFields;
    @api showRtInfoFields;
    @api showAssetLink;
    @api assetNameMaxLength;
    @api showMsgIfNoMachines;
    @api debugConsole;

    _accelUtils = new AccelUtilsSvc(this.debugConsole);

    connectedCallback() {
        if(this.debugConsole) {
            console.info('%c----> /lwc/accountAssets', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        }
    }

    get displayTile() {
        return this.displayType && this.displayType === DISPLAY_TYPE_TILE;
    }
    get displayList() {
        return  this.displayType && this.displayType === DISPLAY_TYPE_LIST;
    }

}