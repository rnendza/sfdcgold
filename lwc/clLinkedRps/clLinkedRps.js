import {LightningElement,wire,api,track} from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {NavigationMixin} from "lightning/navigation";
import CURRENCY from '@salesforce/i18n/currency';
import ACCT_SOBJECT from '@salesforce/schema/Account';
import RPS_SOBJECT from '@salesforce/schema/Route_Processing_Sheet__c';

import retrieveLinkedRps from '@salesforce/apex/clLinkedRpsController.retrieveLinkedRps';
import retrieveLinkedRpsTotalCnt from '@salesforce/apex/clLinkedRpsController.retrieveLinkedRpsTotalRecords';
import Logger from 'c/logger'
import {uiHelper} from "./clLinkedRpsUiHelper";
import {refreshApex} from "@salesforce/apex";

const MAP_KEY_RPS_WRAPPERS    = 'RPS_WRAPPERS';
const MAP_KEY_RPS_TOTAL_CNT   = 'RPS_TOTAL_CNT';
const MAP_KEY_PARENT_ACCT_ID  = 'PARENT_ACCT_ID';
const DEFAULT_ROW_LIMIT       = 50;
const CARD_OVERRIDE_SELECTOR  = '.fake-sfdc-console-card-overrides-class';
const ERROR_VARIANT           = 'error';  //  Error toast variant.
const ERROR_MODE              = 'sticky'; //  Error toast mode.
const ACCT_RPS_RELATED_LIST   = 'Route_Processing_Sheets__r';   //  @todo lwc won't import this!
const STENCIL_COLUMNS         = 2;
const STENCIL_ITERATIONS      = 4;
const KEY_VGT_VARIANCES       = 'vgtVariances';
const KEY_RT_VARIANCES        = 'rtVariances';
/**
 * Component to be placed on RPS page layouts listing all linked RPS Sheets.
 * i.e. All RPS sheets for the parent account other than the current one being viewed on the record page.
 */
export default class ClLinkedRps extends NavigationMixin(LightningElement) {

    //-- PUBLIC API
    @api recordId;
    @api cardTitle = 'Linked RPS';
    @api cardIconName = 'custom:custom18';
    @api viewAllLabel = 'View All';
    @api allowCompactLoOnHover;                                 //  @todo not ready for future use only
    @api allowFilterMenuAction;                                 //  Shows variance and maybe other filters.
    @api allowCollectionDateFilter;                             //  Shows collection date filter.
    @api allowRowLimitOptions;                                  //  Shows row limit select options.
    @api noRecordsText = 'No Linked Route Processing Sheets Exist.';
    @api varianceFilterPillIconName = 'standard:filter';

    @api
    get vgtVariancesLabel() {
        return this._vgtVariancesLabel;
    }
    set vgtVariancesLabel(value) {
        this._vgtVariancesLabel = value;
        this._variancesMap.set(KEY_VGT_VARIANCES,value);
    }

    @api
    get rtVariancesLabel() {
        return this._vgtVariancesLabel;
    }
    set rtVariancesLabel(value) {
        this._rtVariancesLabel = value;
        this._variancesMap.set(KEY_RT_VARIANCES,value);
    }

    @api
    get debugConsole() {
        return this._debugConsole;
    }
    set debugConsole(value) {
        this._debugConsole = value;
        this._logger = new Logger(this._debugConsole);
    }
    @api
    get iRowLimit() {
        return this._iRowLimit;
    }
    set iRowLimit(value) {
        this._iRowLimit = DEFAULT_ROW_LIMIT;
        this._defaultRowLimit = value;
        this._searchParams.iLimit = value;
    }

    //-- PRIVATE
    @track _searchParams = {
        iLimit: this.iRowLimit,
        hasVgtVariance: null,
        hasRtVariance: null,
        daysBackCollectionDate: null
    };
    @track rpsWrappers;
    @track parentAcctId;
    @track fields;
    @track totalRpsRecordCount;
    @track selectedVarianceOptions = []; //  chkbox values selected in the child filters cmp (string array).
    @track selectedDaysBackCollectionDate;
    @track selectedVariancePills;
    @track rowLimitOptions;
    @track selectedRowLimitOption;

