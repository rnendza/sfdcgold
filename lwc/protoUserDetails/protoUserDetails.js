import {LightningElement,api,track} from 'lwc';

export default class ProtoUserDetails extends LightningElement {

    @api cancelLabel;
    @api cancelIconName;
    @api cancelVariant = 'neutral';
    @api visible;
    @api headerIcon;
    @api name;
    @api
    set originalMessage(val) {
        this._originalMessage = val;
        this.userDetails = val;
    }
    get originalMessage() {
        return this._originalMessage;
    }

    @track userDetails;

    _isProcessing;
    _originalMessage;

    handleClick(event){
        let finalEvent = {originalMessage: this.originalMessage, status: event.target.name};
        this.dispatchEvent(new CustomEvent('modalaction', {detail: finalEvent}));
    }

    hideModalBox(evt) {
        let finalEvent = {originalMessage: this.originalMessage, status: evt.target.name};
        this.dispatchEvent(new CustomEvent('modalaction', {detail: finalEvent}));
    }

    get userImageSrc() {
        if(this.userDetails && this.userDetails.imageBase64String) {
            return 'data:image/jpeg;base64,'+this.userDetails.imageBase64String;
        }
    }

    get userName() {
        if(this.userDetails) {
            let name = this.userDetails.firstName ? this.userDetails.firstName : '';
            name+= this.userDetails.lastName ?  ' ' + this.userDetails.lastName : '';
            return name;
        }
    }
}