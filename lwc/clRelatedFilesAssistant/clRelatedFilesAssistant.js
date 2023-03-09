import {LightningElement, api, track,wire} from 'lwc';
import {uiHelper} from "./clRelatedFilesAssistantUiHelper";
import {NavigationMixin} from "lightning/navigation";
import retrieveHelpFile from '@salesforce/apex/clRelatedFiles.retrieveImporterHelpContentVersion';
import {reduceErrors} from "c/ldsUtils";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {getConstants} from "c/clConstantUtil";

const GLOBAL_CONSTANTS = getConstants();

export default class ClRelatedFilesAssistant extends NavigationMixin(LightningElement) {


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
        console.info('%c----> /lwc/clRelatedFilesAssistant',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        console.log('---> helpFileTitle=',this.helpFileTitle);
    }


    get showBulletPoints() {
        return this.bulletPoints;
    }

    @wire(retrieveHelpFile, {title: '$helpFileTitle'})
    retrieveCsvHelpFile(wiredDto) {
        const { data, error } = wiredDto;
        if(data) {
            const dto = data;
            console.log('help file',JSON.parse(JSON.stringify(dto)));
            this.cvWrapperHelpFile = this._accelUtils.getMapValue('importerhelpcsv', dto.values);
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            uiHelper.showToast(this,'','Problem retrieving help file data: '+this.error,'error');
            this._isLoading = false;
        }
    }
    handlePreviewHelpFile(evt) {
        //uiHelper.showToast(this,'DEVELOPER NOTE','Placeholder! Help Video being posted soon','info');
        uiHelper.navigateToStandardWebPage(this,this.cvWrapperHelpFile.fileDownloadUrl);
    }

    get showHelpVideoLink() {
        return this.displayHelpVideoLink && this.cvWrapperHelpFile;
    }
}