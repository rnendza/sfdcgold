import {LightningElement,api,track} from 'lwc';
import {uiHelper} from "c/geoTabAdminUiHelper";
import { getConstants } from 'c/clConstantUtil';

const GLOBAL_CONSTANTS = getConstants();


export default class GeoTabAdminScheduleMaintAssistant extends LightningElement {
    @api assistanceType;
    @api assistanceIconClass = 'accel-assistance-info-icon';
    @api title;
    @api helpIconSize = 'x-small';
    @api bulletPointCategory;
    @api bulletPoints;
    @api displayHelpVideoLink;
    @api helpFileTitle;

    constructor() {
        super();
        console.info('%c----> /lwc/geoTabAdminScheduleMaintAssistant', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {

    }


    get showBulletPoints() {
        return this.bulletPoints;
    }

    /**
     * Handle collapse / expand of a section.
     * @param evt
     */
    handleSectionClick(evt) {
        if(this._isAccordionProcessing) //  prevent double click
            return;
        let sectionTitleId = evt.currentTarget.dataset.sectiontitleid;
        uiHelper.processAccordion(this,sectionTitleId);
    }
}