import {LightningElement,api,track,wire} from 'lwc';
import {dtHelper} from "./paGalleryTableDtHelper";
import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/portalAdminUtilsUiHelper'
import Logger from "c/logger";
import searchPaAdvisories from '@salesforce/apex/PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchImperative';
import searchTotals     from '@salesforce/apex/PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchDeclarativeTotalRecords';

const GLOBAL_CONSTANTS                          = getConstants();
const MAP_KEY_ADVISORY_WRAPS                    = 'ADVISORY_WRAPS';
const MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT      = 'ADVISORY_RECORDS_TOTAL_COUNT';

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class PaAdvisoryGalleryTable extends LightningElement {

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    //   Will be triggered every time a search param changes such as if using filters. This will in turn trigger the wired call.
    @api
    set advancedSearchParams(val) {
        this.log(DEBUG,'setting advancedSearchParams val=',val);
        this._isSearching = true;
        this._advancedSearchParams = {...val};
        this._recCountAdvancedSearchParams = {...this._advancedSearchParams};
        this._recCountAdvancedSearchParams.iLimit = 2000;
        let params = { searchParams: this._advancedSearchParams};
        this.doSearch(params,false);
    }
    get advancedSearchParams() {return this._advancedSearchParams;}

    @api dtContainerStyle = 'height: 25rem;';
    @api infiniteScrollMaxItems;
    @api useInfiniteScroll;
    @api showTableRowNumColumn;
    @api allowCsvExport;
    @api exportBtnVariant = 'brand';
    @api exportBtnLabel = 'Csv Export';
    @api exportBtnTitle = 'Click here to export the details to a csv file.';
    @api exportBtnIconName = 'utility:download';
    @api exportStatusLabel = 'Creating your csv export (All Items) ........';

    @track dtRecords;
    @track shapedRecords = [];
    @track serverRecords;
    @track columns = dtHelper.getUserColumns();
    @track dtClasses = dtHelper.getUserDtClasses();
    @track sortDirection = 'asc';
    @track sortBy = 'paFullName';
    @track totalRecordCount = 0;
    @track totalRecords;
    @track totalSearchRecordCount;
    @track targetDt;
    @track _advancedSearchParams  = {iOffset: null, iLimit: 2000, advisoryStartDate: null, advisoryEndDate:null, fullName:null};
    @track _wiredResultsDto;
    @track _wiredTotalsDto;

    _debugConsole;
    _logger;
    _rendering;
    _isSearching;
    _isLoading;
    _isExporting;
    _totalRecordsDisplayed = 0;
    _recCountAdvancedSearchParams;
    _loadMoreStatus;

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/paAdvisoryGalleryTable', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {}

    /**
     * Gets the total max number of records.
     * @param wiredData
     */
    @wire( searchTotals, {searchParams : '$_recCountAdvancedSearchParams'} )
    wiredTotals(wiredData){
        this._wiredTotals = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.totalSearchRecordCount = uiHelper.getMapValue(MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT,data.values);
                this.log(DEBUG,'total records --> ',this.totalSearchRecordCount);
            } else {
                this.log(WARN,'dto --> ',data);
            }
        } else if (error) {
            console.error(error);
        }
    }

    /**
     * Event Fired by the datatable. load more records.
     * @param event
     */
    handleLoadMore(event) {
        this._isScrolling = true;
        this.targetDt = event.target;
        this.toggleLoader(this.targetDt,true);
        this._loadMoreStatus = 'Loading';
        this._advancedSearchParams.iOffset += this.infiniteScrollMaxItems;
        this.log(DEBUG,'setting offset',this._advancedSearchParams.iOffset);
        let params = {searchParams: this._advancedSearchParams};
        this.log(DEBUG, '---> loadMore calling doSearch with params', params);
        this.doSearch(params,true);
    }

    /**
     * Fire the imperative search.
     * @param params   ie  {iLimit: 2000, iOffset: 0,fullName: xxxxx, isVisible: true};
     */
    doSearch(params,isLoadMore) {
        searchPaAdvisories( params )
            .then((data) => {
                let tmpWraps = uiHelper.getMapValue(MAP_KEY_ADVISORY_WRAPS,data.values);
                let tmpShaped = this.shapeUserTableData(tmpWraps);
                this.log(DEBUG,'doSearch dto-->',data);
                this.log(DEBUG,'# dto nbr of results-->',tmpWraps.length);
                if(isLoadMore) {
                    this.shapedRecords = this.shapedRecords.concat(tmpShaped);
                } else {
                    this.shapedRecords = tmpShaped;
                }
                this._totalRecordsDisplayed = this.shapedRecords.length;
                this.log(DEBUG,'total client side results',this.shapedRecords.length);
                this._loadMoreStatus = '';

                if (this._totalRecordsDisplayed >= this.totalSearchRecordCount) {
                    if(this.targetDt) {
                        this.targetDt.enableInfiniteLoading = false;
                    }
                    this._loadMoreStatus = 'All retrieved';
                } else if (tmpWraps.length === 0){
                    if(this.targetDt) {
                        this.targetDt.enableInfiniteLoading = false;
                    }
                    this._loadMoreStatus = this.shapedRecords.length === 0 ? 'No Records Found' : 'All retrieved';
                }
                this._isSearching = false;
                this._isLoading = false;
                this.toggleLoader(this.targetDt,false);
                this._isScrolling = false;
            })
            .catch((error) => {
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
     * @param targetDt      The reference to the html datatable element.
     * @param isLoading     True, to turn it on, False to turn it off.
     */
    toggleLoader(targetDt,isLoading) {
        if(targetDt) {
            this.log(DEBUG,'--> setting isloading',isLoading);
            targetDt.isLoading = isLoading;
        } else {
            this.log(WARN,'no target dt found!');
        }
    }

    /**
     * @param wraps    An Array of PaAdvisoryController.AdvisoryWrapper objects.
     * @returns {*[]}  An Array of cloned and flattened records suitable for datatable display.
     */
    shapeUserTableData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = JSON.parse(JSON.stringify(wraps));
            tmp.forEach(wrap => {
                let record = {};
                record.paAdvisoryName = wrap.advisory.Name;
                record.paAdvisoryId = wrap.advisory.Id;
                record.paAdvisoryDate = wrap.advisory.Advisory_Date__c;
                record.paRequestDate = wrap.advisory.Request_Date__c;
                record.paFullName = wrap.advisory.Full_Name__c;
                record.paLastName = wrap.advisory.Last_Name__c;
                record.paAdvisoryNumber = wrap.advisory.Advisory_Number__c;
                record.paExclusionType = wrap.advisory.Exclusion_Type__c;
                record.paExclusionPeriod = wrap.advisory.Exclusion_Period__c;
                record.paCity = wrap.advisory.City__c;
                records.push(record);
            });
        }
        return records;
    }
    /**
     * Sort the datatable column.
     * @param evt
     */
    handleSort(evt){
        this.sortBy = evt.detail.fieldName;
        let tmpSortBy = this.sortBy;
        if(this.sortBy === 'paFullName') {
            tmpSortBy = 'paLastName';
        }
        this.sortDirection = evt.detail.sortDirection;
        this.log(DEBUG,'sort by',tmpSortBy);
        this.shapedRecords = dtHelper.sortData(tmpSortBy,this.sortDirection,this.shapedRecords);

        let payload = {sortBy:this.sortBy,sortDirection:this.sortDirection};
        this.dispatchEvent( new CustomEvent('dtsorted',{detail:payload}));
    }

    handleExport(evt) {
        const payload = evt.detail;
        if (payload) {
            this._isExporting = payload.exporting;
        }
    }

    handleRowAction(evt) {
        if(evt.detail.action.name==='paAdvisoryNumber') {
            const row = evt.detail.row;
            let payload = {row: row};
            this.dispatchEvent( new CustomEvent('dtrowclicked',{detail:payload}));
        }
    }

    /**
     *
     * @returns {string}
     * @todo adjust height according to number of rows!
     */
    get dtDynaContainerStyle() {
        let containerStyle = this.dtContainerStyle;
        return containerStyle;
        // if(this.totalRecordCount<=5){//set the minimum height
        //     return 'height:2rem;';
        // }
        // else if(this.totalRecordCount>4 && this.totalRecordCount < 10){//set the max height
        //     return 'height:20rem;';
        // } else if(this.totalRecordCount >= 10) {
        //     return  'height:30rem';
        // }
        // return '';//don't set any height (height will be dynamic)
    }

    get dtKeyField() {
        return 'paAdvisoryId';
    }

    get showStencil() {
        return this._isSearching || this._isExporting; /*&& !this.useInfiniteScroll;*/
    }

    get showProgressBar() {
        return this._isSearching || this._isScrolling || this._isExporting;/* && !this.useInfiniteScroll;*/
    }

    get showNoRecords() {
        //&& !this.useInfiniteScroll
        return (!this._totalRecordsDisplayed || this._totalRecordsDisplayed < 1) && !this._isLoading && !this._isSearching;
    }

    get showDataTable() {
        return !this.showNoRecords && this.shapedRecords && this._totalRecordsDisplayed > 0 && !this._isExporting;
    }

    get showTotals() {
        return this.showDataTable;
    }


    get showExportButton() {
        return this.allowCsvExport && this.showDataTable;
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