import {LightningElement, api, track} from 'lwc';
import {loadScript} from "lightning/platformResourceLoader";
import CSVPARSER from '@salesforce/resourceUrl/papaparse';
import Logger from "c/logger";
import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/portalAdminUtilsUiHelper'
import {exportHelper} from "./paAdvisoryExportHelper";
import retrieveExportData from '@salesforce/apex/PaAdvisoryGalleryController.retrievePaAdvisoriesExportData';

const GLOBAL_CONSTANTS                          = getConstants();
const MAP_KEY_ADVISORY_EXPORT                   = 'ADVISORY_EXPORT';
const PAPAPARSE_LIBPATH                         = '/lib/papaparse.js';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

/**
 * Generates a csv export of ALL Pa_Advisory__c data. using an _searchParms param object for any future filters.
 */
export default class PaAdvisoryExport extends LightningElement {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    @api btnVariant = 'brand';
    @api btnLabel = 'Csv Export';
    @api btnTitle = 'Click here to export the details to a csv file.';
    @api btnIconName = 'utility:download';

    @track _searchParams = { iLimit: 50000, isVisible: true};
    @track csvColHeaders;
    @track csvColData;

    _debugConsole;
    _logger;
    _parserLoaded;
    _isExporting;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/paAdvisoryExport', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     *  Loads the papa parse csv parser library.
     */
    connectedCallback() {
        this.loadParser();
    }

    /**
     * Fire an event to inform the parent cmp an export is occurring.
     * Call the server side SOQL to retrieve the data.
     * Parse the data so it's suitable for Papa Parser.
     * Trigger a browser download.
     *
     * @param params  The params object  sent to the server ie.  { iLimit: 50000, isVisible: true};
     */
    doRetrieveExportData(params) {
        this._isExporting = true;
        this.fireExportingEvent(this._isExporting);
        retrieveExportData( params )
            .then((data) => {
                let rawExportData = uiHelper.getMapValue(MAP_KEY_ADVISORY_EXPORT,data.values);
                exportHelper.generateExport(rawExportData,this);
                let csv = this.createCsv();
                this.downloadToBrowser(csv);
                this.log(DEBUG,'---> advisoryExportData',rawExportData);
                this._isExporting = false;
                this.fireExportingEvent(this._isExporting);
            })
            .catch((error) => {
                this._isExporting = false;
                this.fireExportingEvent(this._isExporting);
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showAlert(msg,'error','');
                this._isScrolling = false;
            });
    }

    /**
     * Tell papa parse to create a proper csv string.
     * @returns {*}  a csv String
     */
    createCsv() {
        let csv = Papa.unparse( {"fields" : this.csvColHeaders, "data" : this.csvColData});
        return csv;
    }

    /**
     * Format the file name and fake a hidden link click to download to the browser.
     * @param csvString  The csvString to download to browser.
     */
    downloadToBrowser(csvString) {
        try {
            let dFormatter = new Intl.DateTimeFormat('en-US');
            let sDate = dFormatter.format(new Date());
            let fileName = 'PA_Exclusions_Export_'+ sDate + '.csv';
            let downloadElement = document.createElement('a');
            downloadElement.href = `data:text/csv;charset=utf-8,${encodeURIComponent(csvString)}`;
            downloadElement.target = '_self';
            downloadElement.download = fileName;
            document.body.appendChild(downloadElement);
            downloadElement.click();
            this.csvColData = [];
        } catch (e) {
            alert(e);
        }
    }

    /**
     * Fire an event to the parent so it can deal with progress indicators.
     * @param isExporting  true if exporting / otherwise false.
     */
    fireExportingEvent(isExporting) {
        let payload = {exporting:isExporting};
        this.dispatchEvent( new CustomEvent('export',{detail:payload}));
    }

    /**
     * Capture button click and formulate and download the export.
     * @param event
     */
    handleButtonClick(event) {
        if (event && event.currentTarget && event.currentTarget.dataset) {
            const buttonId = event.currentTarget.dataset.id;
            switch (buttonId) {
                case 'export':
                    let params = {searchParams: this._searchParams};
                    this.log(DEBUG, '---> doRetrieveExportData with params', params);
                    this.doRetrieveExportData(params);
                    break;
            }
        }
    }

    /**
     * Loads papa parse.
     */
    loadParser() {
        loadScript(this, CSVPARSER + PAPAPARSE_LIBPATH)
            .then(() => {
                console.info('---> papaparser loaded');
                this._parserLoaded = true;
            })
            .catch(error => {
                uiHelper.showToast(this,'Error','Error loading parser '+error,'error');
            })
            .finally(() => {

            });
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