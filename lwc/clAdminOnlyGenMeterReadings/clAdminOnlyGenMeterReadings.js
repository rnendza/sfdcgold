import {LightningElement,api,track} from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import Logger from 'c/logger'
import {uiHelper} from './clAdminOnlyGenMeterReadingsUiHelper';
import doCreateMeters from '@salesforce/apex/clAdminOnlyGenMeterReadingsController.doCreateMeterReadings';
import doRetrieveRps from '@salesforce/apex/clAdminOnlyGenMeterReadingsController.doRetrieveRps';
import {reduceErrors} from "c/ldsUtils";
import {getConstants} from "c/clConstantUtil";

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.
const MAP_KEY_METERS = 'MAP_KEY_METERS';
const MAP_KEY_RPS = 'MAP_KEY_RPS';
const GLOBAL_CONSTANTS = getConstants();

/**
 *  This class will allow an administrator to generate meter readings for a parent RPS Record.
 *  Supports Record Page only. 
 */
export default class ClAdminOnlyGenMeterReadings extends LightningElement {

    @api recordId;  //  In context by virtue of being on the record page.
    @api            //  Admin configurable prop.
    get debugConsole() {
        return this._debugConsole;
    }
    set debugConsole(value) {
        this._debugConsole = value;
        this._logger = new Logger(this._debugConsole);
    }

    @track rpsRecord;
    @track metersInserted;

    _isProcessing;
    _createdMeters;
    _debugConsole;
    _logger;

    constructor() {
        super();
    }

    /**
     * Fire stencils / progress indicators and retrieve the route_Processing_Sheet__c.
     */
    connectedCallback() {
        console.log('%c----> /lwc/clAdminOnlyGenMeterReadings',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isProcessing = true;
        this.retrieveRps();
    }

    /**
     * Imperative retrieval of the Route_Processing_Sheet__c record with the recordId in context.
     */
    retrieveRps () {
        let params = { rpsId:this.recordId };
        this.log(DEBUG,'retrieving rps',params);
        doRetrieveRps(params)
            .then((result) => {
                this._isProcessing = false;
                if(result.isSuccess) {
                    this.rpsRecord = uiHelper.getMapValue(MAP_KEY_RPS,result.values);
                    this.log(DEBUG,'--> rps result',result);
                } else {
                    this.log(WARN,'--> rps result',result);
                }
                this._isProcessing = false;
            })
            .catch((error) => {
                this._isProcessing = false;
                console.error(error);
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'',this.error,'error','pester');
            });
    }

    /**
     * Handle the click of the create button / call the insert for Meter Readings.
     * @param evt
     */
    handleMeterCreationClick(evt) {
        this._isProcessing = true;
        this.createMeters();
    }

    /**
     * Imperative Insert of meter readings for the RPS Id and then retrieve the parent RPS Record. Try to force
     * of refresh of the standard page.
     */
     createMeters () {
        let params = { rpsId:this.recordId };
        doCreateMeters(params)
            .then((result) => {
                this.log(DEBUG,'--> meters results',result);
                if(result.isSuccess) {
                    this._createdMeters = true;
                    this.metersInserted = uiHelper.getMapValue(MAP_KEY_METERS,result.values);
                    let msg = this.metersInserted.length + ' Meters successfully created.';
                    uiHelper.showToast(this,'',msg,'success');
                    this.retrieveRps();
                    this.handleRefresh(this.metersInserted);
                    this.log(DEBUG,'---> meters inserted',this.metersInserted);
                } else {
                    this.log(WARN,'--> meters results',result);
                }
            })
            .catch((error) => {
                this._isProcessing = false;
                console.error(error);
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'',this.error,'error','pester');
            });
    }

    /**
     * We are trying to use lds to refresh the related list but it doesn't appear to support inserts so
     * force an entire page refresh as well.
     *
     * @param metersInserted
     */
    handleRefresh(metersInserted) {
        let insertedRecordIds = [];
        metersInserted.forEach(record => {insertedRecordIds.push(record.Id);});
        const insertedRecords = insertedRecordIds.map(recId => {return { 'recordId': recId };});
        getRecordNotifyChange(insertedRecords); // might not work for inserts.
        try {
            eval("$A.get('e.force:refreshView').fire();"); // use a hammer.. refresh the entire page.
        } catch (e) {
            console.error(e);
        }
    }

    get disableButton() {
        return this._isProcessing;
    }
    get showGenerateButton() {
        return !this.metersExist;
    }
    get showMeterCreationHelp() {
        return !this._isProcessing && !this.metersExist;
    }
    get showMetersAlreadyCreatedMessage() {
        return this.metersExist;
    }
    get showStencil() {
        return this._isProcessing;
    }
    get cardSubTitle() {
        return this.rpsRecord && this.rpsRecord.Name;
    }
    get showProgressBar() {
        return this._isProcessing;
    }
    get metersExist() {
        return this.rpsRecord && this.rpsRecord.Total_Meter_Readings__c > 0;
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