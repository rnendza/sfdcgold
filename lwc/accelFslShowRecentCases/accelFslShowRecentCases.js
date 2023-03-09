import {LightningElement,api,track} from 'lwc';
import {NavigationMixin} from "lightning/navigation";
import retrieveRecentCases from '@salesforce/apex/AccelFslShowRecentCasesController.retrieveRecentCases';
import {uiHelper} from "./accelFslShowRecentCasesUiHelper";
import {dtHelper} from "./accelFslShowRecentCasesDtHelper"
import {themeOverrider} from "./accelFsShowRecentCasesThemeOverrider";
import {getConstants} from 'c/clConstantUtil';
import Logger from 'c/logger';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

const MAP_KEY_CASE_WRAPPERS                     = 'CASE_WRAPPERS';
const DEFAULT_ROW_LIMIT                         = 200;
const DEFAULT_EXCLUDED_STATUSES                 = ['Closed'];
const DEFAULT_INCLUDED_CREATED_DATE_LITERAL     = '= LAST_N_DAYS:7';
const DEFAULT_CARD_TITLE_LABEL                  = 'Recent Cases';
const DEFAULT_NO_DATA_LABEL                     = 'There are no recent cases to display.';
const DEFAULT_CARD_HEADER_ICON                  = 'standard:case';
const DEFAULT_DATA_FONT_SIZE                    = '.87em';
const DEFAULT_DATA_LINE_HEIGHT                  = '1.25rem';
const DEFAULT_TABLE_LEFT_MARGIN                 = '.075rem;'
const DEFAULT_TABLE_RIGHT_MARGIN                = '.075rem';
const DEFAULT_SORT_FIELD                        = 'createdDate';
const DEFAULT_SORT_DIRECTION                    = 'desc';
const DATATABLE_KEY_FIELD                       = 'caseId';
const GLOBAL_CONSTANTS                          = getConstants();
const DEFAULT_SLDS_OVERRIDES_CLASS              = 'fake-sfdc-overrides-class';
const DEFAULT_TABLE_FILTERS_THEME               = 'slds-theme_shade';

/**
 * Just shows a list (datatable) of recent cases tied to the accountid tied to the svc appt  (recordId) being viewed.
 */
export default class AccelFslShowRecentCases extends NavigationMixin(LightningElement) {

    @api recordId;
    @api cardTitleLabel = DEFAULT_CARD_TITLE_LABEL;
    @api cardHeaderIcon = DEFAULT_CARD_HEADER_ICON;
    @api noDataLabel = DEFAULT_NO_DATA_LABEL;
    @api showDetailedNoDataLabel;
    @api allowColumnSort;
    @api deferDisplay;
    @api allowManualDatatableRefresh;
    @api showColHeaderIcons;
    @api showTotalRowsInCardHeader;
    @api showTotalRowsInTableHeader;
    @api defaultSortBy = DEFAULT_SORT_FIELD;
    @api defaultSortDirection = DEFAULT_SORT_DIRECTION;
    @api iLimitRows;
    @api excludedCaseStatuses;
    @api includedDateLiteral;
    @api tableDataFontSize = DEFAULT_DATA_FONT_SIZE;
    @api tableDataLineHeight = DEFAULT_DATA_LINE_HEIGHT;
    @api tableLeftMargin = DEFAULT_TABLE_LEFT_MARGIN;
    @api tableRightMargin = DEFAULT_TABLE_RIGHT_MARGIN;
    @api table
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @track dtRecords;
    @track dtClasses = dtHelper.getDtClasses();
    @track dtColumns;
    @track sortDirection = 'desc';
    @track sortBy = 'createdDate';

    @track caseParams = {
        svcAppointmentId: null,
        iLimitRows: DEFAULT_ROW_LIMIT,
        excludedStatuses: DEFAULT_EXCLUDED_STATUSES,
        includedCreatedDateLiteral : DEFAULT_INCLUDED_CREATED_DATE_LITERAL
    }

    _debugConsole;
    _logger;
    _hasOverrodeTheme;
    _sldsDomOverrideClass = DEFAULT_SLDS_OVERRIDES_CLASS;
    _sldsDomOverrideSelector = '.'+this._sldsDomOverrideClass;    // write css class overrides to the DOM.
    _dataRefreshTime;
    _attemptedRefresh;
    _isLoading;
    _showNoData;

