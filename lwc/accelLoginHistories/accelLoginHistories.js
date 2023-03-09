import {LightningElement, wire, track, api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/accelLoginHistoryUiHelper'
import Logger from 'c/logger'
import retrieveLoginHistories from '@salesforce/apex/LoginHistoryController.retrieveLoginHistories';
import {dtHelper} from "./accelLoginHistoriesDtHelper";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_LOGIN_HISTORY_WRAPS      = 'LOGIN_HISTORY_WRAPS';
const MAX_RESULTS = 600;
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class AccelLoginHistories extends LightningElement {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api showAssistance;
    @api assistanceTitle = 'Login History Assistant'
    @api cardTitle = 'Login History';
    @api hideCardTitle;
    @api cardTitleSearch = 'Login History Search';
    @api btnSearchLabel = 'Login History Search';
    @api cardIcon = 'standard:asset_audit';
    @api defaultSearchToOpen;

    @track dtRecords;
    @track dtRecordsFiltered;
    @track columns = dtHelper.getAuditTrailsColumns();
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
    _statusesFilterApplied;
    _platformsFilterApplied;

    /*
     *  The main params object passed to the server side search.
     */
    @track searchParams = {
        iLimit : MAX_RESULTS,
        userIds : [],
        startDate : null,
        endDate : null,
    }



    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/accelLoginHistories', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     * Generate default server side search selected options. Trigger an initial server side search.
     * Auto open search if the parent requests it.
     */
    connectedCallback() {
        this.generateDefaultFilterSelections();
        this.doRetrieveLoginHistories(this.searchParams);
        this.showAssistance = false;
        //uiHelper.showToast(this,'','DEV IN PROGRESS','info');
       // this._displayServerSideSearch = this.defaultSearchToOpen;
    }


    doRetrieveLoginHistories( params ) {
        this._isLoading = true;
        this.log(DEBUG,'calling doRetrieveLoginHistories with params:',params);
        retrieveLoginHistories( {params:params} )
            .then((data) => {
                this.log(DEBUG, 'login histories dto->', data);
                this.dtRecords = uiHelper.getMapValue(MAP_KEY_LOGIN_HISTORY_WRAPS,data.values);
                this.dtRecordsFiltered = this.dtRecords;
                this._dataRefreshTime = new Date().getTime();
                if(this.dtRecords && this.dtRecords.length >= MAX_RESULTS) {
                    let msg = 'Your search retrieved the maximum of ' + MAX_RESULTS + ' items (for performance reasons). Please refine your search.';
                    uiHelper.showToast(this, '',msg, 'info');
                }
            })
            .catch((error) => {
                this.error = error;
                this.log(ERROR,'Error',error);
                let msg = this.error;
                if(this.error.body) {
                    msg = this.error.body.message;
                }
                uiHelper.showToast(this,'','Error loading login history records: '+msg,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    /**
     * Re-fire the search while setting the search params obj.
     */
    refireQuery() {
        this.log(DEBUG,'refirequery checkcing filterdata',this.filterData);
        if(this.filterData) {
            this.searchParams.userIds = this.filterData.users;
            this.searchParams.startDate = this.filterData.startDate;
            this.searchParams.endDate = this.filterData.endDate;
            this.doRetrieveLoginHistories(this.searchParams);
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
            this.log(DEBUG,'buttonIdclicked',buttonId);
            switch (buttonId) {
                case 'rerunquery':
                    this.refireQuery();
                    break;
            }
        }
    }

    /**
     * Handle the refresh button icon click. Fire a server side search with stored parameters.
     * @param evt
     */
    handleRefresh(evt) {
        this._isLoading = true;
        this.doRetrieveLoginHistories(this.searchParams);
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
     * @todo possible defect here.
     */
    handleClear(evt) {
        const filterId = evt.currentTarget.dataset.filterid;
        if(!evt.target.value.length) {
            switch (filterId) {
                case 'filterUsers':
                    this._usersFilterApplied = null;
                    break;
                case 'filterStatuses':
                    this._statusesFilterApplied = null;
                    break;
                case 'filterPlatforms':
                    this._platformsFilterApplied = null;
                    break;
            }
            if(this._usersFilterApplied || this._statusesFilterApplied || this._platformsFilterApplied) {
                this.dtRecordsFiltered = this.dtRecordsFiltered.filter((item) => {
                    return item.userFullName.toLowerCase().includes(this._usersFilterApplied.toLowerCase())
                        || item.loginStatus.toLowerCase().includes(this._statusesFilterApplied.toLowerCase())
                        || item.platform.toLowerCase().includes(this._platformsFilterApplied.toLowerCase());
                });
            } else {
                this.dtRecordsFiltered = this.dtRecords;
            }
        }
    }

    /**
     * Handle the user typing in the client side filters input.
     * @param event
     *
     * @todo possible defects here.
     */
    handleDtSearchKeyChange(event) {
        const searchKey = event.target.value;
        const filterId = event.currentTarget.dataset.filterid;
        let filterField = '';
        switch (filterId) {
            case 'filterUsers':
                filterField = 'userFullName';
                this._usersFilterApplied = searchKey;
                break;
            case 'filterStatuses':
                filterField = 'loginStatus';
                this._statusesFilterApplied = searchKey;
                break;
            case 'filterPlatforms':
                filterField = 'platform';
                this._platformsFilterApplied = searchKey;
                break;
        }

        if(searchKey && searchKey.length > 1){
            try {
                this.dtRecordsFiltered = this.dtRecordsFiltered.filter((item) => {
                    return item.userFullName.toLowerCase().includes(searchKey.toLowerCase())
                        || item.loginStatus.toLowerCase().includes(searchKey.toLowerCase())
                        || item.platform.toLowerCase().includes(searchKey.toLowerCase());
                });
            } catch (e) {
                this.log(ERROR,'error during filtering',e);
            }
        } else {
            if(this._usersFilterApplied || this._statusesFilterApplied || this._actionsFilterApplied) {
                this.dtRecordsFiltered = this.dtRecordsFiltered.filter((item) => {
                    return item.userFullName.toLowerCase().includes(searchKey.toLowerCase())
                        || item.loginStatus.toLowerCase().includes(searchKey.toLowerCase())
                        || item.platform.toLowerCase().includes(searchKey.toLowerCase());
                });
            } else {
                this.dtRecordsFiltered = this.dtRecords;
            }
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
                    case 'actionSelect':
                        this.filterData.actions = payload.values;
                        break;
                    case 'userSelect':
                        this.filterData.users = payload.values;
                        break;
                    case 'wmpUserSelect':
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
                    case 'actionSelect':
                        this.filterData.actions = this.filterData.actions.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                    case 'userSelect':
                        this.filterData.users = this.filterData.users.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                }
            }
        }
    }

    /**
     * Change of the start date in client cmp search.
     * @param evt
     */
    handleStartDateChange(evt) {
        this.log(DEBUG,'---> start date change handler parent',evt.detail);
        if(evt.detail) {
            const payload = evt.detail.payload;
            if (payload) {
                this.filterData.startDate = payload.value;
            }
        }
    }

    /**
     * Change of end date in child cmp search.
     * @param evt
     */
    handleEndDateChange(evt) {
        this.log(DEBUG,'---> end date change handler parent',evt.detail);
        if(evt.detail) {
            const payload = evt.detail.payload;
            if (payload) {
                this.filterData.endDate = payload.value;
            }
        }
    }

    /**
     * Spinner / loading when child cmp is exporting?
     * @param evt
     */
    handleDatatableExport(evt) {
        const payload = evt.detail;
        if (payload) {
            this._isExporting = payload.exporting;
        }
    }

    /**
     * Default server side search stuff upon init.
     */
    generateDefaultFilterSelections() {
        this.defaultSelections.users = [];
        this.defaultSelections.statuses = [];
        this.defaultSelections.userTypes = ['Standard'];
        this.defaultSelections.activeInactives = ['active'];
        this.defaultSelections.startDate = this.defaultStartDateTime;
        this.defaultSelections.endDate = this.defaultEndDateTime;
        this.searchParams.startDate = this.defaultSelections.startDate;
        this.searchParams.endDate = this.defaultSelections.endDate;
        this.filterData = this.defaultSelections;
    }

    get defaultStartDateTime() {
        let d = new Date();
        d = new Date(d.setDate(d.getDate()-1));
        d.setHours(0,0,0,0)
        return d.toISOString();
    }

    get defaultEndDateTime() {
        let d = new Date();
        return d.toISOString();
    }

    /**
     * Build object data for child assistance cmp.
     * @returns {*[]}
     */
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
        msg = 'Click the Refresh icon to refresh your results form the server using your current search criteria';
        arr.push({text: msg, severity: 'info'});
        return arr;
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
        return 'auditTrailId';
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
        if(this._actionsFilterApplied) {
            num++;
        }
        if(this._sectionsFilterApplied) {
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