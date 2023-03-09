import {LightningElement,track,api} from 'lwc';
import AccelUtilsSvc from 'c/accelUtilsSvc';

export default class AcStartEndDate extends LightningElement {

    @track startDateValue = '';
    @track endDateValue = '';
    _debugConsole = true; //@TODO passed in property / custom meta.
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _className = 'AcStartEndDate';
    _rawHpdDateData;
    _startDateOptions;
    _endDateOptions;

    _hpdDates;
    _dateSuggestions;

    @track displayStartDateError;
    @track displayEndDateError;
    @track startDateErrorClass = '';
    @track endDateErrorClass = '';
    @track startDateErrorMessage = '';
    @track endDateErrorMessage = '';


    connectedCallback() {
        this._accelUtils.logDebug(this._className+ ' --- connectedCallback ---');
    }
    renderedCallback() {
        if (this.hasRendered) return;
        this.setDatePicklistDefaults();
        this.hasRendered = true;
        this._accelUtils.logDebug(this._className+ ' --- renderedCallback ---');
        this.buildOverrideCss();
    }

    /**
     * There seems to be no lightning-select or equiv.. not sure why. seems like a bad decision on SFDCs part
     * since lightning-combobox is pretty useless and doesn't translate to mobile well. That being said.
     * there is no good way to set the default selected options of an HTML Select in lwc other then JS after rendered.
     */
    setDatePicklistDefaults() {
        let eleStartDateSelect  = this.template.querySelector('[data-id="select-start-date-data-id"]');
        if(eleStartDateSelect) {
            eleStartDateSelect.value = this.startDateValue;
        }
        let eleEndDateSelect  = this.template.querySelector('[data-id="select-end-date-data-id"]');
        if(eleEndDateSelect) {
            eleEndDateSelect.value = this.endDateValue;
        }
    }
    @api
    get hpdDates() {
        return this._hpdDates;
    }
    set hpdDates(hpdDates) {
        this._hpdDates = hpdDates;
        if(hpdDates) {
            let options = this.buildDatePicklists(hpdDates);
            this.startDateOptions = options;
            this.endDateOptions = options;
        }
    }
    @api
    get dateSuggestions() {
        return this._dateSuggestions;
    }
    set dateSuggestions(dateSuggestions) {
        this.startDateValue = dateSuggestions.suggestedDefaultMonthlyStartDate;
        this.endDateValue = dateSuggestions.suggestedDefaultMonthlyEndDate;
    }


    @api
    get hpdDateData() {
        return this._rawHpdDateData;
    }
    set hpdDateData(rawHpdDateData) {
        this._accelUtils.logDebug(this._className+'--- setHpdDateData rawHpdDateData=',rawHpdDateData);
        this._rawHpdDateData = rawHpdDateData;
        let options = this.buildDatePicklists(rawHpdDateData.hpdDates);
        this.startDateOptions = options;
        this.endDateOptions = options;
        if (this._rawHpdDateData && this._rawHpdDateData.dateSuggestions) {
            let _self = this;
            this.startDateValue = this._rawHpdDateData.dateSuggestions.suggestedDefaultMonthlyStartDate;
            this.endDateValue = this._rawHpdDateData.dateSuggestions.suggestedDefaultMonthlyEndDate;
            this._accelUtils.logDebug(this._className + '--- setHpdDateData --- ', this.startDateValue);
        }
    }
    set startDateOptions(options) {
        this._startDateOptions = options;
    }
    get startDateOptions() {
        return this._startDateOptions;
    }
    set endDateOptions(options) {
        this._endDateOptions = options;
    }
    get endDateOptions() {
        return this._endDateOptions;
    }
    @api
    get startDateErrorMessage() {
        return this._startDateErrorMessage;
    }
    set startDateErrorMessage(msg) {
        if(!msg || msg === '') {
            this._startDateErrorMessage = null;
        } else {
            this._startDateErrorMessage = msg;
        }
    }
    /**
     *
     * @param event
     * @TODO combine select handlers
     */
    handleStartDateChange(event) {
        this.startDateValue = event.target.value;
        this._accelUtils.logDebug(this._className+ ' --- handleStartDateChange ---',this.startDateValue);
        this.validSelectedDates(event.target);
        if(!this.displayStartDateError) {
            const selected = new CustomEvent('selectedstartdate', {detail: this.startDateValue});
            this.dispatchEvent(selected);
        }
    }

