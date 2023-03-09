import LightningAlert from "lightning/alert";
import LightningConfirm from "lightning/confirm";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";

const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

export const uiHelper = {


    async showAlert(message, theme, label) {
        await LightningAlert.open({
            message: message,
            theme: theme,
            label: label
        }).then(() => {
            console.log("###Alert Closed");
        });
    },
    async showConfirm(message, theme, label) {
        const result = LightningConfirm.open({
            message: message,
            theme: theme,
            label: label,
        });
        return result;
    },
    showToast(ref, title, msg, variant, mode) {
        const evt = new ShowToastEvent({title: title, message: msg, variant: variant, mode: mode});
        ref.dispatchEvent(evt);
    },
    dismissFslSObjectView(ref, recordId) {
        ref[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                "url": `com.salesforce.fieldservice://v1/sObject/${recordId}`
            }
        });
    },
    navigateToFslRecordView(ref,recordId) {
        ref[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": `com.salesforce.fieldservice://v1/sObject/${recordId}/details`
            }
        });
    },
    navigateToSfMobileViewDeepLink(ref,sObjectName) {
        ref[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": `salesforce1://sObject/${sObjectName}/home`
            }
        });
    },
    navigateToPhoneApp(ref,phoneNumber) {
        ref[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": `tel:${phoneNumber}`
            }
        });
    },
    navigateToMessagingApp(ref,phoneNumber) {
        ref[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": `sms:${phoneNumber}`
            }
        });
    },
    navigateInternalListView(objectApiName, filterName) {
        try {
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: objectApiName,
                    actionName: 'list'
                },
                state: {
                    filterName: filterName
                }
            });
        } catch (e) {
            console.error(e);
        }
    },
    /**
     *
     * @param mKey
     * @param values
     * @returns {*}
     */
    getMapValue(mKey, values) {
        let retValue;
        for (let key in values) {
            if (key === mKey) {
                retValue = values[key];
                break;
            }
        }
        return retValue;
    },
    /**
     *
     * @param objectApiName  The api name of the sObject.
     * @param objectInfos    The array of object infos.
     * @returns {unknown}
     */
    findObjectInfo(objectApiName,objectInfos) {
        if(objectInfos && objectInfos.results) {
            return objectInfos.results.find(x => x.result.apiName === objectApiName);
        }
    },
    findRecordTypeId(recordTypeInfos,recordTypeDevName) {
        if(recordTypeInfos && recordTypeDevName) {
            return  Object.keys(recordTypeInfos).find(rti => recordTypeInfos[rti].name === recordTypeDevName);
        }
    },
    /**
     * @param ref      References to lwc client.. ie 'this'
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(ref,logType, msg, obj) {
        if (ref._logger && ref.debugConsole) {
            switch (logType) {
                case DEBUG:
                    ref._logger.logDebug(msg,obj);
                    break;
                case ERROR:
                    ref._logger.logError(msg,obj);
                    break;
                case INFO:
                    ref._logger.logInfo(msg,obj);
                    break;
                default:
                    ref._logger.log(msg, obj);
            }
        }
    }
}