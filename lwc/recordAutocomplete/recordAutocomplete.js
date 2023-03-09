import {LightningElement, track, api, wire} from 'lwc';
import retrieveSObjectResults from '@salesforce/apex/RecordAutocompleteController.retrieveSObjectResults';
import Logger from "c/logger";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';
import {loadScript, loadStyle} from "lightning/platformResourceLoader";
import {fireEvent, registerListener} from "c/pubSub";
import {CurrentPageReference} from "lightning/navigation";

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';
const  MAP_KEY_SOBJECT_RESULTS   = 'MAP_KEY_SOBJECT_RESULTS';
const SEARCH_DELAY = 300; // Wait 300 ms after user stops typing then, peform search

export default class RecordAutocomplete extends LightningElement {

    static delegatesFocus = true;


    //  Private / Reactive
    @track      sObjectResults = [];
    @track      comboboxCssClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
    @track      term = '';
    @track      processing = false;
    @track      isExpanded = false;

    @wire(CurrentPageReference) pageRef;

    //  Public / Reactive
    @api        customId;
    @api        customautofocus = false;
    @api        customrequired = false;
    @api        valueRequired = false;
    @api        placeHolder = 'Default Placeholder';
    @api        searchLabel;
    @api        sObjectApiName = 'Contact';
    @api        optionIconName = 'standard:search';
    @api        primaryDisplayField = 'Name';
    @api        secondaryDisplayField = null;
    @api        secondaryDisplayFieldAddressProperty1;
    @api        secondaryDisplayFieldAddressProperty2;
    @api        secondaryDisplayFieldAddressProperty3;
    @api        secondaryDisplayFieldIsAddressField;
    @api        thirdDisplayField = null;
    @api        primaryFilterField  = 'Name';
    @api        secondaryFilterField = null;
    @api        additionalWhereCriteria = ' Community_Contact__c = true ';
    @api        wiredSObjectResultsDto;
    @api        minCharacters = 3;
    @api        maxRows = 5000;
    @api        preloadResults = false;
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
            if(val === true) {
                this.preloadResults = true;
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

    //  General Utility / Logging stuff
    _hasRendered    = false;
    _debugConsole   = false;
    _className      = 'RecordAutocomplete';
    _logger         = new Logger(this._debugConsole);
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);
    _anySearchEntered = false;
    _recordSelected;
    _labelClass = 'slds-form-element__label';
    _defaultTerm;
    _defaultSelected;
    _searchThrottlingTimeout;
    _resultsPreloaded = false;
    _triggerFocus = false;
    constructor() {
        super();
    }
    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
            this.loadFontAwesome();
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
    handleBlur(event) {

    }
    handleInputKeyDown(event) {
        if(event.key) {
            if(event.key === 'ArrowDown') {

            }
        }
    }
    /**
     *
     * @param event
     */
    handleSearchInputChange(event) {
        let value = event.target.value;
        this.term = value;
        if(value && value.length >= this.minCharacters) {
            this._anySearchEntered = true;
            if(this._searchThrottlingTimeout) {
                clearTimeout(this._searchThrottlingTimeout);
            }
            this._searchThrottlingTimeout = setTimeout(() => {
                this.searchForRecordData(this.term);
            }, SEARCH_DELAY );
        } else {
            if (!value) {
                this.sObjectResults = [];
                this.closeAutocompleteTrigger();
                if (this._recordSelected) {
                    this._recordSelected = null;
                    this.dispatchEvent(new CustomEvent('recordselected', {
                        bubbles: false,
                        detail: {value: this._recordSelected}
                    }))
                }
            }
        }
    }
    handleRecordKeyDown(event) {
        if(event.key) {
           if(event.key === 'Enter') {
               this.handleRecordClicked(event);
           }
        }
    }
    /**
     *
     * @param event
     */
    handleRecordClicked(event) {
        event.stopPropagation();
        let recordId = event.currentTarget.dataset.id;
        this._recordSelected = this.sObjectResults.find(x => x.id === recordId);
        this.log( DEBUG, 'recordClicked: ', JSON.stringify(this._recordSelected));
        if(this._recordSelected) {
            this._anySearchEntered = false;
            this.term = this._recordSelected.primaryDisplayValue;
            this.closeAutocompleteTrigger();
            this.dispatchEvent(new CustomEvent('recordselected', {
                bubbles: false,
                detail: {value: this._recordSelected}
            }))
        }
    }
    processInitialDefaultSelected() {
        if(!this._defaultSelected) {
            return;
        }
        let val = this._defaultSelected;
        if(this.sObjectResults && this.sObjectResults.length > 0 ) {
            this._recordSelected = this.sObjectResults.find(x => x.id === val);
            if (this._recordSelected) {
                this._anySearchEntered = false;
                this.term = this._recordSelected.primaryDisplayValue;
                this.closeAutocompleteTrigger();
                this.dispatchEvent(new CustomEvent('recordselected', {
                    bubbles: false,
                    detail: {value: this._recordSelected}
                }))
            }
        }
    }
    moveRecordFocusDown(event) {
        let isOpenMenu = this.isExpanded;

        // if (isOpenMenu) {
        //     var focusIndex = component.get('v.focusIndex');
        //     var options = component.find('lookupMenu').getElement().getElementsByTagName('li');
        //
        //     if (focusIndex === null || focusIndex === options.length - 1) {
        //         focusIndex = 0;
        //     } else {
        //         ++focusIndex;
        //     }
        //
        //     component.set('v.focusIndex', focusIndex);
        // }
    }