    _wiredRpsDto;
    _wiredRpsTotalCntDto;
    _objectRecordId;
    _domOverrideSelector = CARD_OVERRIDE_SELECTOR; // selector of div
    _hadRendered;
    _isLoading;
    _iRowLimit = 50;
    _hasErrors;
    _showFilters;
    _currency = CURRENCY;
    _stencilColumns = STENCIL_COLUMNS;
    _stencilIterations = STENCIL_ITERATIONS;
    _filtersApplied;
    _variancesMap = new Map();
    _defaultRowLimit;
    _rtVariancesLabel;
    _vgtVariancesLabel;
    _showingCL;
    _limitSelectStyle = 'max-width:5.95rem;font-size:.675rem;height:1.45rem';

    constructor() {
        super();
        this._isLoading = true;
    }

    connectedCallback() {
        this._logger.logDebug('----> /lwc/clLinkedRps','connectedCbk');
        if(this.allowRowLimitOptions) {
            this.rowLimitOptions = this.buildRowLimitOptions();
        }
    }

    disconnectedCallback() {
        this._logger.logDebug('----> /lwc/clLinkedRps','disconnectedCbk');
    }

    /**
     * Override standard slds card css.
     * @todo replace with styling hooks if they exist.
     */
    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            uiHelper.buildConsoleCardOverrideCss(this,this._domOverrideSelector);
        }
    }

    /**
     * Using the current recordId and searchParams objects call the server to retrieve all linked RPS Wrappers.
     *
     * @param wiredDto
     */
    @wire(retrieveLinkedRps, {currentRpsId: '$recordId',searchParams: '$_searchParams'})
    wiredRpsData(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const { data, error } = this._wiredRpsDto;
        if(data) {
            this._logger.logDebug('-->  wiredRpsData dto',data);
            this.rpsWrappers = [...uiHelper.getMapValue(MAP_KEY_RPS_WRAPPERS,data.values)];
            this.parentAcctId = uiHelper.getMapValue(MAP_KEY_PARENT_ACCT_ID,data.values);
            this._isLoading = false;
            this._hasErrors = false;
        } else if (error) {
            this._hasErrors = true;
            this._isLoading = false;
            console.error(JSON.stringify(error));
            this.logError(error,'wiredRpsData');
            const errorDisplay = uiHelper.reduceErrors(error);
            uiHelper.showToast(this,'Error',errorDisplay,ERROR_VARIANT,ERROR_MODE);
        }
    }

    /**
     * Using the current recordId and searchParams objects call the server to retrieve the COUNT of all linked RPS Wrappers.
     *
     * @param wiredDto called back data and errors.
     */
    @wire(retrieveLinkedRpsTotalCnt, {currentRpsId: '$recordId',searchParams: '$_searchParams'})
    wiredRpsCntData(wiredDto) {
        this._wiredRpsTotalCntDto = wiredDto;
        const { data, error } = this._wiredRpsTotalCntDto;
        if(data) {
            this._logger.logDebug('-->  wiredRpsTotalCntData dto',data);
            this.totalRpsRecordCount = uiHelper.getMapValue(MAP_KEY_RPS_TOTAL_CNT,data.values);
            this._hasErrors = false;
        } else if (error) {
            this._hasErrors = true;
            console.error(JSON.stringify(error));
            this.logError(error,'wiredRpsTotalCntData');
            const errorDisplay = uiHelper.reduceErrors(error);
            uiHelper.showToast(this,'Error',errorDisplay,ERROR_VARIANT,ERROR_MODE);
        }
    }

    /**
     * Retrieve UI Data on Route_Processing_Sheet__c.
     *
     * @param data  callback UI data.
     * @param error callback error data.
     */
    @wire(getObjectInfo, { objectApiName: RPS_SOBJECT })
    wiredRpsObject({ data, error }) {
        if (data) {
            this.fields = data.fields;
            this._hasErrors = false;
        } else if (error) {
            this._hasErrors = true;
            this.logError(error,'wiredRpsObject');
            const errorDisplay = uiHelper.reduceErrors(error);
            uiHelper.showToast(this,'Error',errorDisplay,ERROR_VARIANT,ERROR_MODE);
        }
    }

    /**
     * Navigate the rps view.
     *
     * @param evt (used to obtain the rps Id on the dataset attribute.
     */
    handleNavToRpsView(evt) {
        const rpsId = evt.target.dataset.rpsid;
        uiHelper.navigateToRecordView(this,RPS_SOBJECT.objectApiName,rpsId);
    }

    /**
     * Handle the toggle of the filter card icon.
     *
     * @param evt
     */
    handleFilterToggle(evt) {
        this._showFilters = !this._showFilters;
    }

    /**
     * Handle the child comp event the fires the checkbox filter changed event.
     *
     * @param evt  And the filter value selected event from the child cmp (array for variance chkbox values selected)
     */
    handleFilterValueSelected(evt) {
        const detail = evt.detail;
        this.selectedVarianceOptions = detail.valuesSelected;
        this.refireSearchWithVarianceOptions(detail.valuesSelected);
    }

    /**
     * Handle the child comp event the fires the checkbox filter changed event.
     *
     * @param evt  contains the collection date selected value. ie one of null,30,60,90.
     */
    handleCollectionDatePlValueSelected(evt) {
        const detail = evt.detail;
        this.selectedDaysBackCollectionDate = detail;
        this._logger.logDebug('collection date pl value selected', detail);
        this.refireSearchWithCollectionDateOption(detail);
    }

    /**
     * Select the selected row limit option and refire the search.
     *
     * @param evt row limit option i.e. {value:50, label:'Show 50 rows', selected:false}
     */
    handleLimitOptionSelected(evt) {
        this._logger.logDebug('--> limit option selected',evt.detail);
        this.selectedRowLimitOption = evt.detail;
        this.refireSearchWithLimitOption(evt.detail);
    }

    /**
     * Refresh the wired calls with new _searchParams object set by values obtained by the child filters
     * chkbox valuee.
     * Note: We must clone the original _seachParms object and modify it to get the wired to fire.
     *
     * @param options an array of variance options i.e [ {vgtVariances},{rtVariances} ]
     */
    refireSearchWithVarianceOptions(options) {

        if (options) {
            this._filtersApplied = false;
            let tmpParams = {...this._searchParams};    // clone.

            tmpParams.hasVgtVariance = null;
            tmpParams.hasRtVariance = null;
            this.rpsWrappers = null;
            this.totalRpsRecordCount = null;

            if(options.length > 0) {
                options.forEach( (item) => {
                    if(item === KEY_VGT_VARIANCES) {
                        tmpParams.hasVgtVariance = true;
                        this._searchParams = tmpParams; // overwrite
                        this._filtersApplied = true;
                    } else if (item === KEY_RT_VARIANCES) {
                        tmpParams.hasRtVariance = true;
                        this._searchParams = tmpParams; // overwrite
                        this._filtersApplied = true;
                    }
                });
            } else {
                // show all
                this._searchParams = tmpParams; // overwrite
                this._filtersApplied = false;
            }
            this.buildFilterPills(options,this.selectedDaysBackCollectionDate);
            this._isLoading = true;
            this._logger.logDebug('----> refireSearchVariance with params',this._searchParams);
            refreshApex(this._wiredRpsDto);
            refreshApex(this._wiredRpsTotalCntDto);
        }
    }

    /**
     * Refresh the wired calls with new _searchParams object set by values obtained by the child cmp collection
     * date selected pl value.
     *
     * @param value ie one of null,30,60,90
     */
    refireSearchWithCollectionDateOption(value) {
        if(value !== undefined) {
            let tmpParams = {...this._searchParams};    // clone.
            tmpParams.daysBackCollectionDate = value;
            this._searchParams = tmpParams;
            this._isLoading = true;
            this._filtersApplied = true;
            this._logger.logDebug('----> refireSearchCollectionDate with params',this._searchParams);
            this.buildFilterPills(this.selectedVarianceOptions,this.selectedDaysBackCollectionDate);
            refreshApex(this._wiredRpsDto);
            refreshApex(this._wiredRpsTotalCntDto);
        }
    }

    /**
     * Refresh the wired calls with new _searchParams object set by values obtained by the child cmp collection.
     *
     * @param rowLimitOption
     */
    refireSearchWithLimitOption(rowLimitOption) {
        if(rowLimitOption !== undefined) {
            let tmpParams = {...this._searchParams};    // clone.
            tmpParams.iLimit = rowLimitOption.value;
            this._searchParams = tmpParams;
            this._isLoading = true;
            this._filtersApplied = true;
            this._logger.logDebug('----> refireSearchCollectionDate with params',this._searchParams);
            refreshApex(this._wiredRpsDto);
            refreshApex(this._wiredRpsTotalCntDto);
        }
    }

    /**
     * Navigate to the related list view (must exist on parent account page layout).
     * @param evt
     */
    handleNavToRelatedListView(evt) {
        uiHelper.navigateRelatedListView(this,ACCT_SOBJECT.objectApiName,ACCT_RPS_RELATED_LIST,this.parentAcctId);
    }

    /**
     * Build pill options with the values selected on the child filters checkbox cmp.
     *
     * @param selectedOptions               An array of variance checkbox values.
     * @param aSelectedCollectionDateValue  ie.one of null,30,60,90
     */
    buildFilterPills(selectedOptions,aSelectedCollectionDateValue) {
        let pills = [];
        if(selectedOptions) {
            selectedOptions.forEach( (value) => {
                let pillOption = {value:value,label:this._variancesMap.get(value)};
                pills.push(pillOption);
            });
        }
        this._logger.logDebug('--> build filter pills, aSelectedCollectionDateValue',aSelectedCollectionDateValue);
        if(aSelectedCollectionDateValue !== undefined) {
            let pillOption;
            if(aSelectedCollectionDateValue !== null) {
                pillOption = {
                    value:aSelectedCollectionDateValue,
                    label:'Last '+aSelectedCollectionDateValue+ ' days'
                };
                pills.push(pillOption);
            }
        }
        this.selectedVariancePills = pills;
    }

    /**
     * Gets row limit options
     *
     * @returns {*[]}
     */
    buildRowLimitOptions() {
        let options = [];
        options.push({value:this._defaultRowLimit, label:'Show '+this._defaultRowLimit+ ' rows', selected:!this._defaultRowLimit});
        options.push({value:10, label:'Show 10 rows', selected:this.defaultRowLimit === 10});
        options.push({value:20, label:'Show 20 rows', selected:this.defaultRowLimit === 20});
        options.push({value:50, label:'Show 50 rows', selected:this.defaultRowLimit === 50});
        return options;
    }

    /**
     * Call method on child cmp to remove the selected checkbox option.
     * The child will process this, uncheck the checkbox and refire the varianceoptionsselected event
     * if a variance option was removed or refire the collectiondateoptionselected if a collection date picklist option
     * was removed.
     *
     * @param evt
     */
    removeFilterPill(evt) {
        const value = evt.currentTarget.name;
        this._logger.logDebug('removeFilterPillName',value);
        const cmpFilters = this.template.querySelector('c-cl-linked-rps-filters');
        if(cmpFilters && value) {
            if(this.isNumber(value)) {
                //  it's a number such as 30,60,90 ie. collection date pill option.
                cmpFilters.removeSelectedCollectionDateOption(value);
            } else if(value.includes('Variances')) {
                cmpFilters.removeSelectedVarianceOption(value);
            }
        }
    }

    get showRpsRows() {
        return this.rpsWrappers && Array.isArray(this.rpsWrappers) && this.fields && this.rpsWrappers.length > 0;
    }

    get showNoLinkedRps() {
        return !this._isLoading && !this.showRpsRows && this.fields && !this._hasErrors;
    }

    get showStencil() {
        return this._isLoading;
    }

    get filterMenuClass() {
        return this._showFilters ? 'slds-show' : 'slds-hide';
    }

    /**
     * Simulate salesforce cards of showing records (+).
     * @returns {string}
     */
    get cardTitleCustom() {
        let title;
        let totalRecordCount = this.totalRpsRecordCount ? this.totalRpsRecordCount + 1 : null;

        if(this.cardTitle){
            title = this.cardTitle;
        }
        if(this.rpsWrappers) {
            let hasMoreSymbol = '';
            if(totalRecordCount) {
                if(this.rpsWrappers.length > 0 && (totalRecordCount > this.rpsWrappers.length)) {
                    hasMoreSymbol = '+';
                }
            }
            title+= ' ('+this.rpsWrappers.length + `${hasMoreSymbol})`;
        }

        return title;
    }

    /**
     * Appends total record count to the View All link label.
     * @returns {string}
     */
    get viewAllCustom() {
        let title = this.viewAllLabel;
        if(title) {
            //let totalRecordCount = this.totalRpsRecordCount ? this.totalRpsRecordCount + 1 : null;
            let totalRecordCount = this.totalRpsRecordCount;
            if (totalRecordCount && !this._filtersApplied) {
                title += ' ('+totalRecordCount +')';
            }
        }
        return title;
    }


    get showFilterIcon() {
        return  !this._isLoading && this.allowFilterMenuAction;
    }

    get showFilterPills() {
        return this.showFilterIcon && !this._showFilters
            && (
                (this.selectedVarianceOptions && this.selectedVarianceOptions.length > 0)
                || (this.selectedDaysBackCollectionDate));
    }

    get showRowLimitOptions() {
        return this.allowRowLimitOptions && this.rowLimitOptions;
    }

    get customNoRecordsText() {
        let txt;
        if(this._showFilters) {
            txt = 'No Linked RPS Record found for filters applied.';
        } else {
            txt = this.noRecordsText;
        }
        return txt;
    }

    isNumber(n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }

    /**
     * Super generic error logging.
     *
     * @param error         The error object.
     * @param methodName    The method name.
     */
    logError(error, methodName) {
        this._logger.logError('---> full '+methodName+ ' error',error);
        const errorDisplay = uiHelper.reduceErrors(error);
        this._logger.logError('---> reduced '+methodName+ 'error', errorDisplay);
    }


    /* ========= FUTURE USE ONLY ======== */
    /**
     *
     * @param evt
     * @todo not ready for future use only
     */
    handleRpsLinkMouseover(evt) {
        let rpsId = evt.target.dataset.rpsid;
        if(!this.allowCompactLoOnHover) {
            //this._logger.logDebug('on mouseover --> rpsId', rpsId);
            return;
        }
        if(rpsId !== this._objectRecordId && !this._showingCL) {
            //this._objectRecordId = null
            this._logger.logDebug('--> rpsId', rpsId);
            this._objectRecordId = rpsId;
            this._showingCL = true;
            // // eslint-disable-next-line
            // window.clearTimeout(this.delayTimeout);
            // // eslint-disable-next-line @lwc/lwc/no-async-operation
            // this.delayTimeout = setTimeout(() => {
            //     this._objectRecordId = rpsId;
            // }, 250);
        }
    }

    /**
     * @param evt
     * @todo not ready for future use only
     */
    handleRpsLinkMouseout(evt) {
        let rpsId = evt.target.dataset.rpsid;
        if(!this.allowCompactLoOnHover) {
            //this._logger.logDebug('on mouseout --> rpsId', rpsId);
            return;
        }
        this._objectRecordId = null;
        this._showingCL = false;
    }

}