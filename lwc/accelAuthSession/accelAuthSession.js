import {LightningElement, wire, track, api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/accelAuthSessionUiHelper'
import Logger from 'c/logger'
import retrieveAuthSessions from '@salesforce/apex/AuthSessionController.retrieveAuthSessions';
import removeAuthSessions from '@salesforce/apex/AuthSessionController.removeAuthSessions';
import {dtHelper} from "./accelAuthSessionDtHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_AUTH_SESSION_WRAPS = 'AUTH_SESSION_WRAPS';
const MAX_RESULTS = 2000;
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

/**
 * AccelAuthSession will provide a secured user the ability to list all current auth sessions as well as
 * filter data via server searches and client side filters. It will also allow the removal of those
 * sessions i.e. Delete rows in the AuthSession sObject.
 */
export default class AccelAuthSession extends LightningElement {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api assistanceTitle = 'Auth Assistant'
    @api hideCardTitle;
    @api cardTitle = 'User Sessions';
    @api cardTitleSearch = 'Session Search';
    @api btnSearchLabel = 'Session Search';
    @api cardIcon = 'standard:omni_supervisor';

    @track dtRecords;
    @track dtRecordsFiltered;
    @track columns = dtHelper.getLogsColumns();
    @track dtClasses = dtHelper.getDtClasses()
    @track sortDirection = 'asc';
    @track sortBy = 'Name';

    @track defaultSelections = {};
    @track filterData = {};
    @track selectedRows;

    _debugConsole;
    _logger;
    _isLoading;
    _isExporting;
    _dataRefreshTime;
    _displayServerSideSearch;
    _displayFilters;
    _usersFilterApplied;
    _loginTypesFilterApplied;
    _sessionTypesFilterApplied;
    _selectedAuthSessionIds;

    /*
     *  The main params object passed to the server side search.
     */
    @track searchParams = {
        iLimit : MAX_RESULTS,
        userIds : [],
        sessionTypes : [],
        loginTypes : []
    }

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/accelAuthSession', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     * Generate default server side search selected options. Trigger an initial server side search.
     */
    connectedCallback() {
        this.generateDefaultFilterSelections();
        this.doRetrieveAuthSessions(this.searchParams);
        this.showAssistance = true;
    }

    /**
     * Delete selected auth session that were checked in the datatable. And retrigger a server side search.
     * @param params AuthSession.Id,AuthSession.Id
     */
    doDeleteSessions(params) {
        this._isLoading = true;
        this.log(DEBUG,'calling removeAuthSessions with ids:',params);
        removeAuthSessions( {authSessionIds:params} )
            .then((data) => {
                this.log(DEBUG, 'auth sessions remove dto->', data);
                this.refireQuery();
                uiHelper.showToast(this,'',data.message,data.severity);
            })
            .catch((error) => {
                this.error = error;
                this.log(ERROR,'Error',error);
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error deleting auth sessions: '+msg,'error');
            })
            .finally(() => {

            });
    }

    /**
     * Fire the server side search. Set both the dtRecords and dtRecordsFiltered variables.
     * @param params  A AuthSessionParams object.
     *
     * @see AuthSessionParams
     */
    doRetrieveAuthSessions( params ) {
        this._isLoading = true;
        this.log(DEBUG,'calling doRetrieveAuthSessions with params:',params);
        retrieveAuthSessions( {params:params} )
            .then((data) => {
                this.log(DEBUG, 'auth sessions dto->', data);
                this.dtRecords = uiHelper.getMapValue(MAP_KEY_AUTH_SESSION_WRAPS,data.values);
                this.dtRecordsFiltered = this.dtRecords;
                this._dataRefreshTime = new Date().getTime();
                if(this.dtRecords && this.dtRecords.length >= MAX_RESULTS) {
                    let msg = 'Your search retrieved the maximum of ' + MAX_RESULTS + ' items. Please refine your search.';
                    uiHelper.showToast(this, msg, msg, 'info');
                }
            })
            .catch((error) => {
                this.error = error;
                this.log(ERROR,'Error',error);
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading logs: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    /**
     * Re-fire the search while setting the search params obj.
     */
    refireQuery() {
        if(this.filterData) {
            this.searchParams.sessionTypes = this.filterData.sessionTypes;
            this.searchParams.userIds = this.filterData.users;
            this.searchParams.loginTypes = this.filterData.loginTypes;
            this.doRetrieveAuthSessions(this.searchParams);
        }
    }

    /**
     *
     * Handles a primary button onclick event and branches off appropriately.
     * @param event
     *
     */
    handleButtonClick(event){
        if(event && event.currentTarget && event.currentTarget.dataset) {
            const buttonId = event.currentTarget.dataset.id;
            switch (buttonId) {
                case 'rerunquery':
                    this.refireQuery();
                    break;
                case 'deletesessions':
                    this.handleDeleteSessions();
                    break;
            }
        }
    }

    /**
     * Call the removeSessions server side method with the selected checkbox ids.
     */
    handleDeleteSessions() {
        let msg = 'You have chosen to remove '+this.selectedRows.length + ' sessions. Are you sure?';
        uiHelper.showConfirm(msg,'default','Confirm Delete').then((res) => {
            if(res) {
                this.doDeleteSessions(this._selectedAuthSessionIds);
            }
        });
    }

    /**
     * Handle the refresh button icon click. Fire a server side search with stored parameters.
     * @param evt
     */
    handleRefresh(evt) {
        this._isLoading = true;
        this.doRetrieveAuthSessions(this.searchParams);
    }

    /**
     * Sort the datatable column. dispatch a dtsorted event in case a parent needs it.
     * @param evt
     */
    handleSort(evt){
        this.sortBy = evt.detail.fieldName;
        let tmpSortBy = this.sortBy;
        if(tmpSortBy === 'userLink') {
            tmpSortBy = 'userLastName';
        }
        this.sortDirection = evt.detail.sortDirection;
        this.log(DEBUG,'sort by',tmpSortBy);
        this.dtRecordsFiltered = dtHelper.sortData(tmpSortBy,this.sortDirection,this.dtRecordsFiltered);

        let payload = {sortBy:this.sortBy,sortDirection:this.sortDirection};
        this.dispatchEvent( new CustomEvent('dtsorted',{detail:payload}));
    }

    /**
     * User selected datatable rows via checkboxes.
     * @param evt
     */
    handleDtRowSelections(evt) {
        this.selectedRows = evt.detail.selectedRows;
        this._selectedAuthSessionIds = [];
        for (let i = 0; i < this.selectedRows.length; i++) {
            this._selectedAuthSessionIds.push(this.selectedRows[i].authSessionId);
        }
    }

    /**
     * Handle the server side search or client side filters button click.
     * @param evt
     */
    handleIconButtonClick(evt) {
        const buttonId = evt.currentTarget.dataset.iconbuttonid;
        this.log(DEBUG,'buttonId',buttonId);
        switch (buttonId) {
            case 'btnDisplaySearch':
                this._displayServerSideSearch = !this._displayServerSideSearch;
                break;
            case 'btnDisplayFilters':
                this._displayFilters = !this._displayFilters;
                break;
        }
    }

    /**
     * User clicked clear icon (x) on filters input.
     * @param evt
     */
    handleClear(evt) {
        const filterId = evt.currentTarget.dataset.filterid;
        if(!evt.target.value.length) {
            switch (filterId) {
                case 'filterUsers':
                    this._usersFilterApplied = null;
                    break;
                case 'filterLoginTypes':
                    this._loginTypesFilterApplied = null;
                    break;
                case 'filterSessionTypes':
                    this._sessionTypesFilterApplied = null;
                    break;
            }
        }
    }

    /**
     * Handle the user typing in the client side filters input.
     * @param event
     */
    handleDtSearchKeyChange(event) {
        const searchKey = event.target.value;
        const filterId = event.currentTarget.dataset.filterid;
        if(searchKey && searchKey.length > 1){
            let filterField = '';
            switch (filterId) {
                case 'filterUsers':
                    filterField = 'userFullName';
                    this._usersFilterApplied = searchKey;
                    break;
                case 'filterLoginTypes':
                    filterField = 'loginType';
                    this._loginTypesFilterApplied = searchKey;
                    break;
                case 'filterSessionTypes':
                    filterField = 'sessionType';
                    this._sessionTypesFilterApplied = searchKey;
                    break;
            }

            //this.dtLoading = true;
            this.dtRecordsFiltered = this.dtRecordsFiltered.filter((item) => {
                return item[filterField].toLowerCase().includes(searchKey.toLowerCase());
            });
            //this.dtLoading = false;
        } else {
            //this.dtRecordsFiltered = this.dtRecords;
        }
    }

    /**
     * User closed the server side search.
     * @param evt
     */
    handleSearchClose(evt) {
        this._displayServerSideSearch = false;
    }

    /**
     * Server side search value selected in child cmp.
     * @param evt
     */
    handleFilterSelect(evt) {
        this.log(DEBUG,'evt select', evt.detail);
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                switch (evt.detail.name) {
                    case 'sessionTypeSelect':
                        this.filterData.sessionTypes = payload.values;
                        break;
                    case 'userSelect':
                        this.filterData.users = payload.values;
                        break;
                    case 'loginTypeSelect':
                        this.filterData.loginTypes = payload.values;
                        break;
                }
            }
        }
    }

    /**
     * Server side search value removed in child cmp.
     * @param evt
     */
    handleFilterRemove(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload && payload.optionsRemoved) {
                switch (evt.detail.name) {
                    case 'sessionTypeSelect':
                        this.filterData.sessionTypes = this.filterData.sessionTypes.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                    case 'userSelect':
                        this.filterData.users = this.filterData.users.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                    case 'loginTypeSelect':
                        this.filterData.loginTypes = this.filterData.loginTypes.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                }
            }
        }
    }

    handleDatatableExport(evt) {
        const payload = evt.detail;
        if (payload) {
            this._isExporting = payload.exporting;
        }
    }

    generateDefaultFilterSelections() {
        this.defaultSelections.sessionTypes = ['UI'];
        this.defaultSelections.users = [];
        this.defaultSelections.loginTypes = [];
        this.searchParams.sessionTypes = this.defaultSelections.sessionTypes;
        this.filterData = this.defaultSelections;
    }


    get helpBulletPoints() {
        let  arr = [];
        let msg;
        if(!this._displayServerSideSearch) {
            msg = 'Click the Search icon to expand / reduce your results (this is a real time search).';
            arr.push({text: msg, severity: 'info'});
        } else {
            if(!this.filterData) {
                msg = 'Select your search criteria and hit the ' + this.btnSearchLabel + ' to initiate your search.';
                arr.push({text: msg, severity: 'info'});
            }
            msg = 'Click the Search icon again (or the close icon) to close the search section (search filters are saved).';
            arr.push({text: msg, severity: 'info'});
        }
        if(this.showDataTable && this.dtRecordsFiltered && this.numberOfFilteredResults > 0) {
            msg = 'Click the Filter icon above the table to further filter your results.';
            arr.push({text: msg, severity: 'info'});
            msg = 'Click the Column Headers to sort your data.';
            arr.push({text: msg, severity: 'info'});
        }
        if(this.showExportIcon) {
            msg = 'Click the XLS icon above the table export the results to a .csv file.';
            arr.push({text: msg, severity: 'info'});
        }
        if(!this.showRemoveAuthSessionsBtn && this.showDataTable && this.dtRecordsFiltered && this.numberOfFilteredResults > 0) {
            msg = 'Select sessions to remove via clicking the checkbox(s).';
            arr.push({text: msg, severity: 'info'});
        }

        msg = 'Click the Refresh icon to refresh your results form the server using your current search criteria';
        arr.push({text: msg, severity: 'info'});
        return arr;
    }

    get selectedSessionsButtonLabel() {
        return 'Remove ' + this.selectedRows.length + ' sessions';
    }

    get showRemoveAuthSessionsBtn() {
        return !this._isLoading && this.numberOfFilteredResults > 0 && this.selectedRows && this.selectedRows.length > 0;
    }

    get searchIconClass() {
        return this._displayServerSideSearch ? 'accel-blue-icon' : '';
    }

    get searchIconLabel() {
        return this._displayServerSideSearch ? 'Hide Search' : 'Display Search';
    }

    get showDataTable() {
        return !this._isLoading && !this._isExporting && this.dtRecords;
    }
    get showProgressBar() {
        return this._isLoading || this._isExporting;
    }
    get showStencil() {
        return this._isLoading || this._isExporting;
    }
    get dtKeyField() {
        return 'authSessionId';
    }
    get numberOfResults() {
        return this.dtRecords ? this.dtRecords.length : 0;
    }
    get numberOfFilteredResults() {
        return this.dtRecordsFiltered ? this.dtRecordsFiltered.length : 0;
    }

    get showFiltersHeader() {
        return this.showFilters || this.filtersApplied;
    }
    get showFilters() {
        return this._displayFilters;
    }

    get filtersApplied() {
        return !this._isLoading && this.numberOfFiltersApplied > 0;
    }

    get filtersTheme() {
        return this.filtersApplied ? 'slds-theme_alert-texture' : 'slds-theme_shade';
    }

    get disableSearchButton() {
        return this._isLoading;
    }

    get clientSideFiltersIconTooltip() {
        return this._displayFilters ? 'Hide datatable filters' : 'Display datatable filters';
    }

    get numberOfFiltersApplied() {
        let num = 0;
        if(this._loginTypesFilterApplied) {
            num++;
        }
        if(this._sessionTypesFilterApplied) {
            num++;
        }
        if(this._usersFilterApplied) {
            num++;
        }
        return num;
    }

    get showExportIcon() {
        return this.numberOfFilteredResults > 0;
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