import {LightningElement, track, api} from 'lwc';

export default class HpdTransferAssistance extends LightningElement {

    @api allFormFieldsValid;
    @api sourceAccountSelected;
    @api targetAccountSelected;
    @api userWasSelected;
    @api userSelected;
    @api commitTrans;

    @track showAdvancedOptions = false;

    handleHideAdvancedOptions(event) {
        this.showAdvancedOptions = false;
        this.dispatchEvent( new CustomEvent('toggleadvancedform', {detail: { showIt: false }}) );
    }
    handleShowAdvancedOptions(event) {
        this.showAdvancedOptions = true;
        this.dispatchEvent( new CustomEvent('toggleadvancedform', {detail: { showIt: true }}) );
    }
    handlePreviewHelpFile(event) {
        this.dispatchEvent( new CustomEvent('previewhelpfile', {detail: { showIt: true }}) );
    }
}