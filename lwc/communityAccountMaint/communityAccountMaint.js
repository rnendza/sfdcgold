import {LightningElement,wire,track,api} from 'lwc';
import retrievePortalAccounts from '@salesforce/apex/ContactsAccountsController.retrievePortalAccounts';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import accelLwcStyles from '@salesforce/resourceUrl/lwc_styles';
import {loadStyle} from "lightning/platformResourceLoader";

const accountColumns = [
    { label: 'Name', fieldName: 'accountName' },
    { label: 'Physical Address', fieldName: 'accountShippingAddress' },
    { label: 'Relationship Mgr', fieldName: 'rmName' },
    { label: 'Regional Mgr', fieldName: 'regionalMgr' }
];

export default class CommunityAccountMaint extends LightningElement {

    _hasRendered    = false;
    _debugConsole   = true;
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);

    @track rowOffset = 0;
    @track isProcessing = false;

    @track wiredPortalAccounts;
    @track wiredPortalAccountsDto;
    @track portalAccounts = [];

    @track accountColumns = accountColumns;
    @api currentpage;
    @api pagesize;
    @track searchKey;
    totalpages;
    localCurrentPage = null;
    isSearchChangeExecuted = false;
    // not yet implemented
    pageSizeOptions =
        [
            { label: '10', value: 10 },
            { label: '25', value: 25 },
            { label: '50', value: 50 },
            { label: 'All', value: '' },
        ];

    constructor() {
        super();
    }
    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
            this.loadCustomStyles();
        }
    }
    connectedCallback() {

    }

    @wire(retrievePortalAccounts)
    wiredAccountsResults(wiredData) {
        this.isProcessing = true;
        this.wiredPortalAccounts = wiredData;
        this.wiredPortalAccountsDto = Object.assign({}, wiredData);
        const { data, error } = this.wiredPortalAccountsDto;
        if(data) {
            if(data.isSuccess) {
                let tmp  = this._accelUtils.getMapValue('portalAccounts', data.values);
                this.shapePortalAccounts(tmp);
            } else {

            }
            this.isProcessing = false;
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.isProcessing = false;
        }
    }
    shapePortalAccounts(portalAccounts) {
        let newPortalAccounts = [];
        portalAccounts.forEach(account => {
            let newPortalAccount = {};
            newPortalAccount.accountName = account.Name;
            newPortalAccount.accountId = account.Id;
            newPortalAccount.accountShippingAddress = this.concatShippingAddress(account.ShippingAddress);
            let rmName = account.Relationship_Manager__r ? account.Relationship_Manager__r.Name : '';
            newPortalAccount.rmName = rmName;
            newPortalAccount.regionalMgr = account.Regional_Manager__c;
            newPortalAccounts.push(newPortalAccount);
        });
        this.portalAccounts = newPortalAccounts;
        console.warn(JSON.stringify(this.portalAccounts));
    }
    concatShippingAddress(contactAccount) {
        let concatAddress = '';
        let fullAddressObj = contactAccount;
        if(fullAddressObj) {
            concatAddress += fullAddressObj.street;
            if(fullAddressObj.city) { concatAddress += ' ' + fullAddressObj.city;}
            if(fullAddressObj.state) {concatAddress += ' ' + fullAddressObj.state;}
        }
        return concatAddress;
    }
    handleRowAction(event) {
        const row = event.detail.row;
        alert('ROW Action TODO: '+JSON.stringify(row));
    }
    handleTabSelect(event) {
        let tab = event.target.label;
    }
    loadCustomStyles() {
        loadStyle(this, accelLwcStyles + '/lwc_datatable_styles.css').then( () => {

        }).catch (error => {
            console.log(error);
        });
    }


}