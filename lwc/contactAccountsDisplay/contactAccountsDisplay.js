import {LightningElement, track, api, wire} from 'lwc';
import retrieveContactAccounts from '@salesforce/apex/ContactsAccountsController.retrieveContactAccounts';
import createAccountContactRelationship from '@salesforce/apex/ContactsAccountsController.createAccountContactRelationship';
import deleteAccountContactRelationship from '@salesforce/apex/ContactsAccountsController.deleteAccountContactRelationship';
import Logger from "c/logger";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import  {registerListener,fireEvent} from 'c/pubSub';
import {CurrentPageReference} from "lightning/navigation";
import accelLwcStyles from '@salesforce/resourceUrl/lwc_styles';
import {loadStyle} from "lightning/platformResourceLoader";
import { NavigationMixin } from 'lightning/navigation';


const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';
const  MAP_KEY_CONTACT_ACCOUNTS = 'MAP_KEY_CONTACT_ACCOUNTS';

const columns = [

    { label: 'DBA Name', fieldName: 'linkName', type: 'url',
        typeAttributes: {
        label: { fieldName: 'accountName' }, target: '_blank'} },
    {
        label: 'Physical Address',
        fieldName: 'accountShippingAddress',
    },
    { label: 'IGB License #', fieldName: 'igbLicenseNumber' },
    { label: 'Relationship Manager', fieldName: 'rmName' },
    {
        label: 'Is HQ?',
        initialWidth: 75,
        fieldName: 'isHqAccount',
        type: 'boolean'
    },
    {
        label: 'Is Direct?',
        initialWidth: 105,
        fieldName: 'isDirect',
        type: 'boolean'
    },
    {
        label: 'Actions',
        type: 'button-icon',
        initialWidth: 100,
        typeAttributes: {
            iconName: 'action:delete',
            title: 'Remove',
            alternativeText: 'Remove'
        },
        cellAttributes: { alignment: 'left' }
    },
];

export default class ContactAccountsDisplay extends NavigationMixin(LightningElement) {

