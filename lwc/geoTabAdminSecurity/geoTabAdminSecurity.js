import {LightningElement, wire, track, api} from 'lwc';

import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/geoTabAdminUiHelper'
import Logger from 'c/logger'
import retrieveAuthMdt from '@salesforce/apex/GeoTabApiController.retrieveAuthMdt';
import retrieveCacheAuthMdt from '@salesforce/apex/GeoTabApiController.retrievePlatformCacheAuth';
import {NavigationMixin} from "lightning/navigation";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_AUTH_MDT                = 'AUTH_MDT';
const MAP_KEY_AUTH_MDT_URL            = 'AUTH_MDT_URL';
const MAP_KEY_AUTH_CACHE              = 'AUTH_CACHE';
const MAP_KEY_CACHE_SETUP_URL         = 'AUTH_CACHE_URL';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.


export default class GeoTabAdminSecurity extends NavigationMixin(LightningElement) {
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api assistanceTitle = 'Security Assistant'
    @api cardTitle = 'GeoTab Security';

    @track devicesStatusInfo;
    @track secBulletPoints;
    @track serviceResources;
    @track mdtAuth;
    @track mdtSetupUrl;
    @track platformCacheUrl;
    @track cachedCreds;

    _debugConsole;
    _logger;
    _isLoading;
    _dataRefreshTime;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/geoTabAdminSecurity', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this.showAssistance = true;
    }

    connectedCallback() {
        this.retrieveAuthMdt();
    }


    retrieveAuthMdt() {
        this._isLoading = true;
        retrieveAuthMdt( )
            .then((data) => {
                this.log(DEBUG, 'auth mdt dto->', data);
                this.mdtAuth = uiHelper.getMapValue(MAP_KEY_AUTH_MDT,data.values);
                this.mdtSetupUrl = uiHelper.getMapValue(MAP_KEY_AUTH_MDT_URL,data.values);
                this.platformCacheUrl = uiHelper.getMapValue(MAP_KEY_CACHE_SETUP_URL,data.values);
                this.log(DEBUG, 'mdt setupurl:'+this.mdtSetupUrl);
                this.retrieveCacheAuthMdt();
                this._dataRefreshTime = new Date().getTime();
            })
            .catch((error) => {
                this._isLoading = false;
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading auth mdt: '+msg,'error');
            })
            .finally(() => {
            });
    }

    retrieveCacheAuthMdt() {
        this._isLoading = true;
        retrieveCacheAuthMdt( )
            .then((data) => {
                this.log(DEBUG, 'cache auth mdt dto->', data);
                this.cachedCreds = uiHelper.getMapValue(MAP_KEY_AUTH_CACHE,data.values);
                this._dataRefreshTime = new Date().getTime();
            })
            .catch((error) => {
                this.error = error;
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading cached auth mdt: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
                this.generateAssistanceBulletPoints();
            });
    }

    handleRefresh(evt) {
        this._isLoading = true;
        this.retrieveAuthMdt();
    }

    handleBtnClick(evt) {
        if (evt && evt.currentTarget && evt.currentTarget.dataset) {
            const buttonId = evt.currentTarget.dataset.id;
            switch (buttonId) {
                case 'btnEditCustomMetaData':
                    uiHelper.navigateToWebViewNewWindow(this,this.mdtSetupUrl);
                    break;
                case 'btnEditPlatformCache':
                    uiHelper.navigateToWebViewNewWindow(this,this.platformCacheUrl);
                    break;
            }
        }
    }


    /**
     * Bullet points for child assistant / help cmp.
     */
    generateAssistanceBulletPoints() {
        this.secBulletPoints = [];

        let msg = 'Cache will be written to upon the 1st successful auth with the GeoTab API. The session Id will exist';
        msg+= ' in platform cache in SFDC in 48 hours and then expire. The Session Id is valid with GeoTab for 2 weeks.';
        this.secBulletPoints.push({text: msg, severity: 'info'});

        msg = 'Hit the Refresh Button in the Top Right corner to retrieve the latest security information.';
        this.secBulletPoints.push({text: msg, severity: 'info'});
        if(this.showData) {
            msg = 'Hit the Edit buttons to edit the respective security data. You will be redirected to the standard setup pages.';
            this.secBulletPoints.push({text: msg, severity: 'info'});
            msg = 'The Custom Metadata is location in Api_Setting__mdt';
            this.secBulletPoints.push({text: msg, severity: 'info'});
            msg = 'The session Id for GeoTab is cached in SFDC Platform Cache.';
            this.secBulletPoints.push({text: msg, severity: 'info'});
        }
    }
    get showAuthMdtData() {
        return this.mdtAuth && !this._isLoading;
    }
    get showData() {
        return !this._isLoading && (this.showAuthMdtData || this.showCachedCredsData);
    }
    get showCachedCredsData() {
        return this.cachedCreds && !this._isLoading;
    }
    get showDataTable() {
        return !this._isLoading && this.dtRecords;
    }
    get showProgressBar() {
        return this._isLoading;
    }
    get showStencil() {
        return this._isLoading;
    }
    get dtKeyField() {
        return 'deviceId';
    }
    get showMetadataEditButton() {
        return true;
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