import {LightningElement, api, track} from 'lwc';
import {loadScript} from "lightning/platformResourceLoader";
import CSVPARSER from '@salesforce/resourceUrl/papaparse';
import Logger from "c/logger";
import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import {exportHelper} from "./geoTabAdminDevicesExportHelper";

const GLOBAL_CONSTANTS                          = getConstants();
const PAPAPARSE_LIBPATH                         = '/lib/papaparse.js';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class GeoTabAdminDevicesExport extends LightningElement {
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    @api btnVariant = 'brand';
    @api btnLabel = 'Csv Export';
    @api btnTitle = 'Click here to export the details to a csv file.';
    @api btnIconName = 'utility:download';
    @api exportData;

    @track csvColHeaders;
    @track csvColData;

    _debugConsole;
    _logger;
    _parserLoaded;
    _isExporting;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/geoTabAdminDevicesExport', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     *  Loads the papa parse csv parser library.
     */
    connectedCallback() {
        this.loadParser();
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
            let fileName = 'GeoTab_Devices_Export_'+ sDate + '.csv';
            let downloadElement = document.createElement('a');
            downloadElement.href = `data:text/csv;charset=utf-8,${encodeURIComponent(csvString)}`;
            downloadElement.target = '_self';
            downloadElement.download = fileName;
            document.body.appendChild(downloadElement);
            downloadElement.click();
            this.csvColData = [];
        } catch (e) {
            uiHelper.showToast(this,'Error','Error creating csv '+e,'error');
            console.error(e);
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

    doExportData() {
        this._isExporting = true;
        this.fireExportingEvent(this._isExporting);
        exportHelper.generateExport(this.exportData,this);
        let csv = this.createCsv();
        this.downloadToBrowser(csv);
        this.log(DEBUG,'---> geoTabAdminDevicesExport',csv);
        this._isExporting = false;
        this.fireExportingEvent(this._isExporting);
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
                    this.log(DEBUG, '---> doExportData');
                    this.doExportData();
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
                this.log(DEBUG,'---> papaparser loaded');
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