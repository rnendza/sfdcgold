import {LightningElement,track,api} from 'lwc';

export default class AccelUtilsModulePicker extends LightningElement {

    _workOrderExist = false;
    _showWorkOrderPicker = false;
    _todayTotalWorkOrders = 0;


    @track moduleSelected;
    @track isProcessing = true;


    @track utilsModules = [
        {icon: 'standard:asset_audit', id: 'tab_utils_audit_trails', value: 'tab_utils_audit_trails', label: 'Audit Trails', disabled: '', pickerSize: 'slds-visual-picker slds-visual-picker_small'},
        {icon: 'standard:user', id: 'tab_utils_auth_sessions', value: 'tab_utils_auth_sessions', label: 'Users', disabled: '', pickerSize: 'slds-visual-picker slds-visual-picker_small'},
        {icon: 'custom:custom86', id: 'tab_utils_pa_gallery', value: 'tab_utils_pa_gallery', label: 'PA Gallery', disabled: '', pickerSize: 'slds-visual-picker slds-visual-picker_small'},
        {icon: 'standard:location', id: 'tab_utils_gpsstatus', value: 'tab_utils_gpsstatus', label: 'GPS Status', disabled: '', pickerSize: 'slds-visual-picker slds-visual-picker_small'},
        {icon: 'standard:work_capacity_usage', id: 'tab_utils_jobs', value: 'tab_utils_jobs', label: 'Scheduled Jobs', disabled: '', pickerSize: 'slds-visual-picker slds-visual-picker_small'},
    ];

    connectedCallback() {
        console.log('-0--')
    }


    renderedCallback() {
        this.isProcessing = false;
    }

    handleModuleClick(e){
        const idClicked = e.currentTarget.dataset.id;
        this.moduleSelected = this.utilsModules.find(x => x.id === idClicked);
        console.log('--> module click. moduleSelected='+JSON.stringify(this.moduleSelected));
        this.dispatchModuleSelectedEvent(this.moduleSelected);
    }

    dispatchModuleSelectedEvent(moduleSelected){
        if(moduleSelected) {
            let payload = {moduleSelected: moduleSelected};
            const evt = new CustomEvent('moduleselected', {detail: {payload}});
            this.dispatchEvent(evt);
        }
    }
    addWorkOrderPicker() {
        const picker = {
            icon: 'standard:maintenance_asset',
            id: 'myworkorders',
            value: 'myworkorders',
            label: 'Todays work ('+this.todayTotalWorkOrders+')',
            disabled: '',
            pickerSize: 'slds-visual-picker slds-visual-picker_small'
        }
        this.utilsModules.push(picker);
        //  Prepend to beginning of array.
        //this.serviceModules = [picker,...this.serviceModules];
        //this.serviceModules = this.serviceModules.map(el )
        //this.serviceModules.push(picker);
    }
}