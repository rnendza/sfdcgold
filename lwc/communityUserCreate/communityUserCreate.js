import {LightningElement, api, track, wire} from 'lwc';
import insertPortalContact from '@salesforce/apex/ContactsAccountsController.insertPortalContact';
import insertPortalUser from '@salesforce/apex/ContactsAccountsController.insertPortalUser';
import retrieveTriggerSettings from '@salesforce/apex/ContactsAccountsController.retrieveTriggerSettings';
import setUserDefaultPwFuture from '@salesforce/apex/ContactsAccountsController.setUserDefaultPwFuture';
import assignPsas from  '@salesforce/apex/ContactsAccountsController.assignPermissionSets';
import retrievePortalProfiles from '@salesforce/apex/ContactsAccountsController.retrievePortalProfiles';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {fireEvent} from "c/pubSub";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';

const   FIRST_NAME_DATAID                               =       'firstName';
const   LAST_NAME_DATAID                                =       'lastName';
const   EMAIL_ADDRESS_DATAID                            =       'emailAddress';
const   USERNAME_DATAID                                 =       'userName';
const   MAX_HELP_BREAKPOINT                             =       935;

export default class CommunityUserCreate extends LightningElement {

    _lookupInputStyle;
    _wiredPortalProfiles;
    _inputStyle;
    _hasRendered;
    _contactCreated;
    _userCreated;
    _debugConsole = true;
    _className = 'CommunityUserCreate';
    _wiredTriggerSettings;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    @api firstName;
    @api lastName;
    @api emailAddress;
    @api userName;
    @api accountId;
    @api showPortalAdminSecuritySettings = false;

    @track triggerSettings;
    @track pwGenTypeValue = 'random';
    @track pwSendOptionSelected = true;
    @track allowButtonToSetPw = true;
    @track showRightSideHelp = false;
    @track isProcessing = false;
    @track portalProfiles;
    @track portalProfileOptions;
    @track portalProfileId;
    @wire(CurrentPageReference) pageRef;

