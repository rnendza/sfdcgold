import {LightningElement, track, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import accelLwcStyles from '@salesforce/resourceUrl/lwc_styles';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import { refreshApex } from '@salesforce/apex';

import retrieveCommunityUserSettings   from '@salesforce/apex/AcContactProfileSettingsController.retrieveCommunityUserSettings';
import updateCommunityUserSettings     from '@salesforce/apex/AcContactProfileSettingsController.updateCommunityUserSettings';

const   COMMUNITY_USER_PROFILE_SETTINGS         = 'COMMUNITY_USER_PROFILE_SETTINGS';
const   COMMUNITY_USER_DISPLAY_SETTINGS         = 'COMMUNITY_USER_DISPLAY_SETTINGS';
export default class AcContactProfileSettings extends LightningElement {

    _debugConsole = false;
    _className = 'AcContactProfileSettings';
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _communityUserSetting;

    @api wiredCommunityUserSettingsDto;
    @api profileSettings = [];
    @api isSettingsRetrieved = false;
    @api isRunningUpdate = false;
    @api fieldSetIconSize = 'small';
    @api isMobile = false;
    @track recordId;

    connectedCallback() {
        this._accelUtils.logDebug(this._className+ ' --- connectedCallback ---');
    }

    renderedCallback() {
        this._accelUtils.logDebug(this._className+ ' --- renderedCallback ---');
        if (this.hasRendered) return;
        this._accelUtils.logDebug(this._className+ ' --- renderedCallback 1st ---');
        this.registerWindowEvents();
        let templateWidth = this.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
        this.determineFieldSetIconSize(templateWidth);
        loadStyle(this, accelLwcStyles + '/lwc_icon_styles.css').then(() => {
            this._accelUtils.logDebug(this._className + 'lwc_icon_styles loaded');
            this.buildOverrideCss();
        }).catch(error => {
            console.log(error);
        });
        this.hasRendered = true;
    }
    /**
     * Retrieves Community User Settings. 'Spreads' the list. ie clones as it's immutable in case we want to sort later.
     * @param wiredUserData Passed by the Platform via wire api.
     */
    @wire(retrieveCommunityUserSettings)
    wiredContactProfileSettings(wiredCommunityUserSettingsDto) {
        this.wiredCommunityUserSettingsDto = wiredCommunityUserSettingsDto;
        const { data, error } = wiredCommunityUserSettingsDto;
        if(data) {
            const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item);
            if(data.isSuccess) {
                let tmpSettings = this._accelUtils.getMapValue(COMMUNITY_USER_PROFILE_SETTINGS, data.values);
                this._communityUserSetting = Object.assign({}, tmpSettings);
                this.profileSettings = clone(this._accelUtils.getMapValue(COMMUNITY_USER_DISPLAY_SETTINGS, data.values));
                this._accelUtils.logDebug(this._className + ' community user settings=',JSON.stringify(this._communityUserSetting));
                this._accelUtils.logDebug(this._className + ' community user display settings=',JSON.stringify(this.profileSettings));
            } else {
                this._accelUtils.logError(this._className + ' wiredCommunityUserSettings.',data.technicalMsg);
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: data.message,
                        variant: 'error',
                    }),
                );

            }
            this.isSettingsRetrieved = true;
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
            this.isSettingsRetrieved = true;
        }
    }
    /**
     * Builds a Community_User_Setting__c sObj. Populates and fires SS update.
     * @param event
     */
    handleCheckboxChange(event) {
        this.isRunningUpdate = true;
        event.preventDefault();
        const recId = event.target.dataset.recordid;
        let fieldApiName = event.target.name;
        let fieldLabel = event.target.dataset.label;
        let fieldValue = event.target.checked;
        let commUserSetting = {
            'sobjectType': 'Community_User_Setting__c',
            Id: recId,
            [fieldApiName]: fieldValue
        };
        this.updateCommunityUserSetting(commUserSetting,fieldLabel,fieldValue);
    }
    /**
     * Fires the SS update / Toasts a success (hopefully).
     *
     * @param communityUserSetting The Community_User_Setting__c sObject clicked.
     * @param settingLabel  The field label of the value clicked.
     * @param fieldValue    The field value of the row clicked.
     */
    updateCommunityUserSetting(communityUserSetting, settingLabel ,fieldValue) {
        this._accelUtils.logInfo(this._className + ' Attempting to update..',communityUserSetting);
        settingLabel = settingLabel.startsWith('Display') ? settingLabel.replace('Display','') : settingLabel;
        updateCommunityUserSettings({communityUserSetting: communityUserSetting})
            .then(result => {
                let msg = '';
                if(settingLabel !== ' Location Address') {
                    msg = fieldValue === true ? ' will be displayed.' : ' will be hidden.';
                } else {
                    settingLabel = '';
                    msg = fieldValue === true ? 'Location Address will be displayed.' : 'DBA Name will be displayed.';
                }
                this._accelUtils.logInfo('manually calling refreshApex with wiredCommunityUserSettingsDto');
                refreshApex( this.wiredCommunityUserSettingsDto );
                this.isRunningUpdate = false;
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: settingLabel + msg,
                        variant: 'success',
                    }),
                );

            })
            .catch(error => {
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
    /**
     *
     * @param event
     * @TODO handle direct link to this page (ie no other  accel community page in history)
     * @TODO does this work on that mobile container thing?
     */
    handleBackClick(event) {
        let clickedButtonLabel = event.target.label;
        window.history.back();
    }
    /**
     * Builds a Community_User_Setting__c sObj. Populates and fires SS update.
     * @param event
     */
    handleCheckboxContainerClick(event) {
        event.preventDefault();
        const recId = event.target.dataset.recordid;
        let fieldApiName = event.target.name;
        let commUserSetting = {
            'sobjectType': 'Community_User_Setting__c',
            Id: recId,
            [fieldApiName]: event.target.checked
        };
        this.updateCommunityUserSetting(commUserSetting);
    }
    registerWindowEvents() {
        let self = this;
        window.addEventListener('resize', function () {
            let templateWidth = self.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
            self.isMobile = !(templateWidth && templateWidth >= self._accelUtils.DESKTOP_CHART_WIDTH);
            self.determineFieldSetIconSize(templateWidth);
        });
    }
    determineFieldSetIconSize(templateWidth) {
        if(templateWidth > this._accelUtils.MOBILE_FORM_WIDTH) {
            this.fieldSetIconSize = 'small';
        } else {
            this.fieldSetIconSize = 'x-small';
        }
    }
    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     * @media only screen and (max-width: {whatever mobile is set t}px)
     <style>
     .cAccel_CommunityServiceMobileThemeLayout .accel-content
     */
    buildOverrideCss() {
        const mobile = this._accelUtils.MOBILE_FORM_WIDTH;
        let css = '@media only screen and (max-width: '+mobile+'px) {';
        css+='.cAccel_CommunityServiceMobileThemeLayout .accel-content {';
        css+='padding:2px 8px 2px 4px!important} ';
        css+='.slds-col_padded, .slds-col--padded{padding-left:2px;padding-right:2px;padding-top:5px}';
        css+='.siteforceContentArea .comm-layout-column:not(:empty) {padding-top: 10px }}';

        const style = document.createElement('style');
        style.innerText = css;
        let target = this.template.querySelector('.fake-theme-overrides-class');
        target.appendChild(style);
    }
}