    constructor() {
        super();
        console.info('%c----> /lwc/accelFslShowRecentCases', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     * Fire cases query with params set via public api props (or defaulted).
     */
    connectedCallback() {
        //  We must defer some operations here to wait for the public api setters to fire.
        this.dtColumns = dtHelper.getCasesColumns(this);
        this.overrideSort();
        this.overrideQueryParams();

        this.doRetrieveRecentCases(this.caseParams);  // FIRE the main query!
    }

    /**
     * Override slds datatable styles.
     */
    renderedCallback() {
        if(!this._hasOverrodeTheme) {
            themeOverrider.overrideSldsCss(this);
        }
    }

    /**
     * Sets the private / tracked properties with the public api properties.
     */
    overrideSort() {
        this.sortBy = this.defaultSortBy;
        this.sortDirection = this.defaultSortDirection;
    }

    /**
     * Set the query param object.
     */
    overrideQueryParams() {
        this.caseParams.svcAppointmentId = this.recordId;
        this.caseParams.iLimitRows = this.iLimitRows ? this.iLimitRows : DEFAULT_ROW_LIMIT;
        if(this.excludedCaseStatuses) {
            let arr = this.excludedCaseStatuses.split(',');
            this.caseParams.excludedStatuses = arr ? arr : DEFAULT_EXCLUDED_STATUSES;
        } else {
            this.caseParams.excludedStatuses = DEFAULT_EXCLUDED_STATUSES;
        }
        this.caseParams.includedCreatedDateLiteral =
            this.includedDateLiteral ? this.includedDateLiteral : DEFAULT_INCLUDED_CREATED_DATE_LITERAL;
    }

    /**
     * Call apex method to retrieve the case data.
     * @param caseParams
     */
    doRetrieveRecentCases(caseParams) {
        this._attemptedRefresh = true;
        if(this.recordId) {
            this._isLoading = true;
            let params = {caseParams: caseParams};
            this.log(DEBUG,'--> calling retrieve cases with params',params);
            retrieveRecentCases(params)
                .then(data => {
                    this.log(DEBUG,'recent casesDto',data);
                    this._dataRefreshTime = new Date().getTime();
                    if(data.isSuccess) {
                        this.dtRecords = uiHelper.getMapValue(MAP_KEY_CASE_WRAPPERS,data.values);
                        if(this.dtRecords) {
                            this.dtRecords = dtHelper.sortData(this.sortBy, this.sortDirection, this.dtRecords);
                        }
                        this._showNoData = false;
                    } else {
                        this._showNoData = true;
                    }
                    this._isLoading = false;
                })
                .catch(error => {
                    this.log(ERROR,'error getting recent cases',error);
                    let msg = 'Error retrieving cases: ';
                    if(error.body && error.body.message) {
                        msg +=' message: '+error.body.message;
                    }
                    uiHelper.showToast(this,'',msg,'error');
                    this._isLoading = false;
                })
                .finally( () =>{
                    this._isLoading = false;
                });
        }
    }

    /**
     * Handle click of the fake button ie. link for lookup fields in the datatable.
     * Delegates action to viewRecord.
     * @param evt
     */
    handleRowAction(evt){
        const row = evt.detail.row;
        const action = evt.detail.action;
        const actionName = action.name;
        let sObjectName;

        switch (actionName) {
            case 'viewAssignedResource':
                sObjectName = 'User';
                break;
            case 'viewCase':
                sObjectName = 'Case';
                break;
            default:
        }
        if(sObjectName) {
            this.viewRecord(evt,row,sObjectName);
        }
    }

    /**
     * Uses Navigation MixIn to nav to the appropriate record.
     * @param evt
     * @param row
     * @param sObjectName
     */
    viewRecord(evt,row,sObjectName) {
        if(sObjectName && row) {
            evt.preventDefault();
            evt.stopPropagation();
            let recordId;
            switch (sObjectName) {
                case 'Case':
                    recordId = row.caseId;
                    break;
                case 'User':
                    recordId = row.assignedResourceId;
                    break;
                default:
            }
            if(recordId) {
                uiHelper.navigateToRecordView(this, sObjectName, recordId);
            }
        }
    }

    /**
     * Sort the datatable column.
     * @param evt
     */
    handleSort(evt){
        this.sortBy = evt.detail.fieldName;
        this.sortDirection = evt.detail.sortDirection;
        this.dtRecords = dtHelper.sortData(this.sortBy,this.sortDirection,this.dtRecords);
    }

    /**
     * Call the main query again.
     * @param evt
     */
    handleRefresh(evt) {
        this.doRetrieveRecentCases(this.caseParams);  // FIRE the main query!
    }

    /**
     * If an admin has checked deferDisplay do not show the card if loading or there isnt a truthy dtRecords
     * @returns {boolean}
     */
    get showCard() {
        let showIt;
        if(this.deferDisplay) {
            showIt = !this._isLoading || this.dtRecords;
        } else {
            showIt = true;
        }
        return showIt;
    }


    /**
     * Show the refresh icon / number of total rows..etc.
     * @returns {*}
     */
    get showTableConfigOptions() {
        return this.showDataTable && ( this.allowManualDatatableRefresh || this.showTotalRowsInTableHeader);
    }

    get filtersTheme() {
        return DEFAULT_TABLE_FILTERS_THEME;
    }

    get showStencil() {
        return this._isLoading;
    }

    /**
     * Suppress for now unless this takes a ton of time!
     * @returns {boolean}
     */
    get showProgressBar() {
        return false;
        //return this._isLoading;
    }

    get showDataTable() {
        return !this._isLoading && this.dtRecords && this.dtRecords.length > 0;
    }

    get showCardActions() {
        return false;
    }

    get showNoData() {
        return !this._isLoading && this._showNoData;
    }

    get dtKeyField() {
        return DATATABLE_KEY_FIELD;
    }

    get dtContainerStyle()  {
        let style = '';
        style += 'margin-left:'+this.tableLeftMargin;
        style += ';margin-right:'+this.tableRightMargin;
        return style;
    }

    /**
     * Get the card title using the label passed in and appending the number of records.
     * @returns {string}
     */
    get cardTitle(){
        let title = this.cardTitleLabel;
        if(this.showTotalRowsInCardHeader) {
            if (this.dtRecords) {
                title += ' (' + this.dtRecords.length + ')';
            } else {
                if (!this._isLoading) {
                    title += ' (0)';
                }
            }
        }
        return title;
    }

    get numberOfResults() {
        let numResults;
        if(this.dtRecords  && Array.isArray(this.dtRecords)) {
            numResults =  this.dtRecords.length;
        }
        return numResults;
    }
    get showTableTotalRows() {
        return this.showTotalRowsInTableHeader && this.numberOfResults;
    }

    /**
     * Message to display when no data is found.
     * @returns {string}
     */
    get noDataMessage() {
        let msg = this.noDataLabel;
        if(this.showDetailedNoDataLabel) {
            msg += ' which do not have a status of ' + this.caseParams.excludedStatuses;
            msg += ' and have a created date ' + this.caseParams.includedCreatedDateLiteral;
        }
        return msg;
    }

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