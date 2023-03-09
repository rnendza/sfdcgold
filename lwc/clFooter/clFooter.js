import {LightningElement,wire,track} from 'lwc';
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import retrieveUserDetails from '@salesforce/apex/clUserController.retrieveUserDetails';
import {reduceErrors} from "c/ldsUtils";
import AccelUtilsSvc from "c/accelUtilsSvc";
import Id from '@salesforce/user/Id';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { getConstants } from 'c/clConstantUtil';

const MDT_DEV_NAME = 'Application';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const ADMIN_PROFILE_NAME = 'System Administrator';
const MAINT_HEADER = 'MAINTENANCE MESSAGE';
const GLOBAL_CONSTANTS = getConstants();

export default class ClFooter extends LightningElement {

    @track appMdt;
    @track appVersion;
    @track runningUser;
    @track userProfileMsg;
    @track displayProfileWarningText = true;

    _appMdtDevName = MDT_DEV_NAME;
    _wiredAppMdt;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _userId = Id;
    _displayFooter = false;
    _loadDelay = 2000;
    _footerTextDelay = 12000;
    _showMaintenanceToastMsg;
    _showMaintenanceFooterMsg;
    _numTimesPromptDisplayed = 0;
    _maintToastMsg;
    _maintFooterMsg;

    constructor() {
        super();
        console.info('%c----> /lwc/clFooter',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     * Delay the display of this component until the community content block is painted
     * Hide the footer profile blurb after 8 seconds.
     */
    connectedCallback() {
        /* eslint-disable */
        setTimeout(() => {
            //  Here we need to attempt to set a delay as first load in community takes forever
            //  so we are trying to not display the footer until the content appears.
            this._displayFooter = true;
            },this._loadDelay
        );
        setTimeout(() => { this.displayProfileWarningText = false;},this._footerTextDelay);
    }

    /**
     * Fire a toast with a maintenance msg.
     */
    fireMaintenanceToast() {
        if(this._showMaintenanceToastMsg && this._numTimesPromptDisplayed <= 1) {
            this._numTimesPromptDisplayed++;
            this.showToast(MAINT_HEADER,this._maintToastMsg,'warning');
        }
    }

    /**
     * Get full user details (as opposed to just userId, in case it's needed)
     *
     * @param error
     * @param data
     */
    @wire(retrieveUserDetails, { userId: '$_userId' })
    wiredUserDetails({ error, data }) {
        if (data) {
            this.runningUser = data;
            const profileName = this.runningUser.Profile ? this.runningUser.Profile.Name : null;
            if(profileName == ADMIN_PROFILE_NAME) {
                let msg = 'You have logged in as '+profileName+'.';
                msg += '  This profile simulates the navigation of a Coin Collector.';
                this.userProfileMsg = msg;
            }
        } else if (error) {
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving user information: '+this.error,'error');
        }
    }

    /**
     *  Get the app level custom meta-data. Fire maint toast / show in footer if necessary. Also
     *  show the application version.
     *
     *  @param wiredData
     *  @see Cash_Logistics_Setting__mdt (Application type)
     */
    @wire(retrieveMdt, { mdtDevName: '$_appMdtDevName' })
    wiredMdt(wiredData) {
        this._wiredAppMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
        } else if (data) {
            this.appMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
            if(this.appMdt){
                if(this.appMdt.Version__c) {
                    this.appVersion = this.appMdt.Version__c;
                }
                if(this.appMdt.Show_Maintenance_Toast_Msg__c) {
                    this._maintToastMsg = this.appMdt.Maintenance_Toast_Msg__c;
                    this._showMaintenanceToastMsg = true;
                    this.fireMaintenanceToast();
                }
                if(this.appMdt.Show_Maintenance_Footer_Msg__c) {
                    this._maintFooterMsg = this.appMdt.Maintenance_Footer_Msg__c;
                    this._showMaintenanceFooterMsg = true;
                }
            }
        }
    }

    /**
     * For System Admins.. if some warning text displays, allow the user to dismiss.
     * @param evt
     */
    handleDismissWarningText(evt) {
        this.displayProfileWarningText = false;
    }

    /**
     *
     * @param title
     * @param msg
     * @param variant
     */
    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}