import {animationHelper} from "./clRouteScheduleSelectionAnimation";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";

export const uiHelper = {

    processAccordion(ref,sectionTitleId) {
        if(sectionTitleId) {
            try {
                let eleSectionContent = ref.template.querySelector("div[data-sectioncontentid=" + sectionTitleId + "]");
                let eleSectionArrow = ref.template.querySelector("div[data-sectionarrowid=" + sectionTitleId + "]");
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
    processAccordionAll(ref, type) {
        let allSectionContent = ref.template.querySelectorAll(".accel-accordion-content");
        let allSectionArrows = ref.template.querySelectorAll(".section-arrow");
        let arrAllSectionContent = Array.from(allSectionContent);
        let arrAllSectionArrows = Array.from(allSectionArrows);
        if (arrAllSectionContent && Array.isArray(arrAllSectionContent)) {
            arrAllSectionContent.forEach((sectionContent, index) => {
                let sectionArrow = arrAllSectionArrows[index];
                if(type == 'collapseall') {
                    if (sectionArrow) {
                        sectionContent.classList.remove('slds-show');
                        sectionContent.classList.add('slds-hide');
                        animationHelper.animateSection(sectionContent, sectionArrow, 'close', 500);
                    }
                } else if ( type == 'expandall') {
                    if (sectionArrow) {
                        sectionContent.classList.remove('slds-hide');
                        sectionContent.classList.add('slds-show');
                        animationHelper.animateSection(sectionContent, sectionArrow, 'open', 500);
                    }
                }
            });
        }
    },
    /**
     *
     * @param ref   A reference to the component ie this.
     * @param title
     * @param msg
     * @param variant
     */
    showToast(ref,title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        ref.dispatchEvent(evt);
    },
    navigateToPageNoState(ref,pageName) {
        ref[NavigationMixin.Navigate]({type: 'comm__namedPage', attributes: {pageName: pageName}});
    }


}