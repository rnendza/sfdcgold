import {LightningElement, api, track, wire} from 'lwc';
import retrievePaAdvisoryDetail from '@salesforce/apex/PaAdvisoryGalleryController.retrievePaAdvisoryDetail';
import {uiHelper} from "c/portalAdminUtilsUiHelper";
import Logger from 'c/logger'
import {getConstants} from "c/clConstantUtil";


const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_ADVISORY_RECORD      = 'ADVISORY_RECORD';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class PaAdvisoryUserDetails extends LightningElement {

    @api cancelLabel;
    @api cancelIconName;
    @api cancelVariant = 'neutral';
    @api visible;
    @api headerIcon;
    @api name;


    @api
    set originalMessage(val) {
        this._originalMessage = val;
        this.paAdvisoryId = val;
    }
    get originalMessage() { return this._originalMessage;}

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @track paAdvisoryId;
    @track paAdvisory;

    _originalMessage;
    _wiredRecordDto;
    _logger;
    _debugConsole;
    _isSearching;

    constructor() {
        super();
        console.info('%c----> /lwc/paAdvisoryUserDetails', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isSearching = true;
    }


    @wire(retrievePaAdvisoryDetail,{paAdvisoryId: '$paAdvisoryId'})
    wiredState(wiredData) {
        this._wiredRecordDto = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.paAdvisory= uiHelper.getMapValue(MAP_KEY_ADVISORY_RECORD,data.values);
                this.log(DEBUG,'paAdvisory-->',this.paAdvisory);
                // this.generateAssistanceBulletPoints();
            } else {
                this.log(DEBUG,'dto-->',this.data);
            }
            this._isSearching = false;
        } else if (error) {
            console.error(error);
            this._isSearching = false;
        }
    }

    handleClick(event){
        let finalEvent = {originalMessage: this.originalMessage, status: event.target.name};
        this.dispatchEvent(new CustomEvent('modalaction', {detail: finalEvent}));
    }

    hideModalBox(evt) {
        let finalEvent = {originalMessage: this.originalMessage, status: evt.target.name};
        this.dispatchEvent(new CustomEvent('modalaction', {detail: finalEvent}));
    }

    get showUserDetails() {
        return this.paAdvisory;
    }

    get showStencil() {
        return this._isSearching;
    }

    get modalTitle() {
        let title = 'Advisory # ';
        title+= this.paAdvisory ? this.paAdvisory.Advisory_Number__c : '';
        return title;
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