import {LightningElement,api} from 'lwc';

export default class ClRpsBvTypeTotals extends LightningElement {

    @api rpsWrapper;

    get showBvTypeData() {
        return this.rpsWrapper && this.rpsWrapper.hasBvTypes;
    }

    get bvTypesString() {
        let displayVal;
        if(this.showBvTypeData) {
            displayVal = this.formatBvTypeDisplay();
        }
        return displayVal;
    }

    formatBvTypeDisplay() {
        let displayVal = '';
        if(this.rpsWrapper.totalJcmBvType !== 0) {
            displayVal += this.rpsWrapper.totalJcmBvType +' JCM,';
        }
        if(this.rpsWrapper.totalMeiBvType !== 0) {
            displayVal += this.rpsWrapper.totalMeiBvType +' MEI,';
        }
        if(this.rpsWrapper.totalSmallMeiBvType !== 0) {
            displayVal += this.rpsWrapper.totalSmallMeiBvType +' Small MEI,';  
        }

        if(displayVal != '') {
            displayVal = displayVal.replace(/,\s*$/, "");
        }
        return displayVal;
    }
}