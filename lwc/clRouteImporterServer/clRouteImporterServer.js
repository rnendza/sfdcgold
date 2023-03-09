import {LightningElement,api,track} from 'lwc';


export default class ClRouteImporterServer extends LightningElement {

    @api cardTitle = 'Route Importer';
    @api uploadType = 'Route Import';
    @api parentRecordId;
    @api displayHelpVideoLink;
    @api helpFileTitle;
    @api customPermissions; 

    handlePublishAction(evt) {
        this.dispatchEvent(new CustomEvent('publishaction', {detail: {}}));
    }

}