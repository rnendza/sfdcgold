import {LightningElement, track, api, wire} from 'lwc';
import retrieveSObjectResults from '@salesforce/apex/RecordAutocompleteController.retrieveSObjectResults';
import retrieveSelectedSObjectResult from '@salesforce/apex/RecordAutocompleteController.retrieveSelectedSObjectResult';
import Logger from "c/logger";
import {fireEvent, registerListener} from "c/pubSub";
import {CurrentPageReference} from "lightning/navigation";
import FORM_FACTOR from "@salesforce/client/formFactor";
import {uiHelper} from "c/fslUiHelper";

const  MAP_KEY_SOBJECT_RESULTS          = 'MAP_KEY_SOBJECT_RESULTS';
const  MAP_KEY_SELECTED_SOBJECT_RESULT  = 'MAP_KEY_SELECTED_SOBJECT_RESULT';

const SEARCH_DELAY = 350; // Wait x ms after user stops typing then, perform search. ie de-bounce
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export default class FslRecordLookupSearch extends LightningElement {

    static delegatesFocus = true;
    @wire(CurrentPageReference) pageRef;

    //  The unique identifier of the lookup field ie. userLookup
    @api        customId;
    //  @todo for future use. will focus the read only input upon page load?
    @api        customautofocus = false;
    //  @todo for future use. For custom required indicator?
    @api        customrequired = false;
    @api        valueRequired = false;
    //  Placeholder for the form version of the lookup ie. read only
    @api        readOnlyPlaceHolder = 'Default Placeholder';
    //  Field Level Help (Icon will show if not null)
    @api        fieldLevelHelp;
    //  Placeholder for the editable search box.
    @api        searchPlaceHolder = 'Default Placeholder';
    //  Label for the Read-Only lookup field (displayed on the form).
    @api        searchLabel;
    //  Type of sObject.
    @api        sObjectApiName = 'Contact';
    //  Plural label for sObject.
    @api        sObjectLabel;
    //  Icon to the left of search results.
    @api        optionIconName = 'standard:search';
    //  Primary Search Results Field  * REQUIRED *
    @api        primaryDisplayField = 'Name';
    //  Secondary Search Result Field
    @api        secondaryDisplayField = null;

    @api        secondaryDisplayFieldAddressProperty1;
    @api        secondaryDisplayFieldAddressProperty2;
    @api        secondaryDisplayFieldAddressProperty3;
    @api        secondaryDisplayFieldIsAddressField;
    @api        thirdDisplayField = null;
    //  Primary Filter Field (Where Criteria)  * REQUIRED *
    @api        primaryFilterField  = 'Name';
    @api        secondaryFilterField = null;
    @api        additionalWhereCriteria;
    //  Order by Clause (without the order by keyword)
    @api        orderByClause = ' Name ASC';
    @api        wiredSObjectResultsDto;
    @api        minCharacters = 3;
    @api        maxRows = 100;
    @api        preloadResults;
    @api        formLabelClass = 'c3llc-form-labels';
    @api        inputStyle = '';
    @api
    get displaySecondaryField() { return this.secondaryDisplayField }

    @api
    get labelClass() {
        return  this._labelClass;
    }
    set labelClass(val) {
        this._labelClass += ' ' + val;
    }
    @api
    get defaultSelected() {
        return this._defaultSelected;
    }
    set defaultSelected(val) {
        if (val) {
            this._defaultSelected = val;
            this.log(DEBUG,'child set default selected _defaultSelected',val);
            if(val === true) {
                this.preloadResults = true;
                this.log(DEBUG,'forcing preload results',val);
            }
            if(!this._recordSelected) {
                this.searchForRecordData(null);
            }
        }
    }
    @api
    get defaultTerm() {
        return this._defaultTerm;
    }
    set defaultTerm(val) {
        if(val) {
            this._defaultTerm = val;
        }
    }
    @api
    get triggerFocus() {
        return this._triggerFocus;
    }
    set triggerFocus(val) {
        if(val) {
            this._triggerFocus = val;
            if(this._triggerFocus) {
                const inputBox = this.template.querySelector('lightning-input');
                if (inputBox) {
                    inputBox.focus();
                }
                this._triggerFocus = false;
            }
        }
    }

    //  Private / Reactive
    @track      sObjectResults = [];
    @track      term = '';
    @track      processing = false;
    @track      selectedSObjectData;

    //  General Utility / Logging stuff
    _wiredDefaultSelectedDto;
    _hasRendered    = false;
    _debugConsole   = true;
    _className      = 'FslRecordLookupSearch';
    _logger         = new Logger(this._debugConsole);
    _anySearchEntered = false;
    _recordSelected;
    _labelClass = 'slds-form-element__label';
    _defaultTerm;
    _defaultSelected;
    _searchThrottlingTimeout;
    _resultsPreloaded = false;
    _triggerFocus = false;
    _showFormFieldError;
    _inputFocused;
    _showSearchInput;
    _showSearchInputReadOnly = true;
    _hasProcessedInitialDefaultSelected;

    constructor() {
        super();
    }

    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
            this.registerListeners();
            if(this.customautofocus) {
                const inputBox = this.template.querySelector('lightning-input');
                if(inputBox) {
                    inputBox.focus();
                }
            }
            if(this.inputStyle) {
                this.appendInputStyle();
            }
        }
    }
    connectedCallback() {
        if(this.preloadResults) {
            this.searchForRecordData(null);
        }
    }

    /**
     * Retrieve a single sObject for the default selected id.
     * @param wiredData
     */
    @wire(retrieveSelectedSObjectResult, {
        sObjectApiName: '$sObjectApiName', primaryDisplayField: '$primaryDisplayField',
        secondaryDisplayField: '$secondaryDisplayField', defaultRecordSelectedId: '$_defaultSelected'
    })
    wiredDefault(wiredData) {
        this._wiredDefaultSelectedDto = wiredData;
        const {data, error} = wiredData;
        this.log(DEBUG, 'wired default selected data result for id='+this._defaultSelected, wiredData);
        if (data) {
            if (data.isSuccess) {
                this._dataRefreshTime = new Date().getTime();
                this.selectedSObjectData = uiHelper.getMapValue(MAP_KEY_SELECTED_SOBJECT_RESULT, data.values);
                this.log(DEBUG, 'selectedSObjectData', this.selectedSObjectData);
                this.processInitialDefaultSelected();
            }
        } else if (error) {
            this.log(ERROR,'error getting default selected id data',error);
        }
    }

    handleBlur(event) {

    }

    /**
     * Dispatch an inputfocusedout out event for the field that lost focus.
     * @param evt
     */
    handleBackClick(evt) {
        this.log(DEBUG,'--> handleBackClick child. RECORD SELECTED',this._recordSelected);
        const fieldId = evt.currentTarget.dataset.id;
        const detail = {value: 'inputfocusedout',customId:fieldId};
        this.log(DEBUG,'--> handleBackClick child. fire inputfocusedout detail',detail);
        this.dispatchEvent(new CustomEvent('inputfocusedout', {bubbles: false, detail: detail}))
        this._inputFocused = false;
        this._showSearchInput = false;
    }

    handleInputKeyDown(event) {
        if(event.key) {
            if(event.key === 'ArrowDown') {

            }
        }
    }

    handleReadOnlyClear(evt) {
        //let value = evt.target.value;
        this.term = null;
        this._defaultSelected = null;
        this.log(DEBUG,'---> child handleReadOnlyClear term:',this.term);
        this._recordSelected = null;
        this.fireRecordSelected();
        this._showSearchInput = true;
        this.dispatchEvent(new CustomEvent('inputfocused', {bubbles: false, detail: {value: 'inputfocused',customId: this.customId}}))
    }

    fireRecordSelected() {
        // Unselect (for visual purposes) anything that was previously selected and select this one
        let prevSelected = this.sObjectResults.find(x => x.selected);
        if(prevSelected) {
            prevSelected.selected = false;
            prevSelected.cssClass = '';
        }
        if(this._recordSelected) {
            let newSelected = this.sObjectResults.find(x => x.id === this._recordSelected.id);
            if(newSelected) {
                newSelected.selected = true;
                newSelected.cssClass = 'accel-list-item-selected';
            }
        }
        let recordClicked = {recordClicked: this._recordSelected,customId: this.customId,searchTerm:this.term};
        this.log(DEBUG,'---> child fireRecordSelected detail:',recordClicked);
        this.dispatchEvent(new CustomEvent('recordselected', {bubbles: false, detail: {value: recordClicked}}))
    }
    /**
     *cc
     * @param event
     */
    handleSearchInputChange(event) {
        let value = event.target.value;
        this.term = value;
        this.log(DEBUG,'---> child handleSearchInputChange term',this.term);
        if(value && value.length >= this.minCharacters) {
            this._anySearchEntered = true;
            if(this._searchThrottlingTimeout) {
                clearTimeout(this._searchThrottlingTimeout);
            }
            this._searchThrottlingTimeout = setTimeout(() => {this.searchForRecordData(this.term);}, SEARCH_DELAY );
        } else if (value === '') { // clear ie x on right side of input
            this.term = null;
            this.selectedSObjectData = undefined;
            this._defaultSelected = undefined;
            this.log(DEBUG,'handleSearchInputChange Clear term',this.term);
            this._recordSelected = undefined;
            this.fireRecordSelected();
            this.searchForRecordData(null);
        }
    }

    handleRecordKeyDown(event) {
        if(event.key) {
            if(event.key === 'Enter') {
                this.handleRecordClicked(event);
            }
        }
    }
    handleReadOnlyClick(evt) {

        this._showSearchInput = true;
        const fieldId = evt.currentTarget.dataset.id;
        const detail = {value:'inputFocused',customId:fieldId}
        this.log(DEBUG,'---> child handleReadOnlyClick  fire input focused detail:',detail);
        this.dispatchEvent(new CustomEvent('inputfocused', {bubbles: false, detail: detail}))

    }
    /**
     *
     * @param event
     */
    handleRecordClicked(event) {
        event.stopPropagation();
        let recordId = event.currentTarget.dataset.id;
        this._recordSelected = this.sObjectResults.find(x => x.id === recordId);
        this.log( DEBUG, '---> child recordSelected: ', JSON.stringify(this._recordSelected));
        if(this._recordSelected) {
            this._anySearchEntered = false;
            this._showFormFieldError = false;
            this.term = this._recordSelected.primaryDisplayValue;
           // this.closeAutocompleteTrigger();
            this.fireRecordSelected();
            const detail = {value: 'inputfocusedout',customId: this.customId};
            this.log( DEBUG, '---> child fireInputFocusedOut- detail ', detail);
            this.dispatchEvent(new CustomEvent('inputfocusedout', {bubbles: false, detail: detail}))
            this._inputFocused = false;
            this._showSearchInput = false;
        }
    }
    processInitialDefaultSelected() {
        this.log(DEBUG,'---> child processDefaultSelected selectedSObjectData ',this.selectedSObjectData);

        if(!this.selectedSObjectData || this._hasProcessedInitialDefaultSelected) {
            //return;
        }
        this._hasProcessedInitialDefaultSelected = true;
        let currentSelectedRecord = this.sObjectResults.find(x => x.id === this.selectedSObjectData.Id);
        if(currentSelectedRecord) {
            this.sObjectResults = this.sObjectResults.filter(x => x.id !== currentSelectedRecord.id);
            // return
        }
        let shapedData = {};
        shapedData.primaryDisplayValue = this.selectedSObjectData[this.primaryDisplayField];
        shapedData.secondaryDisplayValue = this.selectedSObjectData[this.secondaryDisplayField];
        shapedData.id = this.selectedSObjectData.Id;
        shapedData.selected = true;
        shapedData.cssClass = 'accel-list-item-selected';
        this.log(DEBUG,'processDefaultSelected shapedSObject ',shapedData);
        this.term = shapedData.primaryDisplayValue;

        if(shapedData.secondaryDisplayValue) {
            if(Date.parse(shapedData.secondaryDisplayValue)) {
                let sDate = new Date(shapedData.secondaryDisplayValue).toLocaleDateString();
                shapedData.secondaryDisplayValue = sDate;
            }
        }
        if(this.sObjectResults && this.sObjectResults.length > 0 ) {
           this.sObjectResults.unshift(shapedData);
        } else {
           // if(this.term )
           // this.sObjectResults.push(shapedData);
        }
    }


    get showProgressBar() {
        return this.processing;
    }
    /**
     *
     * @param event
     */
    handleInputFocus(event) {
        this.log(DEBUG,'child onfocus');
        const inputBox = this.template.querySelector('lightning-input');
        this._showSearchInput = false;
        if(inputBox) {
            if(this.term) {
                this.dispatchEvent(new CustomEvent('inputfocused', {bubbles: false, detail: {value: 'inputfocused'}}))
                this._inputFocused = true;
                this._showSearchInputReadOnly = false;
            }

            // inputBox.focus();
            if(this.isFslMobile) {
                inputBox.scrollIntoView({behavior: "smooth", block: "start", inline: "nearest"});
            }
        }
        if(this.sObjectResults && Array.isArray(this.sObjectResults) && this.sObjectResults.length > 0) {
        } else {
            if(!this._resultsPreloaded) {
                this.searchForRecordData(null);
            }
        }
    }
    searchForRecordData(term) {
        this.processing = true;
        const params = {
            sObjectApiName: this.sObjectApiName, primaryDisplayField: this.primaryDisplayField,
            iMinCharacters: this.minCharacters, secondaryDisplayField: this.secondaryDisplayField,
            searchTerm: term,
            primaryFilterField: this.primaryFilterField,
            secondaryFilterField: this.secondaryFilterField,
            additionalWhereCriteria: this.additionalWhereCriteria,
            orderByClause: this.orderByClause,
            defaultRecordSelectedId: this._defaultSelected,
            preloadResults: this.preloadResults, iMaxRows : this.maxRows
        };
        this.log( DEBUG, '---> child calling searchForRecordData with parms', JSON.stringify(params));

        retrieveSObjectResults(params)
            .then(result => {
                this.processing = false;
                const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item);
                let dto = result;
                this.log(DEBUG, '--> child dto tech msg', dto.technicalMsg);
                let tmpResults = [];
                if (dto.isSuccess) {
                    tmpResults = uiHelper.getMapValue(MAP_KEY_SOBJECT_RESULTS, dto.values);
                    this.log(DEBUG,'---> child raw sObjectResults =',tmpResults);
                } else {
                    this.log(ERROR, '--> child error getting record data', dto);
                }
                this.shapeData(tmpResults);
            })
            .catch(error => {
                this.processing = false;
                this.log(ERROR, '---> child error on SS Call', JSON.stringify(error));
            });
    }
    shapeData(sobjects) {
        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item);
        let clonedSObjects = clone(sobjects);
        let dateFormatter = this.dateFormatter;
        try {
            clonedSObjects.forEach((x, idx, array) => {
                let shapedData = {};
                shapedData.primaryDisplayValue = x[this.primaryDisplayField];
                if (this.secondaryDisplayField && this.secondaryDisplayFieldIsAddressField) {
                    this.parseAddressData(shapedData,x);
                } else {
                    if (this.secondaryDisplayField && this.secondaryDisplayField.includes('.')) {
                        shapedData.secondaryDisplayValue =
                            this.convertStringToRef(x, this.secondaryDisplayField);
                    } else if (this.secondaryDisplayField) {
                        shapedData.secondaryDisplayValue = x[this.secondaryDisplayField];
                    }
                    if(shapedData.secondaryDisplayValue) {
                        if(Date.parse(shapedData.secondaryDisplayValue)) {
                            let sDate = new Date(shapedData.secondaryDisplayValue).toLocaleDateString();
                               shapedData.secondaryDisplayValue = sDate;
                        }
                    }
                }
                if(this.thirdDisplayField) {
                    shapedData.thirdDisplayField = x[this.thirdDisplayField];
                }
                shapedData.id = x.Id;
                clonedSObjects[idx] = shapedData;
            });
        } catch (e) {
            console.error(e);
        }
        this.sObjectResults = clonedSObjects;
        this.log(DEBUG,'shapeData');
        if(this.selectedSObjectData) {
            this.processInitialDefaultSelected();
        }
        // if(this._defaultSelected && !this._recordSelected) {
        //     this.processInitialDefaultSelected();
        // }
        if(this.preloadResults) {
            this._resultsPreloaded = true;
        }

        //this.highlightSearchTerms();

        if(this.sObjectResults && this.sObjectResults.length > 0  && this._anySearchEntered) {


            // if(!this.preloadResults) {
            if (this._anySearchEntered) {
                //this.openAutocompleteTrigger();
            }
            // }
        } else {
            //this.closeAutocompleteTrigger();
        }
    }


    registerListeners() {
        registerListener('eventOuterContainerClicked', this.handleOuterContainerClicked, this);
        registerListener('eventCloseAllOtherAutoCompletes', this.handleCloseAllOtherAutoCompletes, this);
    }
    handleOuterContainerClicked(payload) {
        this.log(DEBUG,'handle evt outer container clicked pl',payload);
        //this.closeAutocompleteTrigger();
        if(!this._recordSelected && this.term) {
            this._showFormFieldError = true;
        } else {
            this._showFormFieldError = false;
        }
    }
    handleAutocompleteClicked(event) {
        event.stopPropagation();
        if(event.target.dataset && event.target.dataset.customId) {
            if(event.target.dataset.customId === this.customId) {
                fireEvent(this.pageRef, 'eventCloseAllOtherAutoCompletes', this.customId);
            }
        }
    }
    handleInfoOptionClicked(evt) {
        evt.stopPropagation();
    }
    handleCloseAllOtherAutoCompletes(payload) {
        if(payload && payload !== this.customId) {
            //this.closeAutocompleteTrigger();
        }
    }
    handleSearchInputClick(evt) {

    }
    parseAddressData(shapedData,x) {
        if (this.secondaryDisplayFieldAddressProperty1) {
            shapedData.secondaryDisplayValue =
                this.convertStringToRef(x, this.secondaryDisplayField+'.'
                    +this.secondaryDisplayFieldAddressProperty1);
        }
        if (this.secondaryDisplayFieldAddressProperty2) {
            shapedData.secondaryDisplayValue += ' ' +
                this.convertStringToRef(x, this.secondaryDisplayField+'.'
                    +this.secondaryDisplayFieldAddressProperty2);
        }
        if (this.secondaryDisplayFieldAddressProperty3) {
            shapedData.secondaryDisplayValue += ' ' +
                this.convertStringToRef(x, this.secondaryDisplayField+'.'
                    +this.secondaryDisplayFieldAddressProperty3);
        }
    }
    convertStringToRef(object, reference) {
        function arr_deref(o, ref, i) {
            let ret = '';
            ret = !ref ? o : (o[ref.slice(0, i ? -1 : ref.length)]);
            if(!ret) {
                ret = '';
            }
            return ret;
        }
        function dot_deref(o, ref) {
            let ret ='';
            if(ref) {
                try {
                    ret = !ref ? o : ref.split('[').reduce(arr_deref, o);
                } catch (e) {
                    console.error(e);
                }
            }
            return ret;
        }
        return reference.split('.').reduce(dot_deref, object);
    }

    get numResultsContainerClass() {
        let cls = '';
        if(!this.processing) {
            let iNum = 0;
            if(this.sObjectResults) {
                iNum = this.sObjectResults.length;
            }
            if(iNum > 0) {
                cls = 'accel-results-found_container'
            } else  {
                cls = 'accel-noresults-found_container';
            }
        }
        return cls;
    }


    get showSearchInputReadOnly() {
        return this._showSearchInputReadOnly;
    }
    get showSearchResults() {
        return this.isExpanded;
    }

    get showSearchInput() {
        return this._showSearchInput;
    }
    get numResultsMsg() {
        let iNum = 0;
        if(this.sObjectResults) {
            iNum = this.sObjectResults.length;
        }
        let msg = iNum + ' item';
        if(iNum > 1 || iNum === 0) {
            msg +='s'
        }
        return msg;
    }


    appendInputStyle() {
        let target = this.template.querySelector('.fake-input-overrides-class');
        target.appendChild(this.inputStyle);
    }

    get showSearchCriteria() {
        return this.term;
    }
    get searchCriteriaLabel() {
        return ' "'+this.term+'" in '+this.sObjectLabel;
    }

    /**
     * @todo need something better than this!
     * @returns {boolean}
     */
    get isFslMobile() {
        return FORM_FACTOR === 'Small';
    }

    get dateFormatter() {
        return new Intl.DateTimeFormat('en', {
            year: "numeric",
            month: "numeric",
            day: "numeric"
        })
    }

    /**
     *
     * @param logType  The type of log (see the constants). (optional)
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
            if(msg) {
                if(this._className) {
                    msg = this._className + ' - ' + msg;
                }
            }
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