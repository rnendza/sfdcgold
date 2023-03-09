import {LightningElement, api, track,wire} from 'lwc';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {getConstants} from "c/clConstantUtil";

const GLOBAL_CONSTANTS = getConstants();

export default class ClTimestamper extends LightningElement {


    @api assistanceType;
    @api assistanceIconClass = 'accel-assistance-info-icon';
    @api title;
    @api helpIconSize = 'small';
    @api helpIconName = 'utility:info';
    @api buttonHelpText = '';
    @api buttonIconName = 'utility:save';
    @api buttonLabel = '';
    @api originalMessage;

    @track disableButton;

    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    constructor() {
        super();
        console.info('%c----> /lwc/clTimestamper',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    handleSubmitDateButton(evt) {
        this.disableButton = true;
        let finalEvent = { originalMessage: this.originalMessage };
        this.dispatchEvent(new CustomEvent('dateclickaction', {detail: finalEvent}));
    }

    get showButtonHelpText() {
        return this.buttonHelpText;
    }
}