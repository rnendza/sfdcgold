import {LightningElement, api,track} from 'lwc';
import {themeOverrider} from "./clRpsSurveyThemeOverrides";
import mainTemplate from "./clRpsSurvey.html";
import { getConstants } from 'c/clConstantUtil';

const GLOBAL_CONSTANTS = getConstants();
const LAST_MOD_DATE_HELP_UPTODATE = 'The time your answers were last saved (your current answers are all saved).';
const LAST_MOD_DATE_HELP_STALE = 'The time your answers were last saved (you need to hit save again to update your answers).';

export default class ClRpsSurvey extends LightningElement {

    //  PUBLIC API most of these are defaults that can be overriden.
    @api rpsId;
    @api objectApiName = 'Route_Processing_Sheet__c';
    @api formClass = 'slds-theme_shade accel-form-theme_shade';
    @api formTitle = 'Questions';
    @api formIcon = 'standard:question_best';
    @api dateIconName = 'utility:save';
    @api formDensity = 'auto';
    @api fieldRteMinHeight = '125px';
    @api showLastModifiedDate;

    /**
     * an array of field objects ie. [{name=apiname,value={optional},variant={optional}}]
     * @see https://developer.salesforce.com/docs/component-library/bundle/lightning-input-field/specification
     */
    @api
    set fields(arr) {
        if(arr && Array.isArray(arr)) {
            try {
                //  shallow copy so we can modify immutable data.
                this.formFields = arr.map(field => ({...field}));
                //  if a field label override was configured.. set the variable to label hidden.
                this.formFields.forEach((field) => {
                    if (field.label) {
                        field.variant = 'label-hidden';
                    }
                });
            } catch (e) {
                console.error(e);
            }
            this._isLoading = true;
        }
    }
    get fields() {
        return this.formFields;
    }

    /**
     * Trigger a hidden submit button so we can properly override the form submit action and capture it.
     */
    @api
    triggerSaveEvent() {
        const submitBtn = this.template.querySelector( ".accel-hidden-submit-button" );
        if(submitBtn) {
            submitBtn.click();
        }
    }

    //  PRIVATE SHIT
    @track formFields;
    _hasOverrodeSfdcCss;
    _isLoading;
    _questionsLastModDate;
    _currentNotesValue;
    _iconClass = 'accel-icon-green';
    _dateTextClass = 'accel-text-green';
    _lastModDateText = LAST_MOD_DATE_HELP_UPTODATE;
    _currentFields; // The SFDC Fields array of objects saved onload.

    constructor() {
        super();
        this._isLoading = true;
        console.info('%c----> /lwc/clRpsSurvey',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    render() {
        return mainTemplate;
    }

    connectedCallback() {}

    /**
     * Override standard SFDC forom field css.
     */
    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
        }
        if(!this._hasOverrodeSfdcCss) {
            themeOverrider.buildFormOverrideCss(this);
        }
    }

    handleLoad(evt) {
        this._isLoading = false;
        const record = evt.detail.records;
        const fields = record[this.rpsId].fields;
        this._currentFields = fields;
        this._questionsLastModDate =  fields.Questions_Last_Modified__c.value;
    }

    handleSubmit(evt) {
        evt.preventDefault();
        //console.log('handle submit survey form');
        const fields = evt.detail.fields;
        fields.Questions_Last_Modified__c = this.formatNowDate();
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(evt) {
        //alert('handleSuccess survey form fields. : '+JSON.stringify(evt.detail.fields));
        this.dispatchEvent( new CustomEvent('rpssurveyformsubmitted', {detail: { success: true }}) );
    }

    handleError(evt) {
        console.error(evt.detail.message);
    }

    /**
     * if the new (changed value) is not equal to the current field value (old value) then change the color
     * of the text to signify to the user it needs to be saved again.
     * @param evt
     */
    handleFieldChange(evt) {
        const fieldValue = evt.detail.value;
        const fieldName = evt.target.dataset.fieldname;
        let oldValue = this._currentFields[fieldName].value;
        let needsSave = fieldValue !== oldValue;
        this._iconClass =  needsSave ? 'accel-icon-orange' : 'accel-icon-green';
        this._dateTextClass = needsSave ? 'accel-text-orange' : 'accel-text-green';
        this._lastModDateText = needsSave ? LAST_MOD_DATE_HELP_STALE : LAST_MOD_DATE_HELP_UPTODATE;
    }

    get showForm() {
        return this.rpsId  && this.objectApiName;
    }

    get showFormContents() {
        return this.rpsId && !this._isLoading;
    }

    get showStencil() {
        return  this._isLoading || this._isSaving;
    }

    get showLastModifiedDate() {
        return this._questionsLastModDate;
    }

    formatNowDate() {
        return new Date().toISOString();
    }
}