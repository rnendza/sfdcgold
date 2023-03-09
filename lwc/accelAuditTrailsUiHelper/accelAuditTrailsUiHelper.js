import LightningAlert from "lightning/alert";
import LightningConfirm from "lightning/confirm";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";
import {animationHelper} from "c/accelAuditTrailsAnimationHelper";

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
    navigateToRecordView(ref, sObjectApiName, recordId) {
        console.log('---> navigating to object:' + sObjectApiName + '... with Id=' + recordId);
        ref[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: sObjectApiName,
                recordId: recordId,
                actionName: 'view'
            }
        });
    },
    navigateToWebViewNewWindow(ref,url) {
        ref[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url : url,
            },
        }).then(refUrl => {
            window.open(refUrl);
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
    processAccordion(ref, sectionTitleId) {
        if (sectionTitleId) {
            try {
                let eleSectionContent = ref.template.querySelector("div[data-sectioncontentid=" + sectionTitleId + "]");
                let eleSectionArrow = ref.template.querySelector("div[data-sectionarrowid=" + sectionTitleId + "]");
                // console.log('---> ele content',eleSectionContent);
                if (eleSectionContent) {
                    const sectionOpen = eleSectionContent.getAttribute('class').search('slds-show') != -1;
                    if (sectionOpen) {
                        eleSectionContent.classList.remove('slds-show');
                        eleSectionContent.classList.add('slds-hide');
                        animationHelper.animateSection(eleSectionContent, eleSectionArrow, 'close');
                        ref._chevronTitle = 'Click to expand content';
                    } else {
                        eleSectionContent.classList.remove('slds-hide');
                        eleSectionContent.classList.add('slds-show');
                        animationHelper.animateSection(eleSectionContent, eleSectionArrow, 'open');
                        ref._chevronTitle = 'Click to collapse content';
                    }
                }
            } catch (e) {
                console.error(e);
            }
        }
    }
}