    @api
    get genTypeIsRandom() {
        return this.pwGenTypeValue = 'random';
    }
    @api
    get accountWhereCriteria() {
        let whereCriteria = ' RecordType.DeveloperName = \'Location\'';
        whereCriteria += ' AND ( Type = \'Accel Account\' OR Legal_Name__c = \'Portal Dummy Account\') ';
        return whereCriteria;
    }
    constructor() {
        super();
        this.buildInputOverrideCss();
    }
    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
            const templateWidth = this.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
            this.determineHelpLocation(templateWidth);
            if(this._inputStyle) {
                this.appendLocalInputStyle();
            }
            this.registerWindowEvents();
        }
    }
    @api
    get showPortalProfileOptions() {
        return this.portalProfileOptions && Array.isArray(this.portalProfileOptions) && this.portalProfileOptions.length > 0;
    }
    @wire(retrievePortalProfiles)
    wiredResults(wiredData) {
        this._wiredPortalProfiles = wiredData;
        const { data, error } = this._wiredPortalProfiles;
        if(data) {
            this.shapePortalProfiles(data);
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }
    shapePortalProfiles(profiles) {
        if(profiles && Array.isArray(profiles)) {
            let options = [];
            profiles.forEach( profile => {
                if(profile.Name === 'Individual User Community Standard') {
                    this.portalProfileId = profile.Id;
                }
                options.push( {label: profile.Name, value: profile.Id } );
            });
            this.portalProfileOptions = options;
            console.info(JSON.stringify(this.portalProfileOptions));
        }
    }
    /*
     * @TODO pass down to child.
     */
    @wire(retrieveTriggerSettings,{userId: '$_userId'})
    wiredTriggerSettingsResults(wiredData) {
        this._wiredTriggerSettings = wiredData;
        const { data, error } = this._wiredTriggerSettings;
        if(data) {
            this.triggerSettings = Object.assign({},data);
            console.log(JSON.stringify(this.triggerSettings));
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }
    createCommunityContact() {
        this.isProcessing = true;
        let params = {
            accountId: this.accountId, firstName: this.firstName,
            lastName: this.lastName, emailAddress: this.emailAddress,
            userName: this.userName
        };
        insertPortalContact(params)
            .then(result => {
                let dto = result;
                console.log(JSON.stringify(dto));
                if (dto.isSuccess) {
                    this._contactCreated =  this._accelUtils.getMapValue('portalContact',dto.values);
                    this.createCommunityUser();
                } else {
                    this.isProcessing = false;
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                alert(JSON.stringify(error));
                this.isProcessing = false;
            });
    }
    clearForm() {
        const inputFields = this.template.querySelectorAll('lightning-input');
        if (inputFields) {
            inputFields.forEach(field => {
                field.value = null;
            });
        }

    }
    createCommunityUser() {
        let params = {
           contact: this._contactCreated, userName: this.userName
        };
        insertPortalUser(params)
            .then(result => {
                let dto = result;
                console.log(JSON.stringify(dto));
                if (dto.isSuccess) {
                    this._userCreated =  this._accelUtils.getMapValue('portalUser',dto.values);
                    this.assignUserPermissionSets(this._userCreated.Id);
                    let msg = 'Your portal user '+this._userCreated.Username + ' was created and activated. ';
                    if(this.triggerSettings) {
                        if(this.triggerSettings.Portal_User_SetPassword_Active__c) {
                            msg += ' The default password will be set shortly and an user delivered to the user. ';
                        }
                    }
                    this.showToast('User Created!', msg, 'success');
                    this.dispatchEvent(new CustomEvent('portalusercreated', {bubbles: false, detail: {value: this._userCreated}}));
                    this.clearForm();
                    this.isProcessing = false;
                    fireEvent(this.pageRef,'portalUserCreated',this._contactCreated);
                } else {
                    this.isProcessing = false;
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                alert(JSON.stringify(error));
            });
    }
    assignUserPermissionSets( userId ) {
        let params = { userId: userId };
        assignPsas(params)
            .then(result => {
                let dto = result;
                console.log(JSON.stringify(dto));
                if (dto.isSuccess) {
                    let psas  =  this._accelUtils.getMapValue('psas',dto.values);
                    console.log(JSON.stringify(psas));
                } else {
                    this.isProcessing = false;
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                alert(JSON.stringify(error));
            });
    }
    handlePwSendOptionSelected(event) {
        this.pwSendOptionSelected = event.detail.value;
    }
    handlePwGenTypeSelected(event) {
        this.pwGenTypeValue = event.detail.value;
    }
    handlePortalProfileChange(event) {
        this.portalProfileId = event.target.value;
        console.error(this.portalProfileId);
    }
    handleInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        switch (field) {
            case  FIRST_NAME_DATAID:
                this.firstName = value;
                break;
            case  LAST_NAME_DATAID:
                this.lastName = value;
                break;
            case  EMAIL_ADDRESS_DATAID:
                this.emailAddress = value;
                this.userName = value;
                break;
            case  USERNAME_DATAID:
                this.userName = value;
                break;
            default:
                console.log('huh? unless we added a new input this should not be hit.');
        }
    }
    handleAccountSelected(event) {
        let record = event.detail.value;
        if(record && record.id) {
            this.accountId = record.id;
            // this.fireRefreshOnAccountVisibilityChange = true;
            // fireEvent(this.pageRef,'accountSelected',record);
        }
    }

    handleButtonClick(event) {
        event.preventDefault();
        const allInputs = this.template.querySelectorAll("lightning-input");
        let allValid = true;

        if(!this.accountId) {
            allValid = false;
        }
        allInputs.forEach(function(ele){
            if(!ele.checkValidity()) {
                ele.reportValidity();
                allValid = false;
            }
        });
        if(allValid) {
            this.createCommunityContact();
        } else {
            if(!this.accountId) {
                this.showToast('Error','Please select a valid account','error');
            }
            console.error('something not valid');
        }
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
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }
    /**
     * Register a window event to constantly determine the amount of real-estate (not including left nav) so we
     * can determine what device we are on. This is a bit more accurate and up to date then media queries.
     */
    registerWindowEvents() {
        let self = this;
        window.addEventListener('resize', function() {
            const templateWidth = self.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
            self.determineHelpLocation(templateWidth);
        });
    }
    /**
     * Based on the breakpoint set of the bounding div width, Shows extra help on right on large devices.
     *
     * @param templateWidth
     */
    determineHelpLocation(templateWidth) {
        if (templateWidth > MAX_HELP_BREAKPOINT) {
            this.showRightSideHelp= true;
        } else {
            this.showRightSideHelp = false;
        }
    }

    appendLocalInputStyle() {
         let target = this.template.querySelector('.create-fake-input-overrides-class');
         target.appendChild(this._inputStyle);
    }
    buildInputOverrideCss() {
        let css = '@media only screen and (min-width: 768px) {';
        css += '.c3llc-autocomplete-container .slds-input { background-color: rgb(255, 255, 255);width: 100%;display: inline-block;height: 40px; ';
        css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);border-width: 1px;';
        css += 'border-style: solid;border-color: rgb(219, 219, 219);border-image: initial;border-radius: 0.25rem;';
        css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;';
        css += 'padding-left:35px';
        css+= '}';
        css += '.c3llc-autocomplete-container .slds-form-element__label {color:black;font-weight:bold} ';
        css += '}';
        this._lookupInputStyle = document.createElement('style');
        this._lookupInputStyle.innerText = css;

        let cssLocal = '@media only screen and (min-width: 768px) {';
        cssLocal += '.c3llc-input-container .slds-input { background-color: white;width: 100%;display: inline-block;height: 40px; ';
        cssLocal += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);border-width: 1px;';
        cssLocal += 'border-style: solid;border-color: rgb(219, 219, 219);border-image: initial;border-radius: 0.25rem;';
        cssLocal += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;';
        cssLocal += 'padding-left:15px';
        cssLocal += '}';
        cssLocal += '.c3llc-input-container .slds-form-element__label {color:black;font-weight:bold} ';
        cssLocal += '}';

        this._inputStyle = document.createElement('style');
        this._inputStyle.innerText = cssLocal;
    }

    //======================= deprecated code.

    // createUserPw(userId) {
    //     let params = {userId: userId, pwType: 'predefined', emailAddresses: null};
    //     setUserDefaultPwFuture(params)
    //         .then(result => {
    //             let dto = result;
    //             console.log(JSON.stringify(dto));
    //             if (dto.isSuccess) {
    //                 this.showToast('', 'Your portal user: '+this._userCreated.Username
    //                     +' was successfully created and activated. The default password will be set shortly.', 'success');
    //                 this.isProcessing = false;
    //                 fireEvent(this.pageRef,'portalUserCreated',this._contactCreated);
    //             } else {
    //                 this.isProcessing = false;
    //                 this.showToast('', dto.message, 'error');
    //             }
    //         })
    //         .catch(error => {
    //             alert(JSON.stringify(error));
    //             this.isProcessing = false;
    //         });
    // }
}