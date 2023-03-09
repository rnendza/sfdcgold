import {LightningElement,api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';

const GLOBAL_CONSTANTS  =   getConstants();
const USER_FILTER       =   'userfilter';
const CITY_FILTER       =   'cityfilter';

/**
 * PAAdvisoryFilters will display filter fields and fire textfilterkeypress custom events up to the parent indicating
 * which filter and what values were entered.
 *
 * ie. the parent will do the actual filtering of the data.
 */
export default class PaAdvisoryFilters extends LightningElement {

    @api exclusionTypes;
    @api filterContainerClass = '';
    @api userPlaceHolder = 'Enter name...';
    @api cityPlaceHolder = 'Enter city...';
    @api filtersLabel = 'Photo Filters';
    @api filtersAppliedLabel = 'Filters Applied';
    @api minFilterChars = 2;

    _userFilter;
    _cityFilter;

    constructor() {
        super();
        console.info('%c----> /lwc/paAdvisoryFilters', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     * Fires an event up to the parent so that it can detect the filter key change.
     * @param event
     */
    handleFilterKeyChange(event) {
        const filterKey = event.target.value;
        const filterType = event.target.dataset.filtertype;
        const payload = { filterType: filterType,value: filterKey };
        this.dispatchEvent( new CustomEvent('textfilterkeypress', {detail: payload}) );

        switch (filterType) {
            case USER_FILTER:
                this._userFilter = filterKey;
                break;
            case CITY_FILTER:
                this._cityFilter = filterKey;
                break;
        }
    }

    get _filtersAppliedLabel() {
        if(this.numberOfFiltersApplied) {

        }
    }

    handleClose() {
        this.dispatchEvent( new CustomEvent('closefilters') );
    }

    get numberOfFiltersApplied() {
        let numApplied = 0;
        if(this.filtersApplied) {
            if(this._userFilter && this._userFilter.length >= 2) {
                numApplied++;
            }
            if(this._cityFilter && this._cityFilter.length >= 2) {
                numApplied ++;
            }
        }
    }

    /**
     * Accessor to assist with changing the filter box header text.
     * @returns {boolean}
     */
    get filtersApplied() {
        return (this._userFilter && this._userFilter.length >= 2) || (this._cityFilter && this._cityFilter.length >= 2);
    }
}