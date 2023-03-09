import {ShowToastEvent} from "lightning/platformShowToastEvent";

export const uiHelper = {

    showToast(ref,title, msg, variant) {
        const evt = new ShowToastEvent({title: title, message: msg, variant: variant});
        ref.dispatchEvent(evt);
    }
}