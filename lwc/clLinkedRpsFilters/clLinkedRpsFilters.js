import {api,track, LightningElement} from 'lwc';
import Logger from "c/logger";

export default class ClLinkedRpsFilters extends LightningElement {

    @api filterContainerClass = '';
    @api filtersLabel = 'RPS Filters';
    @api cBoxGroupLabel = 'Variance Filters';
    @api collectionDateSelectLabel = 'Collection Date Filters';
    @api allowCollectionDateFilters;
    @api allowRowLimitFilter;   // future use
    @api variancesMap;
    @api defaultRowLimit = 5;   // future use

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value;this._logger = new Logger(this._debugConsole);}

    @api
    get selectedVarianceOptions() { return this._selectedVarianceOptions;}
    set selectedVarianceOptions(value) { this._selectedVarianceOptions = value;}

    /**
     * Public method to remove the selected checkbox option.
     * @param val
     */
    @api
    removeSelectedVarianceOption(val) {
        this.handleRemoveVariance(val);
    }

    /**
     * Public method to remove the selected collection date option
     * @param val
     */
    @api
    removeSelectedCollectionDateOption(val) {
        this.handleRemoveSelectedCollectionDateOption(val);
    }

    @track filtersState={};     // @todo for future use.. to inform parent that things might have been checked.
    @track varianceCboxOptions;
    @track _selectedVarianceOptions = [];
    @track _selectedCollectionDateOption;

    _logger;
    _debugConsole;

    connectedCallback() {
        this._logger.logDebug('----> /lwc/clLinkedRpsFilters','connectedCbk');
        this.buildVarianceCboxOptions();
    }

    /**
     * Build variance check box options.
     */
    buildVarianceCboxOptions() {
        this.varianceCboxOptions = [];
        if(this.variancesMap) {
            this.variancesMap.forEach((value, key) => {
                this.varianceCboxOptions.push({value: key, label: value});
            });
        }
    }

    /**
     * Gets collection date picklist options.
     * @returns {*[]}
     */
    get collectionDateOptions() {
        let options = [];
        options.push({value:null, label:'-- All Collection Dates --', selected:!this._selectedCollectionDateOption});
        options.push({value:10, label:'Last 10 days', selected:this._selectedCollectionDateOption === 10});
        options.push({value:30, label:'Last 30 days', selected:this._selectedCollectionDateOption === 30});
        options.push({value:90, label:'Last 90 days', selected:this._selectedCollectionDateOption === 90});
        return options;;
    }

    /**
     * Gets row limit options
     * @returns {*[]}
     *
     * @todo future use
     */
    get rowLimitOptions() {
        let options = [];
        options.push({value:this.defaultRowLimit, label:this.defaultRowLimit, selected:!this.defaultRowLimit});
        options.push({value:10, label:'10', selected:this.defaultRowLimit === 10});
        options.push({value:20, label:'20', selected:this.defaultRowLimit === 20});
        options.push({value:50, label:'50', selected:this.defaultRowLimit === 50});
        return options;
    }

    /**
     * Removes variance selected option for which the user closed the pill.
     * @param valToRemove
     */
    handleRemoveVariance(valToRemove) {
        this._selectedVarianceOptions =  this._selectedVarianceOptions.filter(value => value !== valToRemove)
        this._logger.logDebug('----> handleRemoveVariance.. new vals selected arr=',this._selectedVarianceOptions);
        let option = {name: name, valuesSelected: this.selectedVarianceOptions};
        this.dispatchEvent(new CustomEvent('varianceoptionsselected', {detail: option}));
    }

    /**
     * Sets the selected option on the collection date picklist back to All Collection Dates.
     * @param valToRemove  not used.
     */
    handleRemoveSelectedCollectionDateOption(valToRemove) {
        this._selectedCollectionDateOption = null;
        this.dispatchEvent(new CustomEvent('collectiondateoptionselected', {detail: null}));
    }

    /**
     * Handle the change event of the picklist and fire an event so the parent can listen.
     * Note: the checkbox group change evt contains all selected values and not just the most recently selected one!
     * @param evt
     */
    handleVarianceChkBoxChange(evt) {
        let values = evt.target.value;
        const name = evt.target.name;
        this._selectedVarianceOptions = values;
        let option = {name: name, valuesSelected: this.selectedVarianceOptions};
        this.dispatchEvent(new CustomEvent('varianceoptionsselected', {detail: option}));
    }

    /**
     * Handle the change event of the picklist and fire an event so the parent can listen.
     * @param evt
     */
    handlePlChange(evt) {
        let value = evt.target.value;
        if(value && this.isNumber(value)) {
            this._selectedCollectionDateOption = Number.parseInt(value);
        } else {
            this._selectedCollectionDateOption = null;
        }
        this.dispatchEvent(new CustomEvent('collectiondateoptionselected', {detail: this._selectedCollectionDateOption}));
    }

    handleCloseClicked(evt) {
        this.dispatchEvent(new CustomEvent('close', {detail: this.filtersState}));
    }

    get showVarianceCBoxValues() {
        return this.varianceCboxOptions;
    }

    get showCollectionDateOptions() {
        return this.allowCollectionDateFilters && this.collectionDateOptions;
    }
    // @todo future use
    get showRowLimitOptions() {
        return this.allowRowLimitFilter && this.rowLimitOptions;
    }

    isNumber(n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }
}