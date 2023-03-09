import {LightningElement,api} from 'lwc';
import Logger from 'c/logger'

/**
 * A generic select object to allow the user to filter number of rows displayed which
 * takes an array of rowLimitOptions and fires the selected option back up to the parent.
 */
export default class UiListLimitFilter extends LightningElement {

    /**
     * An array of options objects to be displayed in the following object format:
     * [ { value:'', label:'', selected:false } ]
     */
    @api rowLimitOptions;

    /**
     * The Label on top of the select if supplied, otherwise label is suppressed.
     */
    @api selectLabel;

    /**
     * A custom style tag applied to the <select> tag.
     */
    @api selectStyle;

    /**
     * Simply turns console debugging on / off and initializes the logger wrapper.
     * @returns {*}
     */
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    _debugConsole;
    _logger;

    connectedCallback() {
        this._logger.logDebug('----> /lwc/uiListLimitFilter','connectedCbk');
    }

    /**
     * Handle the change event of the picklist and fire an event so the parent can listen.
     *
     * @param evt the value of the picklist ie. 5,10,20,50
     */
    handlePlChange(evt) {
        let value = evt.target.value;
        if(this.isNumber(value)) {
            value = parseInt(value);
        }
        let opt = this.rowLimitOptions.find( (item) => item.value === value );
        this._logger.logDebug('----> selected opt being fired in optionselected evt:',opt);
        this.dispatchEvent(new CustomEvent('optionselected', {detail: opt}));
    }

    get showSelectLabel() {
        return this.rowLimitOptions && this.selectLabel;
    }

    isNumber(n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }
}