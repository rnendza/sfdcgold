import {LightningElement, track, wire} from 'lwc';
import AccelUtilsSvc from "c/accelUtilsSvc";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {NavigationMixin} from "lightning/navigation";
import Id from "@salesforce/user/Id";
import {getConstants} from "c/clConstantUtil";
import lblCardTitle from '@salesforce/label/c.CL_Process_Home_Card_Title'
import lblFill from '@salesforce/label/c.CL_Process_Home_App_Fill'
import lblProcess from '@salesforce/label/c.CL_Process_Home_App_Process'
import {reduceErrors} from "c/ldsUtils";
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import mainTemplate from './clRouteProcessingHome.html';
import stencil from './clRouteProcessingHomeStencil.html';

const PAGE_NAME_FILL = 'processing-fill';
const PAGE_NAME_PROCESS ='processing-process';
const PAGE_NAME_PROCESS_BETA = 'process-routes-group';
const GLOBAL_CONSTANTS = getConstants();
const MDT_APP_DEV_NAME = 'Application';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';

export default class ClRouteProcessingHome extends NavigationMixin(LightningElement) {

    labels = {lblCardTitle,lblFill,lblProcess};
    _userId = Id;
    _appMdtDevName = MDT_APP_DEV_NAME;
    _wiredAppMdt;
    _debugConsole = false;
    _allDataLoaded;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _pageNameProcess = PAGE_NAME_PROCESS;

    @track appMdt;
    @track moduleSelected;
    @track processorModules = [
        {icon: 'standard:webcart', id: 'fill', value: 'fill', label: this.labels.lblFill, disabled: '', pickerSize: 'slds-visual-picker slds-visual-picker_medium'},
        {icon: 'standard:proposition', id: 'process', value: 'process', label: this.labels.lblProcess, disabled: '', pickerSize: 'slds-visual-picker slds-visual-picker_medium'},
    ];

    constructor() {
        super();
        console.info('%c----> /lwc/clRouteProcessingHome',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }
    render() {
        return this._allDataLoaded ? mainTemplate : stencil;
    }

    handleModuleClick(evt){
        const idClicked = evt.currentTarget.dataset.id;
        this.moduleSelected = this.processorModules.find(x => x.id === idClicked);
        switch (idClicked) {
            case 'fill' :
                this.navigate(PAGE_NAME_FILL);
                break;
            case 'process' :
                if(this._pageNameProcess === PAGE_NAME_PROCESS_BETA) {
                    //let msg = 'Redirecting to beta page per admin setting..';
                    //this.showToast('DEVELOPER NOTE', msg, 'info');
                }
                this.navigate(this._pageNameProcess);
                break;
            default:
                this.showToast('','WIP','info');
        }
    }

    handleModuleChange(evt){

    }

    /**
     * @param pageName
     */
    navigate(pageName) {
        try {
            console.log('attempting to nav to pageName:'+pageName);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                },
                state: {
                }
            });
        } catch (e) {
            console.error(e);
        }
    }

    /**
     *  Get the app level custom meta-data.
     *
     *  @param wiredData
     *  @see Cash_Logistics_Setting__mdt (Application type)
     */
    @wire(retrieveMdt, { mdtDevName: '$_appMdtDevName' })
    wiredMdt(wiredData) {
        this._wiredAppMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error('---> error getting mdt',this.error);
        } else if (data) {
            this._allDataLoaded = true;
            this.appMdt = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
            if(this.appMdt){
                console.info('---> app mdt=',JSON.parse(JSON.stringify(this.appMdt)))
                if(this.appMdt.Use_Processor_Grouping__c) {
                    this._pageNameProcess = PAGE_NAME_PROCESS_BETA;
                }
            }
        }
    }
    /**
     *
     * @param title
     * @param msg
     * @param variant
     */
    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

}