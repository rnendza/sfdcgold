import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {animationHelper} from "./clSecurityAuditAssistantAnimation";
import {NavigationMixin} from "lightning/navigation";

export const uiHelper = {

    showToast(ref,title, msg, variant) {
        const evt = new ShowToastEvent({title: title, message: msg, variant: variant});
        ref.dispatchEvent(evt);
    },
    navigateToPageNoState(ref,pageName) {
        ref[NavigationMixin.Navigate]({type: 'comm__namedPage', attributes: {pageName: pageName}});
    },
    navigateToStandardWebPage(ref, url) {
        ref[NavigationMixin.Navigate]({type: 'standard__webPage', attributes: {url: url}}, false );
    },
    navigateToNamedPage(ref,pageName, selectedRecordId) {
        ref[NavigationMixin.Navigate]({type: 'standard__namedPage', attributes: {pageName: pageName},
            state : {
                selectedRecordId:selectedRecordId
            }
        })
    },
    processAccordion(ref,sectionTitleId) {
        if(sectionTitleId) {
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
}