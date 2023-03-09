import {LightningElement, api, wire, track} from 'lwc';
import retrieveCompletedAccountData from '@salesforce/apex/BatchUiController.retrieveCompletedAccountData';

export default class HpdMonthlyTransferCompletedData extends LightningElement {

    @api completedAccountId;

    @track wiredCompletedAccountDto;
    @track completedAccountResult;
    @track showCompletedData = false;

    constructor() {
        super();
    }

    @wire(retrieveCompletedAccountData, {accountId: '$completedAccountId'})
    wiredCompletedAccountResults(wiredData) {
        this.wiredCompletedAccountDto= wiredData;
        const { data, error } = this.wiredCompletedAccountDto;
        if(data) {
            this.completedAccountResult = data;
            this.showCompletedData = true;
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }
}