    //  General Utility / Logging stuff
    _hasRendered    = false;
    _debugConsole   = true;
    _className      = 'ContactAccountDisplay';
    _logger         = new Logger(this._debugConsole);
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);
    _wiredContactAccountsForRefresh;

    @api contactId;
    @api contactSelected;
    @api wiredContactAccountsDto;
    @api
    get rowCount() {
        let count = 0;
        if(this.contactAccounts && Array.isArray(this.contactAccounts)) {
            count = this.contactAccounts.length;
        }
        return count;
    }
    @api
    get hasMultipleLocations() {
        return this.rowCount > 1;
    }
    @api
    get showDataDescription() {
        return this.contactSelected && !this.isProcessing;
    }

    @wire(CurrentPageReference) pageRef;

    @track contactAccounts;
    @track columns = columns;
    @track rowOffset = 0;
    @track isProcessing = false;

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
        this.registerListeners();
    }

    @wire(retrieveContactAccounts, {contactId: '$contactId'})
    wiredContactAccountsResults(wiredData) {
        this.isProcessing = true;
        this._wiredContactAccountsForRefresh = wiredData;
        this.wiredContactAccountsDto = Object.assign({}, wiredData);
        const { data, error } = this.wiredContactAccountsDto;
        if(data) {
            if(data.isSuccess) {
                let tmpContactAccounts = (this._accelUtils.getMapValue(MAP_KEY_CONTACT_ACCOUNTS, data.values));
                this.shapeContactAccounts(tmpContactAccounts);
            } else {
                this._accelUtils.logError(this._className + ' retrieveContactAccounts Failed.',data.technicalMsg);
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
    shapeContactAccounts(contactAccounts) {
        let newContactAccounts = [];
        contactAccounts.forEach(contactAccount => {
            let newContactAccount = Object.assign({},contactAccount);
            console.error(newContactAccount);
            newContactAccount.accountName = contactAccount.accountName;
            newContactAccount.accountId = contactAccount.AccountId;
            newContactAccount.linkName = '/'+contactAccount.accountId;
            newContactAccount.accountShippingAddress = this.concatShippingAddress(contactAccount);
            newContactAccount.isHqAccount = !!contactAccount.isHqAccount;
            newContactAccount.isDirect = contactAccount.isDirect;
            newContactAccount.acrId = contactAccount.acrId;
            newContactAccount.igbLicenseNumber = contactAccount.accountIgbNumber;
            newContactAccount.rmName = contactAccount.rmName;
            newContactAccounts.push(newContactAccount);
        });
        this.contactAccounts = newContactAccounts;
        this._accelUtils.logDebug(this._className + ' raw contactAccounts =',JSON.stringify(this.contactAccounts));
    }
    insertAccountContactRelationship( contactId, accountId ) {
        this.isProcessing = true;
       let params = { contactId: contactId, accountId: accountId };
        createAccountContactRelationship(params)
            .then(result => {
                let dto = result;
                if(dto.isSuccess) {
                    let acrCreated = this._accelUtils.getMapValue('MAP_KEY_ACR_CREATED', dto.values);
                    let tmpContactAccounts = this._accelUtils.getMapValue(MAP_KEY_CONTACT_ACCOUNTS, dto.values);
                    this.shapeContactAccounts(tmpContactAccounts);
                    let msg = 'Location '+ acrCreated.Account.Name + ' successfully added for contact '
                        + acrCreated.Contact.Name;
                    this.isProcessing = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: msg,
                            variant: 'success',
                        }),
                    );
                }
            })
            .catch(error => {
                this.isProcessing = false;
                console.error(JSON.stringify(error));
                this.isRunningUpdate = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while updating record',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    removeAccountContactRelationship( accountContactRelationId ) {
        this.isProcessing = true;
        let params = {  accountContactRelationId : accountContactRelationId };
        deleteAccountContactRelationship(params)
            .then(result => {
                let dto = result;
                if(dto.isSuccess) {
                    let acrDeleted = this._accelUtils.getMapValue('MAP_KEY_ACR_DELETED',dto.values);
                    let tmpContactAccounts = this._accelUtils.getMapValue(MAP_KEY_CONTACT_ACCOUNTS,dto.values);
                    this.shapeContactAccounts(tmpContactAccounts);
                    let msg = acrDeleted.Contact.Name + ' successfully removed from '+acrDeleted.Account.Name;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: msg,
                            variant: 'success',
                        }),
                    );
                }
                this.isProcessing = false;
                fireEvent(this.pageRef,'removeLocGrowthChart',true);
                fireEvent(this.pageRef,'refreshAllLocRevenueData',true);
            })
            .catch(error => {
                this.isProcessing = false;
                console.error(JSON.stringify(error));
                this.isRunningUpdate = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while updating record',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    toastAcrCreateSuccess() {

    }
    loadCustomStyles() {
        loadStyle(this, accelLwcStyles + '/lwc_datatable_styles.css').then( () => {
            this.log('DEBUG','lwc_datatable_styles loaded');
        }).catch (error => {
            console.log(error);
        });
    }
    handleRowAction(event) {
        const row = event.detail.row;
        if(row && row.acrId) {
            this.removeAccountContactRelationship(row.acrId);
        }
    }
    createAccountContactRelationship(accountSelected) {
        let accountId = accountSelected.id;
        this.insertAccountContactRelationship(this.contactId, accountId);
    }
    handleAccountSelected(accountSelected) {
        if(accountSelected) {
            this.createAccountContactRelationship(accountSelected);
        }
    }
    handleContactRedirect(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contactId,
                objectApiName: 'Contact',
                actionName: 'view'
            },
        });
    }
    registerListeners() {
        registerListener('accountSelected', this.handleAccountSelected, this);
    }
    concatShippingAddress(contactAccount) {
        let concatAddress = '';
        let fullAddressObj = contactAccount.accountShippingAddress;
        if(fullAddressObj) {
            concatAddress += fullAddressObj.street;
            if(fullAddressObj.city) { concatAddress += ' ' + fullAddressObj.city;}
            if(fullAddressObj.state) {concatAddress += ' ' + fullAddressObj.state;}
        }
        return concatAddress;
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