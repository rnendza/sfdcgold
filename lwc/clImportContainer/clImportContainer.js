import {LightningElement,api,track} from 'lwc';

export default class ClImportContainer extends LightningElement {

    @api recordId;
    @api displayHelpVideoLink;
    @api helpFileTitle= 'CL - Importer User Guide';
    @track customPermissions;
    _activeTabValue = 'tab_route_import';
    _refreshDummy;

    constructor() {
        super();
        this.displayHelpVideoLink = true;
        this.retrieveRequiredPerms();
    }

    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
        if(this._activeTabValue === 'tab_route_import_history') {
            this._refreshDummy = Date.now();
        }
    }

    retrieveRequiredPerms() {
        let perms = [];
        perms.push({action: "delete", name: "CL_Delete_Route_Import_Files", enabled:false});
        perms.push({action: "publish", name: "CL_Publish_Route_Import_Files", enabled:false});
        this.customPermissions = perms;
    }
}