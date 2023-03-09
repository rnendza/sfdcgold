import {LightningElement, api, wire} from 'lwc';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveExpiredLicenseInfo  from '@salesforce/apex/AcPostLoginProcessingController.retrieveExpiredLicenseInfo';

const MAP_KEY_LICENSE_SUMMARY           =   'LICENSE_SUMMARY';
/**
 *  Intended to happen after the user logs in (probably embedded in the bottom nav)
 */
export default class AcPostLoginProcessor extends LightningElement {

    @api wiredExpiredLicenseDto;
    _licenseSummary;
    _debugConsole                   = false; //@TODO passed in property / custom meta.
    accelUtils                      = new AccelUtilsSvc(this._debugConsole);
    /**
     * Retrieves expiring license data for all accounts visible to the community user.
     * Will fire a custom event to a containing aura component to toast if there are any expiring licenses.
     *
     * @param wiredExpiredLicenseInfo Passed by the Platform via wire api.
     */
    @wire(retrieveExpiredLicenseInfo)
    wiredRetrieveExpiredLicenseInfo( wiredExpiredLicenseInfo ) {
        this.wiredExpiredLicenseDto = wiredExpiredLicenseInfo;        // track the provisioned value
        const { data, error } = wiredExpiredLicenseInfo;              // destructure it for convenience
        if(data) {
            if(data.isSuccess) {
                this._licenseSummary = this.accelUtils.getMapValue(MAP_KEY_LICENSE_SUMMARY,data.values);
                this.accelUtils.logDebug('license summary debug debug', this._licenseSummary);
                if(this._licenseSummary.anyExpiredOrExpiring === true) {
                    this.showNotification();
                }
            }
        } else if (error) {
            this.error = this.accelUtils.reduceErrors(error);
            this.accelUtils.logError('Errors calling retrieveExpiredLicenseInfo',this.error);
        }
    }
    /**
     *  If we are not on the location-detail page.. show toast if we have any expiring or expired licenses.
     *  Added disable of showing toast on custom settings.. 
     */
    showNotification() {
        /**
         * @TODO the below seems dirty.. SFDC doesn't usually like direct access to the window object.
         * Plus we assume the community page this called. location-detail. Revise if time allows.
         */
        try {
            if(window.location.href) {
                if(window.location.href.includes('location-detail')) {
                    //--- exit because we are already on the location detail page.
                    return;
                }
                if(window.location.href.includes('my-settings')) {
                    return;
                }
            }
        } catch (e) {
            this.accelUtils.logError('error getting current location', e);
        }
        let msg = '';
        let bExpired = this._licenseSummary.iNumExpiredLicenses > 0;
        let bExpiring = this._licenseSummary.iNumExpiringLicenses > 0;
        if(this._licenseSummary && bExpired) {
            msg += this._licenseSummary.iNumExpiredLicenses + ' of your licenses have expired';
            if(!bExpiring) {
                msg += '!'
            }
        }
        if(this._licenseSummary && bExpiring) {
            if(bExpired) {
                msg += ' and '+ this._licenseSummary.iNumExpiringLicenses + ' license';
                if(this._licenseSummary.iNumExpiringLicenses > 1) {
                    msg += 's are about to expire!';
                } else {
                    msg += ' is about to expire!';
                }
            }
        }
        msg += ' Click ';
        let url =  '/location-detail';
        let msgTemplate = '{0} {1}  for more information!';
        let payload = { msg:msg, linkUrl:url, linkLabel:'VIEW LOCATION DETAILS',title:'',
                        msgTemplate : msgTemplate, type:'warning',mode:'dismissible',duration:7000};

        const showExpiredNotification = new CustomEvent('showexpirednotification', {detail: { payload },});

        this.dispatchEvent(showExpiredNotification);
    }
}