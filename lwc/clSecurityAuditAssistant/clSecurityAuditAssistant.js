import {LightningElement, api, track,wire} from 'lwc';
import {uiHelper} from "./clSecurityAuditAssistantUiHelper";
import {NavigationMixin} from "lightning/navigation";
import {reduceErrors} from "c/ldsUtils";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {getConstants} from "c/clConstantUtil";

const GLOBAL_CONSTANTS = getConstants();

export default class ClSecurityAuditAssistant extends NavigationMixin(LightningElement) {


    @api assistanceType;
    @api assistanceIconClass = 'accel-assistance-info-icon';
    @api title;
    @api helpIconSize = 'x-small';
    @api bulletPoints;
    @api displayHelpVideoLink;
    @api helpFileTitle;

    @track cvWrapperHelpFile;

    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    constructor() {
        super();
        console.info('%c----> /lwc/clSecurityAuditAssistant', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
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