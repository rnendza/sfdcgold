import {LightningElement, wire, track, api} from 'lwc';
import retrieveAllMonthliesForAccounts from '@salesforce/apex/POCDumpAllMonthliesController.retrieveAllMonthliesForAccounts';
import accelLwcStyles from '@salesforce/resourceUrl/lwc_styles';
import {loadStyle} from "lightning/platformResourceLoader";

const columns = [
    {label: 'Month', fieldName: 'hpdDate', type: 'date-local'},
    {label: 'DBA Name',fieldName: 'accountName'}
];

export default class PocAcDumpAllMonthlies extends LightningElement {

    _wiredHoldPerDays;
    _hasRendered = false;

    @api contactId;
    @api isProcessing = false;

    @track holdPerDays;
    @track columns = columns;
    @track rowOffset = 0;

    @api
    get rowCount() {
        let rc = 0;
        if(this.holdPerDays) {
            rc = this.holdPerDays.length;
        }
        return rc;
    }

    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
            this.loadCustomStyles();
        }
    }

    @wire(retrieveAllMonthliesForAccounts, {contactId: '$contactId'})
    wiredResults(wiredData) {
        this.isProcessing = true;
        this._wiredHoldPerDays = wiredData;
        const { data, error } = this._wiredHoldPerDays;
        if(data) {
            this.shapeHpds(data);
            this.isProcessing = false;
        } else if (error) {
            console.error(JSON.stringify(error));
            this.isProcessing = false;
        }
    }
    shapeHpds(hpds) {
        let tmpArray = [];
        hpds.forEach(hpd => {
            let oHpd = Object.assign({},hpd);
            oHpd.hpdDate = hpd.Date__c;
            oHpd.hpdId = hpd.Id;
            oHpd.netRevenue = hpd.Net_Revenue__c;
            oHpd.accountName = hpd.Account__r.Name;
            oHpd.locShare = hpd.Location_Share__c;
            oHpd.fundsIn = hpd.Funds_In__c;
            oHpd.fundsOut = hpd.Funds_Out__c;
            oHpd.vgtCount = hpd.VGT_Count__c;
            tmpArray.push(oHpd);
        });
        this.holdPerDays = tmpArray;
    }
    loadCustomStyles() {
        loadStyle(this, accelLwcStyles + '/lwc_datatable_styles.css').then( () => {
        }).catch (error => {
            console.log(error);
        });
    }
}