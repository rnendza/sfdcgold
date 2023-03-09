import {LightningElement, wire, track, api} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/portalAdminUtilsUiHelper'
import { dtHelper } from "./paAdvisoryGalleryDtHelper";
import Logger from 'c/logger'
import retrievePaAdvisories from '@salesforce/apex/PaAdvisoryGalleryController.retrievePaAdvisories';
import searchTotals     from '@salesforce/apex/PaAdvisoryGalleryController.retrievePaAdvisoriesAdvancedSearchDeclarativeTotalRecords';

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_ADVISORY_WRAPS = 'ADVISORY_WRAPS';
const MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT     = 'ADVISORY_RECORDS_TOTAL_COUNT';
const DELAY = 200;

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class PaAdvisoryGallery extends LightningElement {

    //  Public Api
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}
    @api allowFilters;
    @api allowMouseOverHighlight;
    @api allowListVsImageToggle;
    @api allowCsvExport;
    @api allowPdfExport;
    @api allowSortIcon;
    @api useInfiniteScroll;
    @api infiniteScrollMaxImageItems = 30;
    @api infiniteScrollMaxTableItems = 30;
    @api cardTitle = 'PA Advisories';
    @api cardIcon = 'custom:custom86';
    @api scrollContainerStyle = 'max-height:700px';
    @api dtContainerStyle = 'height: 25rem;';
    @api showTableRowNumColumn;
    @api userPlaceHolder = 'Enter name...';
    @api cityPlaceHolder = 'Enter city...';
    @api filtersLabel = 'Filters';
    @api filtersAppliedLabel = 'Filters Applied';
    @api photoStyle = 'height:300px;width:300px';
    @api photoCls;
    @api minFilterChars = 2;
    @api exportBtnVariant = 'brand';
    @api exportBtnLabel = 'Csv Export';
    @api exportBtnTitle = 'Click here to export the details to a csv file.';
    @api exportBtnIconName = 'utility:download';
    @api exportStatusLabel = 'Creating your csv export (All Items) ........';

    //  Private Properties
    _debugConsole;
    _logger;
    _serverRecords;
    _isSearching;
    _isScrolling;
    _loadMoreStatus;
    _showUserDetails;
    _showFilters;
    _totalRecords;
    _displayImageView = true;
    _displayTableView;
    _isSorting;
    _wiredTotals;
    _totalRecordsDisplayed;
    _isExporting;
    _displayPdf;
    _formFactor = FORM_FACTOR;
    _selectedSortOption = {
        id: 'paAdvisoryDatedesc', label: 'Advisory Date - Newest', value: 'paAdvisoryDate',
        sortDir: 'desc', prefixIconName: 'utility:arrowdown'
    };
    _currentSortedByIcon = this._selectedSortOption.prefixIconName

    @track dialogPayload;
    @track filteredUserRecords;
    @track displayedUserRecords;
    @track _dtUserFilter = null;
    @track _dtCityFilter;
    @track _searchParams = { iLimit: 2000, iOffset: 0,fullName: this._dtUserFilter, isVisible: true};
    @track _dtSearchParams = { iLimit: 2000, iOffset: 0,fullName: this._dtUserFilter, isVisible: true};
    @track totalSearchRecordCount;
    @track exclusionTypes;
    @track advisoryIdsForPdfExport;
    @track sortDirection = this._selectedSortOption.sortDir;
    @track sortBy = this._selectedSortOption.value;


    constructor() {
        super();
        console.info('%c----> /lwc/paAdvisoryGallery', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     * Fires off the search.
     */
    connectedCallback() {
        this._dtSearchParams.iLimit = this.infiniteScrollMaxTableItems;
        this.search();
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            if(this.allowListVsImageToggle) {
                const btn =  this.template.querySelector('[data-iconbuttonid="btnDisplayTile"]');
                if(btn) {
                    btn.click();
                }
            }
        }
    }

    /**
     * Gets the total max number of records.
     * @param wiredData
     */
    @wire( searchTotals, {searchParams : '$_searchParams'} )
    wiredTotals(wiredData){
        this._wiredTotals = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.totalSearchRecordCount = uiHelper.getMapValue(MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT,data.values);
                this.log(DEBUG,'total server record cnt --> ',this.totalSearchRecordCount);
            } else {
                this.log(WARN,'dto --> ',data);
            }
        } else if (error) {
            console.error(error);
        }
    }

    /**
     * Call the server to with the searchParams object.
     * Shape the server data suitable for display.
     * Builds a displayed arrow so that we can use client side infinite scroll.
     * Shuts off spinners / loading indicators.
     */
    search() {
        this._isSearching = true;
        let params = { searchParams: this._searchParams};
        this.log(DEBUG,'---> calling sObjectSearch with params',params);

        retrievePaAdvisories(params)
            .then((result) => {
                if(result.isSuccess) {
                    let tmpWraps = uiHelper.getMapValue(MAP_KEY_ADVISORY_WRAPS,result.values);
                    //this.tmpWraps = this.tmpWraps.slice(0,1);
                    this._serverRecords = this.shapeUserTableData(tmpWraps);
                    this.log(DEBUG,'---> advisory server records',this._serverRecords);
                    this._totalRecords = this._serverRecords.length;
                    this.log(DEBUG,'---> total server records ',this._totalRecords);

                    this.displayedUserRecords = [];
                    if(this.useInfiniteScroll) {
                        for (let i = 0; i < this.infiniteScrollMaxImageItems; i++) {
                            this.displayedUserRecords.push(this._serverRecords[i]);
                        }
                    } else {
                        this.log(DEBUG,'-----> infinite scroll set to off!');
                        this.displayedUserRecords = this._serverRecords;
                    }
                    this.displayedUserRecords = this.sortImages(this.displayedUserRecords);

                    this.filteredUserRecords = [];
                    if(this.useInfiniteScroll) {
                        for (let i = 0; i < this.infiniteScrollMaxImageItems; i++) {
                            this.filteredUserRecords.push(this._serverRecords[i]);
                        }
                    } else {
                        this.filteredUserRecords = this._serverRecords;
                    }
                    this.filteredUserRecords = this.sortImages(this.filteredUserRecords);
                    this._totalRecordsDisplayed = this.filteredUserRecords.length;
                } else {
                    this._serverRecords = uiHelper.getMapValue(MAP_KEY_ADVISORY_WRAPS,result.values);
                    this.filteredUserRecords = [...this._serverRecords];
                    this.displayedUserRecords =  [...this._serverRecords];
                    let mode = 'dismissible';
                    let title = 'error on retrieval';
                    uiHelper.showToast(this,title,result.message,result.severity,mode);
                }
            })
            .catch((error) => {
                console.error(error);
                let msg = error.body.exceptionType + ' - ' + error.body.message;
                if(error.body.message.includes('limit') || error.body.message.includes('heap')) {
                    msg += '. Please tighten your search parameters.';
                }
                uiHelper.showToast(this,'Error on Call to Provider',msg,'error','sticky');
            })
            .finally(() => {
                this._isLoading = false;
                this._isSearching = false;
            });
    }

    /**
     * Takes the server side data and clones it for easier use in a datatable.
     *
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
                record.paPhoto = wrap.advisory.Photo__c;
                record.paImgSrc = wrap.photoSrcUrl;
                records.push(record);
            });
        }
        return records;
    }

    /**
     * Handle the scroll event using the height of the container.  Concats records based
     * on infiniteScrollMaxImageItems property.This event gets pounded by the brower
     * upon every scroll of the mouse and will probably start smoking. it's not really meant
     * to be used in this context.
     *
     * @param event
     */
    handleScroll(event) {
        let area = this.template.querySelector('.scrollArea');
        let threshold = 2 * event.target.clientHeight;
        let areaHeight = area.clientHeight;
        let scrollTop = event.target.scrollTop;
        this._isScrolling = true;
        if(areaHeight - threshold < scrollTop) {
            this._loadMoreStatus = 'Loading';
            let t = this.filteredUserRecords.length;
            if(!this._dtUserFilter) {
                for (let i = 0; i < this.infiniteScrollMaxImageItems; i++) {
                    if ((i + t) < this._serverRecords.length) {
                        this.filteredUserRecords.push(this._serverRecords[i + t]);
                    }
                }
            }
            if(this.allowSortIcon) {
                // generally too slow. don't do unless we have to.
                this.filteredUserRecords = this.sortImages(this.filteredUserRecords);
            }
            this.displayedUserRecords = this.filteredUserRecords;
            this.log(DEBUG,'--> handleScroll - displayed user records size',this.displayedUserRecords.length);
            this._totalRecordsDisplayed = this.filteredUserRecords.length;
            this._loadMoreStatus = null;
        }
        this._isScrolling = false;
    }

    /**
     * Opens details modal.
     * @param paAdvisoryId
     */
    doShowDetails(paAdvisoryId) {
        this.dialogPayload = paAdvisoryId;
        this._showUserDetails = true;
    }

    /**
     * Handles the click of the image.
     * @param evt
     */
    handlePhotoClick(evt) {
        const id  = evt.currentTarget.dataset.sfdcid;
        this.doShowDetails(id);
    }

    handlePhotoMouseover(event) {
        if(!this._isScrolling && this.allowMouseOverHighlight) {
            const classList = event.currentTarget.classList;
            classList.add('lgc-highlight');
        }
    }

    handlePhotoMouseout(event) {
        if(this.allowMouseOverHighlight) {
            const classList = event.currentTarget.classList;
            classList.remove('lgc-highlight');
        }
    }
    /**
     * Process the card menu option selected.
     * @param evt`
     */
    handleCardMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        this.log(DEBUG,'---> selectedItemValue', selectedItemValue);

        if (selectedItemValue === 'showFilters') {
            this._showFilters = true;
        } else if (selectedItemValue === 'hideFilters') {
            this.filteredUserRecords = this._serverRecords;
            this._showFilters = false;
        }
    }

    handleCloseFilters(evt) {
        this._showFilters = false;
    }

    /**
     *
     * @param evt
     * @todo experimental
     */
    handleSortMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        this.log(DEBUG,'menuid',evt.detail);
        const menuOptions = this.sortOptions;
        if(menuOptions) {
            const menuOption = menuOptions.find( (option) => option.id === selectedItemValue);
            if(menuOption) {
                this._isSorting = true;
                this._selectedSortOption = menuOption;
                this.log(DEBUG,'--> menu ele: ',menuOption);
                this.sortBy = menuOption.value;
                this.sortDirection = menuOption.sortDir;
                this._currentSortedByIcon = menuOption.prefixIconName;

                if(this.allowFilters || this.useInfiniteScroll) {
                    this._serverRecords = this.sortImages(this._serverRecords);
                    this.displayedUserRecords = this.sortImages(this.displayedUserRecords);
                }
                this.filteredUserRecords = this.sortImages(this.filteredUserRecords);
                this._isSorting = false;
            }
        }
    }

    handleIconButtonClick(evt) {
        const buttonId = evt.currentTarget.dataset.iconbuttonid;
        this.log(DEBUG,'buttonId',buttonId);
        if(buttonId === 'btnDisplayTile') {
            this._displayTableView = false;
            this._displayImageView = true;
        } else if (buttonId === 'btnDisplayTable') {
            this._displayTableView = true;
            this._displayImageView = false;
        } else if (buttonId === 'btnExportPdf') {
            this.processPdfButtonClick();
        }
    }

    processPdfButtonClick() {
        let cmp = this.template.querySelector('c-pa-advisory-pdf-export');
        if(!this.displayPdfView) {
            this.advisoryIdsForPdfExport = [];
            this.filteredUserRecords.forEach(userRec => {
                this.advisoryIdsForPdfExport.push(userRec.paAdvisoryId);
            });
            if (cmp) {
                //this.log(DEBUG, 'advisoryIds for export prior to call', this.advisoryIdsForPdfExport);
                cmp.preparePdfViewPublic(this.advisoryIdsForPdfExport);
                this._displayPdf = true;
            }
        } else {
            this._displayPdf = false;
            if (cmp) {
                cmp.preparePdfViewPublic(null);
            }
        }
    }
    /**
     * Filters were pressed on the child filters cmp.  filter the displayed data (using timeout so as to not throttle)
     * @param evt
     */
    handleTextFilterKeyPress(evt) {
        const filterKey = evt.detail.value;
        const filterType = evt.detail.filterType;
        let validType;

        switch (filterType) {
            case 'userfilter':
                validType = true;
                this._dtUserFilter = filterKey;
                this._searchParams.fullName = this._dtUserFilter;
                this._dtSearchParams = {...this._dtSearchParams}; // clone so as to trigger the child reactive api setter.
                this._dtSearchParams.fullName = this._dtUserFilter;
                break;
            case 'cityfilter':
                validType = true;
                this._dtCityFilter = filterKey;
                this._searchParams.fullName = this._dtUserFilter;
                this._searchParams.city = this._dtCityFilter;
                this._dtSearchParams = {...this._dtSearchParams}; // clone so as to trigger the child reactive api setter.
                this._dtSearchParams.fullName = this._dtUserFilter;
                this._dtSearchParams.city = this._dtCityFilter;
                break;
        }
        this.log(DEBUG,'--> filter type',filterType);
        let fieldNames = [];
        if(this._dtUserFilter) {
            fieldNames.push('paFullName');
        }
        if(this._dtCityFilter) {
            fieldNames.push('paCity');
        }
        if(validType) {
            this.delayedFireFilterEvent(filterKey, fieldNames);
        }
        this.log(DEBUG,'---> filterType',filterType);
    }

    handleModalUserDetailsClick(evt) {
        this._showUserDetails = false;
    }

    handleDatatableRowSelected(evt) {
        const rowClicked = evt.detail.row;
        if(rowClicked) {
            this.doShowDetails(rowClicked.paAdvisoryId)
        }
    }

    handleDatatableSorted(evt) {
        const payload = evt.detail;
        this.log(DEBUG,'--> paAdvisoryGallery handleDtSorted',payload);
        if(payload) {
            this.sortBy = payload.sortBy;
            this.sortDirection = payload.sortDirection;
            this.sortImages(this.displayedUserRecords);
        }
    }

    handleFilterToggle(evt) {
        this._showFilters = !this._showFilters;
    }

    handleExport(evt) {
        const payload = evt.detail;
        if (payload) {
            this._isExporting = payload.exporting;
        }
    }

    handleCancelPdf(evt) {
        console.log('---> handleCancelPdf event');
        this._displayPdf = false;
    }

    /**
     * Filter by fullname (last name) for now / resort.
     * @param searchKey The search key pressed
     */
    delayedFireFilterEvent(searchKey,fieldNames) {
        window.clearTimeout(this.delayTimeout);

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.delayTimeout = setTimeout(() => {
            if(searchKey && searchKey.length > 1) {
                this.filteredUserRecords = this._serverRecords.filter((item) => {
                    let foundAll = false;
                    fieldNames.forEach(fieldName => {
                        this.log(DEBUG,'--->delayed filter checkfield',fieldName);
                        if(item[fieldName].toLowerCase().includes(searchKey.toLowerCase())) {
                            foundAll = true;
                        } else {
                            foundAll = false;
                        }
                    });
                    this.log(DEBUG,'--->delayed filter foundAll?',foundAll);
                    return foundAll;
                });
                this.displayedUserRecords = this.filteredUserRecords;
                if(this.sortBy && this.sortDirection) {
                    this.displayedUserRecords = this.sortImages(this.displayedUserRecords);
                    this._serverRecords = this.sortImages(this._serverRecords);
                }
            } else {
                this.filteredUserRecords = this._serverRecords;
                this.displayedUserRecords = this._serverRecords;
            }
        }, DELAY);
    }

    get imageIconClass() {
        return this._displayImageView ? 'accel-blue-icon' : '';
    }

    get disableSortMenuButton() {
        return this._isSorting || this._isLoading || this._isSearching || this._isScrolling;
    }

    get showPdf() {
        return this._displayPdf;
    }

    get tableIconClass() {
        let cls = '';
        if(this.allowFilters) {
            //cls = 'slds-m-right_medium';
        }
        if(this.showFilterIcon) {
            cls = 'slds-m-right_medium';
        }
        if(this._displayTableView) {
            cls += ' slds-m-left_xx-small accel-blue-icon';
        } else {
            cls += ' slds-m-left_xx-small';
        }
        return cls;
    }
    get showFilterIcon() {
        return !this._loadMoreStatus && !this._isLoading && this.allowFilters;
    }
    get showSortIcon() {
        return !this._loadMoreStatus && !this._isLoading && this.allowSortIcon;
    }
    get showStencil() {
        return this._isSearching || this._isExporting;
    }


    get showProgressBar() {
        return this._isSearching || this._isExporting || this._isSorting;
    }

    get showSearchResults() {
        return this._serverRecords && !this._isExporting;
    }

    get isUserDetailsVisible() {
        return this._showUserDetails;
    }

    get totalServerRows() {
        return this._serverRecords ? this._serverRecords.length : 0;
    }

    get totalFilteredRows() {
        return this.filteredUserRecords ? this.filteredUserRecords.length : 0;
    }
    get totalDisplayedRows() {
        return this.displayedUserRecords ? this.displayedUserRecords.length : 0;
    }
    get showTotals() {
        return true;
    }

    get filtersActiveParentCmp() {
        return this._displayImageView ? 'paAdvisoryGallery' : 'paAdvisoryGalleryTable';
    }

    get showExportButton() {
        return this.allowCsvExport && this._serverRecords && this.totalDisplayedRows > 0;
    }

    get mobile() {
        return this._formFactor === 'Small';
    }

    get cardActions() {
        let actions = [];

        if (this.allowFilters) {
            if (this._showFilters) {
                let option = {
                    id: 'hideFilters',
                    label: 'Hide Search filters',
                    value: 'hideFilters',
                    prefixIconName: 'utility:hide'
                };
                actions.push(option);
            } else {
                let option = {
                    id: 'showFilters',
                    label: 'Show Search filters',
                    value: 'showFilters',
                    prefixIconName: 'utility:search'
                };
                actions.push(option);
            }
        }
        return actions;
    }

    get sortOptions() {
        let options = [];

        if (this.allowSortIcon) {
            let option = {
                id: 'paLastNameasc',
                label: 'Last Name - Asc',
                value: 'paLastName',
                sortDir: 'asc',
                prefixIconName: 'utility:arrowup'
            };
            let optionb = {
                id: 'paLastNamedesc',
                label: 'Last Name - Desc',
                value: 'paLastName',
                sortDir: 'desc',
                prefixIconName: 'utility:arrowdown',
                selected: ( (this.sortBy === 'paFullName') || (this.sortBy === 'paLastName') )
            };
            let optionc = {
                id: 'paAdvisoryDatedesc',
                label: 'Advisory Date - Newest',
                value: 'paAdvisoryDate',
                sortDir: 'desc',
                prefixIconName: 'utility:arrowdown'
            };
            let optiond = {
                id: 'paAdvisoryDateasc',
                label: 'Advisory Date - Oldest',
                value: 'paAdvisoryDate',
                sortDir: 'asc',
                prefixIconName: 'utility:arrowup'
            };
            options.push(option);
            options.push(optionb);
            options.push(optionc);
            options.push(optiond);
        }
        return options;
    }

    sortImages(records) {
        let tmpSortBy = this.sortBy;
        if(this.sortBy === 'paFullName') {
            tmpSortBy = 'paLastName';
        }
        this.log(DEBUG,'---> calling sort with sortBy:'+tmpSortBy+'... direction:'+this.sortDirection);
        return dtHelper.sortData(tmpSortBy,this.sortDirection,records);
    }

    get displayImageView() {
        return ( !this.allowListVsImageToggle || this._displayImageView ) && !this.displayPdfView;
    }

    get displayTableView() {
        return ( this.allowListVsImageToggle && this._displayTableView ) && !this.displayPdfView;
    }

    get displayPdfView() {
        return this._displayPdf;
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