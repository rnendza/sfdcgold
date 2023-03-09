import {LightningElement,track,wire} from 'lwc';
import {getRecord} from 'lightning/uiRecordApi';
import USER_ID from '@salesforce/user/Id';
import FIRST_NAME_FIELD from '@salesforce/schema/User.FirstName';

export default class AccelAdminWelcome extends LightningElement {

    @track currentModule;
    @track displayModuleOptions;

    @track userFirstName;

    @wire(getRecord, { recordId: USER_ID, fields: [FIRST_NAME_FIELD]})
        wireduser({error, data}) {
        if (error) {
            this.error = error;
        } else if (data) {
            this.userFirstName = data.fields.FirstName.value;
        }
    }

    handleModuleOptionSelected(event) {
        this.currentModule = event.detail.payload.moduleSelected;
        this.displayModuleOptions = false;
        console.log('--> welcome recieved module option selected='+JSON.stringify(this.currentModule));
        let payload = {moduleSelected: this.currentModule};
        const evt = new CustomEvent('utilsmoduleselected', {detail: {payload}});
        this.dispatchEvent(evt);
    }

    get helpText() {
        return 'Hello '+this.userFirstName+'. As a System Administrator, you can use these utilities to maintain and query Salesforce data.';
    }


}