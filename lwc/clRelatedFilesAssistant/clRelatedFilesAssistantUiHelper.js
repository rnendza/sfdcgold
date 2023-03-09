import {ShowToastEvent} from "lightning/platformShowToastEvent";
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
    }
}