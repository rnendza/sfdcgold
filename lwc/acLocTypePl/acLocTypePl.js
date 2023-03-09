import {LightningElement,track,wire} from 'lwc';
import retrieveAvailableLocTypes   from '@salesforce/apex/AcGrowthMetricsController.retrieveAvailableLocTypes';
import AccelUtilsSvc from 'c/accelUtilsSvc';
/**
 *
 */
export default class AcLocTypePl extends LightningElement {

    @track value = 'All'; //  Default
    @track locationLocTypeOptions = [];
    _debugConsole = true; //@TODO passed in property / custom meta.
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _className = 'AcLocTypePl';

    connectedCallback() {
        this._accelUtils.logDebug(this._className+ ' --- connectedCallback ---');
    }
    /**
     *
     */
    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;
        this._accelUtils.logDebug(this._className+ ' --- renderedCallback ---');
        this.buildOverrideCss();
    }

    /**
     *
     * @param wiredAvailableLocTypes
     */
    @wire(retrieveAvailableLocTypes)
    wiredAvailableLocTypesData(wiredAvailableLocTypes) {
        if(wiredAvailableLocTypes.data) {
            let plOptions = [{label:'All Types', value:'All'}];
            //plOptions.push({label:'BAD BOGUS VALUE', value:'BAD BOGUS VALUE'});
            wiredAvailableLocTypes.data.forEach(function (item, index) {
                plOptions.push({label: item, value: item}   );
            });
            this.locationLocTypeOptions = plOptions;
        }
    }

    /**
     *
     * @param event
     */
    handleChange(event) {
        //this.value = event.detail.value;
        this.value = event.target.value;
        const selected = new CustomEvent('selected', { detail: this.value });
        this.dispatchEvent(selected);
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
}