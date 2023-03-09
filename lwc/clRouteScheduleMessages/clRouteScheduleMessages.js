import {LightningElement,api} from 'lwc';

export default class ClRouteScheduleMessages extends LightningElement {

    @api recordId;
    @api messageDisplayType;
    @api scopedMessageDuration;
    @api scopedMessageDismissible;

    handleJobComplete(evt) {
        console.log(JSON.stringify(evt.detail));
    }
}