    /**
     *
     * @param event
     */
    handleAutocompleteMenuFocusOut(event) {
        let self = this;
       // setTimeout(function() {self.closeAutocompleteTrigger();}, 150);
    }
    /**
     *
     * @param event
     */
    handleInputFocus(event) {
        if(this.sObjectResults && Array.isArray(this.sObjectResults) && this.sObjectResults.length > 0) {
            this.openAutocompleteTrigger();
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
            preloadResults: this.preloadResults, iMaxRows : this.maxRows
        };
        this.log( DEBUG, 'calling searchForRecordData with prams', JSON.stringify(params));

        retrieveSObjectResults(params)
            .then(result => {
                this.processing = false;
                const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item);
                let dto = result;
                let tmpResults = [];
                if (dto.isSuccess) {
                    tmpResults = this._accelUtils.getMapValue(MAP_KEY_SOBJECT_RESULTS, dto.values);
                    this._accelUtils.logDebug(this._className + ' raw sObjectResults =',JSON.stringify(tmpResults));
                } else {
                    this.log(ERROR, 'error getting geo data', JSON.stringify(dto));
                }
                this.shapeData(tmpResults);
            })
            .catch(error => {
                this.processing = false;
                this.log(ERROR, 'error on SS Call', JSON.stringify(error));
            });
    }
    shapeData(sobjects) {
        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item);
        let clonedSObjects = clone(sobjects);
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
        if(this._defaultSelected && !this._recordSelected) {
            this.processInitialDefaultSelected();
        }
        if(this.preloadResults) {
            this._resultsPreloaded = true;
        }

        this.highlightSearchTerms();

        if(this.sObjectResults && this.sObjectResults.length > 0  && this._anySearchEntered) {


            // if(!this.preloadResults) {
            if (this._anySearchEntered) {
                this.openAutocompleteTrigger();
            }
            // }
        } else {
            this.closeAutocompleteTrigger();
        }
    }
    handleBackdropclick(event) {
        this.closeAutocompleteTrigger();
    }
    handlePortalUserCreated(portalContact) {
        this.searchForRecordData(null);
    }
    registerListeners() {
        registerListener('portalUserCreated',this.handlePortalUserCreated,this);
        registerListener('eventOuterContainerClicked', this.handleOuterContainerClicked, this);
        registerListener('eventCloseAllOtherAutoCompletes', this.handleCloseAllOtherAutoCompletes, this);
    }
    handleOuterContainerClicked(payload) {
        this.closeAutocompleteTrigger();
    }
    handleAutocompleteClicked(event) {
        event.stopPropagation();
        if(event.target.dataset && event.target.dataset.customId) {
            if(event.target.dataset.customId === this.customId) {
                fireEvent(this.pageRef, 'eventCloseAllOtherAutoCompletes', this.customId);
            }
        }
    }
    handleCloseAllOtherAutoCompletes(payload) {
        if(payload && payload !== this.customId) {
            this.closeAutocompleteTrigger();
        }
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
    closeAutocompleteTrigger() {
        this.comboboxCssClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click';
        this.isExpanded = false;
    }
    openAutocompleteTrigger() {
        this.comboboxCssClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open';
        this.isExpanded = true;
    }
    /**
     * Loads font awesome js and css for fonts not available in SLDS.
     */
    loadFontAwesome() {
        Promise.all([
            loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/all.css'),
        ])
            .then(() => {
                //console.log('fa loaded');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }
    /**
     *
     */
    highlightSearchTerms() {
        if(this.sObjectResults && Array.isArray(this.sObjectResults) && this.term) {
           //  console.warn('in highlight');
           //  //let searchTerm;
           // // let searchTerm = Object.assign({},this.term);
           // let searchTerm = this.term;
           // var completedString = completedString || searchTerm;
           // try {
           //     console.warn('in highlight searchTerm='+searchTerm);
           //     if (searchTerm) {
           //         this.sObjectResults.forEach(x => {
           //             console.warn('in highlight x.primaryDisplayValue='+x.primaryDisplayValue);
           //             //@Sanya530 :( Maybe try escaping the forward slash (text|simple)(?![^<]*>|[^<>]*<\/)?
           //             var reg = "(" + searchTerm + ")(?![^<]*>|[^<>]*<\\/)?";
           //             var regex = new RegExp(reg, "i");
           //             if (!x.primaryDisplayValue.match(regex)) {
           //                 console.warn('in highlight nomatch');
           //                 return;
           //             }
           //             var matchStartPosition = this.term.match(regex).index;
           //             var matchEndPosition = matchStartPosition + this.term.match(regex)[0].toString().length;
           //             var originalTextFoundByRegex = this.term.substring(matchStartPosition, matchEndPosition);
           //             completedString = completedString.replace(regex, '<mark class="sch-Result_Highlight">'+originalTextFoundByRegex+'</mark>');
           //             console.error('--- searchmatch?-');
           //             console.error(completedString);
           //         });
           //     }
           // } catch (e) {
           //     console.error(e);
           // }
        }
    }
    appendInputStyle() {
        let target = this.template.querySelector('.fake-input-overrides-class');
        target.appendChild(this.inputStyle);
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