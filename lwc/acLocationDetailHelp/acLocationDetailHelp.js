import {LightningElement, api,track} from 'lwc';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import locLicenseWarning from '@salesforce/label/c.Community_Location_License_Warning';
import locLicenseExpiredMessage from '@salesforce/label/c.Community_License_Expired_Message';
import locLicenseExpiringMessage from '@salesforce/label/c.Community_License_Expiring_Message';

/**
 *  https://accel-entertainment.monday.com/boards/286658657/pulses/311323513
 *
 *  This class will merely show a legend of error / warning icons and user specific guidance if they have any
 *  visible accounts that have expiring or expired licenses.
 *
 */
export default class AcLocationDetailHelp extends LightningElement {

    _locationLicenseSummary;
    _debugConsole                       = false; //@TODO passed in property / custom meta.
    _accelUtils                         = new AccelUtilsSvc(this._debugConsole);
    @track showExpiredLicenseWarning    = false;
    @track showExpiringLicenseWarning   = false;
    @track showAnything                 = false;
    @track helpBorderCssClass           = 'accel-square-box slds-theme--shade ';
    @track helpInfoIconCssClass         = 'accel-error-icon';

    // Expose the labels to use in the template.
    label = {
        locLicenseWarning,
        locLicenseExpiredMessage,
        locLicenseExpiringMessage
    };
    /**
     * Accessor for private version of passed in locationLicenseSummary Attribute.
     * @returns {*}
     */
    @api
    get locationLicenseSummary() {
        return this._locationLicenseSummary;
    }
    /**
     * We must cheat a bit on this setter due to one way data binding and the need to set track-able boolean for the view.
     * as the attribute will not not be populated upon instantiation as it is populated in an async call on the grandfather
     * aura cmp.
     *
     * @param summaryObj    Passed in locationLicenseSummary object from parent aura cmp.
     */
    set locationLicenseSummary(summaryObj) {
        this._locationLicenseSummary = summaryObj;
        if(this._locationLicenseSummary) {
            this._accelUtils.logDebug('_locationLicenseSummary',this._locationLicenseSummary);
            this.showExpiredLicenseWarning  = this._locationLicenseSummary.iNumExpiredLicenses > 0;
            this.showExpiringLicenseWarning = this._locationLicenseSummary.iNumExpiringLicenses > 0;
            this.showAnything = this.showExpiredLicenseWarning || this.showExpiringLicenseWarning;
            if(this.showAnything) {
                this.formatCustomLabels();
                if(this.showExpiredLicenseWarning) {
                    this.helpBorderCssClass += 'accel-square-box__error';
                } else {
                    this.helpBorderCssClass += 'accel-loc-detail-help-warning-border';
                    this.helpInfoIconCssClass = 'accel-warn-icon';
                }
            }
        }
    }
    /**
     * Formats tokens in the custom label to replace number of licenses and whether license
     * needs to be plural or not.
     *
     * @see AccelUtilsSvc.StringHelpers
     */
    formatCustomLabels() {
        if (this._locationLicenseSummary) {
            let iNumExpired = this._locationLicenseSummary.iNumExpiredLicenses;
            let iNumExpiring = this._locationLicenseSummary.iNumExpiringLicenses;

            let expiredLicenseTxt = iNumExpired > 1 ? 'licenses' : 'license';
            let expiringLicenseTxt = iNumExpiring > 1 ? 'licenses' : 'license';

            this.label.locLicenseExpiredMessage = this._accelUtils.StringHelpers
                .format(this.label.locLicenseExpiredMessage, iNumExpired, expiredLicenseTxt);
            this.label.locLicenseExpiringMessage = this._accelUtils.StringHelpers
                .format(this.label.locLicenseExpiringMessage, iNumExpiring, expiringLicenseTxt);
        }
    }
}