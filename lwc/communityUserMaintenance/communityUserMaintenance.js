import {LightningElement,wire,track,api} from 'lwc';
import retrievePortalUsers from '@salesforce/apex/ContactsAccountsController.retrievePortalUsers';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import accelLwcStyles from '@salesforce/resourceUrl/lwc_styles';
import {loadStyle} from "lightning/platformResourceLoader";


// row actions
const actions = [
    { label: 'Reset Pw', name: 'reset_pw'},
    { label: 'Delete', name: 'delete'},
    { label: 'Freeze', name: 'freeze'}
];

const contactColumns = [
    { label: 'Name', fieldName: 'userFullName' },
    { label: 'Username', fieldName: 'userName' },
    { label: 'Email', fieldName: 'userEmail' },
    { label: 'Primary Account', fieldName: 'primaryAccountName' },
    {label: 'Last Login', fieldName: 'lastLoginDate', type: 'date-local'},
    {label: 'Failed Logins', fieldName: 'numberOfFailedLogins'},
    {
        type: 'action',
        typeAttributes: {
            rowActions: actions,
            menuAlignment: 'right'
        }
    },
    ];

export default class CommunityUserMaintenance extends LightningElement {

    _hasRendered    = false;
    _debugConsole   = true;
    _accelUtils     = new AccelUtilsSvc(this._debugConsole);

    @track rowOffset = 0;
    @track isProcessing = false;
    @track wiredPortalUsers;
    @track wiredPortalUsersDto;
    @track portalUsers = [];
    @track contactColumns = contactColumns;

    @api activeTabValue = 'Contacts';

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

    @wire(retrievePortalUsers)
    wiredResults(wiredData) {
        this.isProcessing = true;
        this.wiredPortalUsers = wiredData;
        this.wiredPortalUsersDto = Object.assign({}, wiredData);
        const { data, error } = this.wiredPortalUsersDto;
        if(data) {
            if(data.isSuccess) {
                let tmp  = this._accelUtils.getMapValue('portalUsers', data.values);
                this.shapePortalUsers(tmp);
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
    shapePortalUsers(portalUsers) {
        let newPortalUsers = [];
        portalUsers.forEach(u => {
            let newPortalUser = {};
            newPortalUser.userName = u.Username;
            newPortalUser.userId = u.Id;
            newPortalUser.userFullName = u.Name;
            newPortalUser.userEmail = u.Email;
            newPortalUser.lastLoginDate = u.LastLoginDate;
            newPortalUser.numberOfFailedLogins = u.NumberOfFailedLogins;
            newPortalUser.primaryAccountName = u.Contact.Account.Name;
            newPortalUsers.push(newPortalUser);
        });
        this.portalUsers = newPortalUsers;
        console.warn(JSON.stringify(this.portalUsers));
    }
    handleRowAction(event) {
        const row = event.detail.row;
        alert('ROW Action TODO: '+JSON.stringify(row));
    }
    handleTabSelect(event) {
        let tab = event.target.label;
        //this.activeTabValue = tab;
        // this.previewActive = tab === 'Preview';
        // if(this.previewActive && this.showPreview) {
        //     fireEvent(this.pageRef,'removeLocGrowthChart',true);
        //     fireEvent(this.pageRef,'refreshAllLocRevenueData',true);
        // }
    }
    loadCustomStyles() {
        loadStyle(this, accelLwcStyles + '/lwc_datatable_styles.css').then( () => {

        }).catch (error => {
            console.log(error);
        });
    }
}