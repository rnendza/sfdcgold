import LightningAlert from "lightning/alert";
import LightningConfirm from 'lightning/confirm';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";
import {animationHelper} from "c/portalAdminAnimationHelper";

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
    navigateRelatedListView(ref,sObjectApiName,relationshipApiName,recordId) {
        ref[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: recordId,
                objectApiName: sObjectApiName,
                relationshipApiName: relationshipApiName,
                actionName: 'view'
            },
        });
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
    },
    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     */
    buildConsoleCardOverrideCss(ref,selector) {
        let css = '';
        css += '.accel-console-card .slds-card__header {';
        css += '    background-color: rgb(243,243,243); border-top-right-radius:5px;border-top-left-radius:5px;';
        css += '    border-bottom: 1px solid silver;padding-bottom:5px;';
        css += '} ';
        css += '.accel-console-card .slds-card__footer {';
        css += '    background-color: rgb(243,243,243); border-bottom-right-radius:5px;border-bottom-left-radius:5px;';
        css += '   ';
        css += '} ';
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector(selector);
        if(target) {
            if(!target.contains(style)) {
                target.appendChild(style);
            }
        }
    },
    reduceErrors(errors) {
        console.log('---> reduce errors:',errors);
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        return (
            errors
                // Remove null/undefined items
                .filter((error) => !!error)
                // Extract an error message
                .map((error) => {
                    // UI API read errors
                    if (Array.isArray(error.body)) {
                        return error.body.map((e) => e.message);
                    }
                    // UI API DML, Apex and network errors
                    if (error.body) {
                        let bodyMessage = [];
                        // top-level error. there can be only one
                        if (error.body.message) {
                            bodyMessage.push(error.body.message);
                        }
                        // page-level errors (validation rules, etc)
                        if (error.body.output && error.body.output.errors) {
                            error.body.output.errors.forEach(error => {
                                bodyMessage.push(error.message);
                            });
                        }
                        if (error.body.fieldErrors) {
                            // field specific errors--we'll say what the field is
                            Object.keys(error.body.fieldErrors).forEach(fieldName => {
                                // each field could have multiple errors
                                error.body.fieldErrors[fieldName].forEach(fieldError => {
                                    bodyMessage.push("Field Error on " + fieldName + " : " + fieldError.message);
                                });
                            });
                        }
                        if (bodyMessage.length > 0) {
                            return bodyMessage.join(" ");
                        }
                    }
                    // JS errors
                    if (typeof error.message === 'string') {
                        return error.message;
                    }
                    // Unknown error shape so try HTTP status text
                    return error.statusText;
                })
                // Flatten
                .reduce((prev, curr) => prev.concat(curr), [])
                // Remove empty strings
                .filter((message) => !!message)
                .join('\n')
        );
    }
}