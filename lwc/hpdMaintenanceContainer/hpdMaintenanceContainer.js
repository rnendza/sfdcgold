import {LightningElement, api, wire,track} from 'lwc';
import {fireEvent} from 'c/pubSub';
import { CurrentPageReference } from 'lightning/navigation';
import doesUserHavePermission from '@salesforce/apex/UserSvc.doesUserHavePermission';
   
const LARGE_SCREEN_WIDTH = 1476;

export default class HpdMaintenanceContainer extends LightningElement {

    @api activeTabValue = 'MonthlyXfer';
    @api hpdMonthlyImportCustomPermApiName = 'HPD_Maintenance_Allow_Monthly_Import';

    @track tabContainerStyle = 'width:100%;margin: auto;';
    @track isProcessing;
    @track hasCustomPermMonthlyImport = false;

    @wire(CurrentPageReference) pageRef;
    _hasRendered = false;

    constructor() {
        super();
        this.isProcessing = true;
    }
    renderedCallback() {
        if(!this._hasRendered) {
            this.checkContainerWidth();
            this.registerWindowEvents();
        }
    }
    @wire(doesUserHavePermission, {customPermissionApiName: '$hpdMonthlyImportCustomPermApiName'})
    wiredCustomPermResults(wiredData) {
        const { data, error } = wiredData;
        if(data !== undefined && data !== null) {
           this.hasCustomPermMonthlyImport = data;
        } else if (error) {
            console.error(JSON.stringify(error));
        }
    }
    handleTabSelect(event) {
        let tab = event.target.label;
    }
    /**
     * Pub an event on this outer container of a click so that children the user the recordAutoComplete component
     * can decide whether or not to close the slds menu.
     * @param event
     */
    handleOuterContainerClick(event) {
        fireEvent(this.pageRef, 'eventOuterContainerClicked', 'outercontainerclick');
    }
    handleKillContainerSpinner(event) {
        this.isProcessing = false;
    }
    registerWindowEvents() {
        let self = this;
        window.addEventListener('resize', function () {
           self.checkContainerWidth();
        });
    }
    checkContainerWidth() {
        let templateWidth = this.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
        if (templateWidth && templateWidth > LARGE_SCREEN_WIDTH) {
            this.tabContainerStyle = 'width:80%;margin: auto;';
        } else {
            this.tabContainerStyle = 'width:100%;margin: auto;';
        }
    }
}