    /**
     *
     * @param event
     */
    handleEndDateChange(event) {
        this.endDateValue = event.target.value;
        this._accelUtils.logDebug(this._className+ ' --- handleEndDateChange ---',this.endDateValue);
        this.validSelectedDates(event.target);
        if(!this.displayEndDateError) {
            const selected = new CustomEvent('selectedenddate', {detail: this.endDateValue});
            this.dispatchEvent(selected);
        }
    }

    /**
     * Overcome Shadow DOM and CSS Isolation of standard SFDC Components.
     * Gets any existing attributes and then APPENDS new ones.
     */
    buildOverrideCss() {
        let target = this.template.querySelector('.slds-form-element__label');
        if(target) {
           target.setAttribute('class',  target.getAttribute('class') + ' accel-combobox' );
        }
    }

    /**
     * Takes a apex date such as '2019-07-01' .. creates a new js dhate which gives us
     * 'Sun Jun 30 2019 19:00:00 GMT-0500 (Central Daylight Time)' then appropriately converts this
     * back to 'Mon Jul 01 2019 00:00:00 GMT-0500 (Central Daylight Time)'
     *
     * @param sDate
     * @returns {Date}
     */
    convertApexStringDateToLocalDate(sDate) {
        let utcDate = new Date(sDate);
        return new Date(utcDate.getTime() + utcDate.getTimezoneOffset() * 60000);
    }

    /**
     *
     * @param hpdDates
     * @returns {[]}
     */
    buildDatePicklists(hpdDates) {
        let hpdFormattedDateOptions = [];
        if(hpdDates) {
            for(let i=0; i<hpdDates.length; i++){
                let monthlyHpdDate = hpdDates[i];
                let realDate = this.convertApexStringDateToLocalDate(monthlyHpdDate.hpdDate);
                hpdFormattedDateOptions.push({
                    value: monthlyHpdDate.hpdDate,
                    label: this.getPicklistDateYearDisplay(realDate),
                    selected: ''
                });
            }
        }
        return hpdFormattedDateOptions;
    }
    getPicklistDateYearDisplay(dt) {
        let s = '';
        var options = {year: 'numeric', month: 'short'};
        s = dt.toLocaleDateString('en-US', options);
        return s;
    }

    /**
     * Really basic / lame form validation. We really should be using a framework like formvalidation.io but for now..
     */
    validSelectedDates(target) {
        let valid = true;
        if(this.startDateValue && this.endDateValue) {
            if(this.startDateValue >= this.endDateValue ) {
                if(target.name === 'startDate') {
                    this.startDateErrorMessage = '<b>From Date</b> must be less then the To Date.';
                    this.startDateErrorClass = ' slds-has-error';
                    this.displayStartDateError = true;
                    this.displayEndDateError = false;
                    this.endDateErrorMessage = '';
                    this.endDateErrorClass = '';
                } else if (target.name === 'endDate') {
                    this.endDateErrorMessage = '<b>To Date</b> must be greater than the From Date.';
                    this.endDateErrorClass = ' slds-has-error';
                    this.displayEndDateError = true;
                    this.displayStartDateError = false;
                    this.startDateErrorMessage = '';
                    this.startDateErrorClass = '';
                }
                valid = false;
            }
        }
        if(valid) {
            this.startDateErrorMessage = '';
            this.startDateErrorClass = '';
            this.endDateErrorMessage = '';
            this.endDateErrorClass = '';
            this.displayStartDateError = false;
            this.displayEndDateError = false;
        }
    }
}