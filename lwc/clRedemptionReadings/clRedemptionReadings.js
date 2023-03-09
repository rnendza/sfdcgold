import {LightningElement, track, api, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {reduceErrors} from 'c/ldsUtils';
import {refreshApex} from "@salesforce/apex";
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import mainTemplate from './clRedemptionReadings.html';
import stencil from './clRedemptionReadingsStencil.html';
import deleteDoc from '@salesforce/apex/clRedemptionController.deleteDoc';
import updateRpsRtRedemptionStartDate from '@salesforce/apex/clRedemptionController.updateRpsRtStartReplenishmentDate';
import updateRpsRtRedemptionEndDate from '@salesforce/apex/clRedemptionController.updateRpsRtEndReplenishmentDate';
import retrieveSurveyMdts from '@salesforce/apex/clRouteProcessingSheetsController.retrieveSurveyMetadatas'
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import {animationHelper} from "./clRedemptionReadingsAnimation";
import {themeOverrider} from "./clRedemptionReadingThemeOverrides";
import lblSurveyFormTitle from '@salesforce/label/c.CL_Collector_Meter_Readings_RPS_Survey_Form_Title';

//import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_stripped_down';
import {loadScript, loadStyle} from "lightning/platformResourceLoader";

import retrieveRpsWrapperData   from '@salesforce/apex/clRedemptionController.retrieveRpsWrapper';

const MAP_KEY_RPS_DATA = 'ROUTE_PROCESSING_SHEET_DATA';
const MAP_KEY_SURVEY_MDTS = 'SURVEY_MDTS';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const GLOBAL_CONSTANTS = getConstants();
const LBL_START_RT_REPLENISHMENT_BUTTON = 'Start RT Replenishment';
const LBL_END_RT_REPLENISHMENT_BUTTON = 'End RT Replenishment';
const LBL_START_RT_REPLENISHMENT_TITLE = 'Start RT Replenishment';
const LBL_END_RT_REPLENISHMENT_TITLE = 'End RT Replenishment';
const MDT_DEV_NAME = 'Meter_Readings';
const MDT_RPS_SURVEY_CUSTOM_DEV_NAME = 'RPSQuestions';

export default class ClRedemptionReadings extends LightningElement {

    @api rpsId;
    @api redemptionType;
    @api imageCompressionRatio = .2;
    @track rpsWrapper;
    @track uiErrorMessage = {};
    @track saveButtonLabel = 'Save RTs';
    @track surveyFields;

    _wiredRpsDto;
    _wiredPageMdt;
    _wiredSurveyDto;
    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _isLoading = true;
    _isUpdating;
    _hasRendered;
    _hasOverrodeTheme;
    _hasOverrodeSfdcCss;
    _chevronTitle = 'Click to collapse content';
    _isAccordionProcessing = false;
    _cameraIconZoom = 6;
    _imageWidth = 175;
    _findCamLauncher;
    _selectedRpsImgType;
    _mdtMeterReadings;
    _pageMdtDevName = MDT_DEV_NAME;
    _lblStartRtReplenishmentBtn = LBL_START_RT_REPLENISHMENT_BUTTON;
    _lblStartRtReplenishmentTitle = LBL_START_RT_REPLENISHMENT_TITLE;
    _lblEndRtReplenishmentBtn = LBL_END_RT_REPLENISHMENT_BUTTON;
    _lblEndRtReplenishmentTitle = LBL_END_RT_REPLENISHMENT_TITLE;
    _hasScrolledToTop;
    _fieldRteMinHeight = '100px';
    _surveyCustomDevName;
    _surveySObjectApiName;

    labels = { lblSurveyFormTitle};

    constructor() {
        super();
        console.info('%c----> /lwc/clRedemptionReadings',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }
    render() {
        return this._isLoading ? stencil : mainTemplate;
    }
    connectedCallback() {
       //this.showToast('WARNING','This screen is currently being worked on (notes) and subject to break 1/24/2021','warning');
    }
    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            this.loadFontAwesome();
            this.overrideThemes();
        }

        // we clicked on an existing image for replace functionality. we have to wait until this control is back in the DOM!
        if( this._findCamLauncher) {
            this._findCamLauncher = false;
            let cmpCamLauncherDiv = this.template.querySelector('div[data-id="'+this._selectedRpsImgType+'"]');
            console.log('---> rendered cb..  cmpCamLauncherDiv',cmpCamLauncherDiv);
            if(cmpCamLauncherDiv) {
                cmpCamLauncherDiv.click();
                this._selectedRpsImgType = null;
            }
        }
    }

    @wire(retrieveRpsWrapperData, {rpsId: '$rpsId'})
    retrieveWiredRps(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const {data,error} = this._wiredRpsDto;
        if(data) {
            const dto = data;
            if(dto.isSuccess) {
                //  @todo dirty hack. create utils deep clone method.
                this.rpsWrapper = JSON.parse(JSON.stringify(this._accelUtils.getMapValue('RPS_WRAPPER_DATA', dto.values)));
                console.log('---> rpsWrapper',JSON.stringify(this.rpsWrapper));
                this._surveyCustomDevName = MDT_RPS_SURVEY_CUSTOM_DEV_NAME;
                this._isLoading = false;
            } else {
                this._isLoading = false;
               // this.uiErrorMsg.body = dto.message;
                console.error('---> wrapper dto false=',JSON.parse(JSON.stringify(dto)));
            }
        } else if (error) {
            this._isLoading = false;
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving rps wrapper data: '+this.error,'error');
        }
    }
    /**
     * Only show "survey" ie. "notes" if:
     *
     *   1. There is an rps id passed here.
     *   2. There are survey fields (ie. it was set up in custom metadata.
     *   3. The survey metadata was found
     *
     *   Notes. it was listed by user req that notes are desired when no vgts exists.
     *
     * @return {*|boolean}
     */
    get showSurvey() {
        return this.rpsId && this.surveyFields && this._surveySObjectApiName;
    }

    /**
     *  Get the page level custom meta-data.
     * @param wiredData
     */
    @wire(retrieveMdt, { mdtDevName: '$_pageMdtDevName' })
    wiredPageMdt(wiredData) {
        this._wiredPageMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
        } else if (data) {
            this._mdtMeterReadings = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
        }
    }

    /**
     *  Get the survey mdt.
     * @param wiredData
     */
    @wire(retrieveSurveyMdts, { surveyDevName: '$_surveyCustomDevName' })
    wiredMdt(wiredData) {
        this._wiredSurveyDto = wiredData;
        const { data, error } = wiredData;
        console.log('wired survery date',JSON.stringify(this._wiredSurveyDto));
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
        } else if (data) {
            if(data.isSuccess) {
                this._mdtRpsSurveyRecords = this._accelUtils.getMapValue(MAP_KEY_SURVEY_MDTS, data.values);
                this.buildSurveyFields();
            } else {
                console.error('--> problem getting survey data',data);
            }
        }
    }

    updateRpsRtStartDate() {
        //this.showToast('','dev to do update here with id:'+this.rpsWrapper.rpsId,'info');
        let params = {rpsId : this.rpsWrapper.rpsId};
         updateRpsRtRedemptionStartDate( params )
             .then(dto => {
                 console.log('--> returned dto from start date update='+JSON.stringify(dto));
                 if (dto.isSuccess) {
                     refreshApex(this._wiredRpsDto);
                     let rpsRecord = this._accelUtils.getMapValue('RPS_RECORD', dto.values)
                 }
                 this.showToast('',dto.message,dto.severity);
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem rt collection start date: '+this.error,'error');
                console.error(this.error);
            });
    }

    updateRpsRtEndDate() {
        //this.showToast('','dev to do update here with id:'+this.rpsWrapper.rpsId,'info');
        let params = {rpsId : this.rpsWrapper.rpsId};
        updateRpsRtRedemptionEndDate( params )
            .then(dto => {
                console.log('--> returned dto from end date update='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    refreshApex(this._wiredRpsDto);
                    let rpsRecord = this._accelUtils.getMapValue('RPS_RECORD', dto.values)
                }
                this.showToast('',dto.message,dto.severity);
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem setting RT Redemption End Date: '+this.error,'error');
                console.error(this.error);
            });
    }
    deleteDocument(docId,rpsId) {
        let params = {docId : docId, rpsId : rpsId};
        console.log('---> calling delete doc.. params:',params);
        deleteDoc( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    refreshApex(this._wiredRpsDto);
                    this.showToast('','Delete Successful','success');
                }
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem deleting doc: '+this.error,'error');
                console.error(this.error);
            });
    }
    triggerSurveyFormSave() {
        if(this.surveyFields) {
            this._isLoading = true;
            let ele = this.template.querySelector('c-cl-rps-survey');
            if (ele) {
                this._isUpdating = true;
                try {
                    console.log('--- firing save from parent');
                    ele.triggerSaveEvent();
                } catch (e) {
                    console.error(e);
                }
            }
        }
    }
    handleFileReplaceCanceled(evt) {
        console.log('---> handleFireReplaceCanceled');
        refreshApex(this._wiredRpsDto);
    }

    handleRtCamLauncherClick(evt) {
        evt.preventDefault();
        console.log('---------------->cam launcher click');
        let type = evt.target.dataset.id;

        console.log('--> camlauncher click. type=', type);
        let cmpCamLauncher = this.template.querySelector('c-ui-camera-launcher[data-id="' + type + '"]');
        //console.log(cmpCamLauncher);
        cmpCamLauncher.camLauncherClick();
        // //this.modifySingleMeterReading(selectedAssetId)
    }
    handleFileUploaded(evt) {
        let payload = evt.detail;
        console.log('---> file upload payload = ',payload);
        refreshApex(this._wiredRpsDto);
        //this._isLoading = false;
    }

    handleDateStartClickAction(evt) {
        this.updateRpsRtStartDate();
    }
    handleDateEndClickAction(evt) {
        this.updateRpsRtEndDate();
    }
    /**
     * Reads the custom mdt to build the fields objects to pass to the child survey component.
     * For now this is just the 'notes' field.
     */
    buildSurveyFields() {
        let fields = [];
        if(this._mdtRpsSurveyRecords && Array.isArray(this._mdtRpsSurveyRecords)) {
            console.log('building survey fields');
            let surveySObjectName;
            let i = 0;
            let anyFundsInFieldsValues = false;
            this._mdtRpsSurveyRecords.forEach((mdtRecord) => {
                if(i == 0) {
                    surveySObjectName = mdtRecord.SObject_Api_Name__c;
                }
                if(mdtRecord.Dependent_On__c) {
                    let showIt = this.performSurveyDependencyChecks(mdtRecord);
                    if(!showIt) {
                        if(!showIt) {
                            return;  //  Loop to the next field in mdt records.
                        } else {
                            anyFundsInFieldsValues = true;
                        }
                    }
                }
                let field = {
                    name: mdtRecord.Field_Api_Name__c,
                    variant: mdtRecord.Variant__c,
                    active: mdtRecord.Active__c,
                    order: mdtRecord.Order__c,
                    required: mdtRecord.Required__c,
                    disabled: mdtRecord.Disabled__c,
                    readOnly: mdtRecord.Read_Only__c,
                    label: mdtRecord.Field_Label__c,
                    fieldClass: mdtRecord.Field_Class__c
                };
                if(mdtRecord.Text_Area_Min_Height__c) {
                    this._fieldRteMinHeight = mdtRecord.Text_Area_Min_Height__c;
                }
                fields.push(field);
                i++;
            });
            //  If the header (ie Account Funds In Field value exists but no value has been assigned. don't show the header
            try {
                if (!anyFundsInFieldsValues) {
                    if (fields.length > 0) {
                        fields = fields.filter(x => x.name !== 'Location_Funds_In_Field_Value__c');
                    }
                }
            } catch(e) {
                console.error(e);
            }
            this._surveySObjectApiName = surveySObjectName;
            this.surveyFields = fields;
            console.log('surveyFields',this.surveyFields);
        }
    }

    /**
     * Branches to 1 or more dependency checks via evaluating metadata associated with the record.
     * @param mdtRecord
     * @returns {boolean}  true if we should show the field, otherwise false.
     */
    performSurveyDependencyChecks(mdtRecord) {
        let showIt = false;
        if(this._debugConsole) {
            console.log('---> running mdt dependency checks',mdtRecord);
        }
        if(mdtRecord && mdtRecord.Dependent_On__c == 'Account__r.Funds_in_Field__c') {
            showIt = this.performFundsInDependencyCheck(mdtRecord);
        }
        return showIt;
    }

    /**
     * Determines if the PL value(s) in Account__r.Field_in_Field__c match the mdt record Dependent_Value__c.
     * If so, so the field. If not, don't show it!
     * @param mdtRecord
     * @returns {boolean} true if we should show the field, otherwise false.
     */
    performFundsInDependencyCheck(mdtRecord) {
        let showIt = false;
        let accountFundsInFieldValue = this.rpsWrapper.rpsAccountFundsInField;
        let accountFundsInFieldArr = this.parseFundsInFieldMultiSelect(accountFundsInFieldValue);
        if (Array.isArray(accountFundsInFieldArr) && mdtRecord.Dependent_Value__c) {
            showIt = accountFundsInFieldArr.includes(mdtRecord.Dependent_Value__c);
        }
        if(this._debugConsole) {
            console.log('---> running funds in dependency check with array'+JSON.stringify(accountFundsInFieldArr)+ 'returning showIt',showIt);
        }
        return showIt;
    }

    /**
     * Transform those messy multi-selects into an array.
     *
     * @param fundsInFieldValue
     * @returns {*[]}
     */
    parseFundsInFieldMultiSelect(fundsInFieldValue) {
        let fundsInValues = [];
        if(fundsInFieldValue) {
            fundsInValues = String(fundsInFieldValue).split(";");
        }
        return fundsInValues;
    }
    /**
     * Event called from child image thumb component upon click.
     * We toggle the current rpsWrapper to show the cam launcher and hide the image thumb.
     * We have to wait till the dom rerenders this the boolean being set (renderedcallback is called)
     * @param evt
     */
    handleUiImgClick(evt) {
        const rpsImageType = evt.currentTarget.dataset.rpsimagetype;
        if (rpsImageType) {
            this._selectedRpsImgType = rpsImageType;
            switch (rpsImageType) {
                case 'currentcassette':
                    this.rpsWrapper.currentCassetteImg.showThumb = false;
                    this.rpsWrapper.currentCassetteImg.showCamLauncher = true;
                    break;
                case 'currentcoin':
                    this.rpsWrapper.currentCoinImg.showThumb = false;
                    this.rpsWrapper.currentCoinImg.showCamLauncher = true;
                    break;
                case 'newcassette':
                    this.rpsWrapper.newCassetteImg.showThumb = false;
                    this.rpsWrapper.newCassetteImg.showCamLauncher = true;
                    break;
                case 'newcoin':
                    this.rpsWrapper.newCoinImg.showThumb = false;
                    this.rpsWrapper.newCoinImg.showCamLauncher = true;
                    break;
            }
            this._findCamLauncher = true;
            console.log('---> trigger renderedcallback...selected img type', rpsImageType);
        }
    }


    get noDataHeaderText() {
        return 'No redemption data found.'
    }
    get showNoData() {
        return !this.rpsWrapper;
    }
    get showRpsForm() {
        return this.rpsWrapper;
    }

    get  showOverflowFields() {
         return this.rpsWrapper && this.rpsWrapper.rpsReplenishmentType && this.rpsWrapper.rpsReplenishmentType === 'Cash Fill';
    }

    overrideThemes() {
        if(!this._hasOverrodeTheme) {
            this.buildFormThemeOverrideCss();
        }
        if(!this._hasOverrodeSfdcCss) {
            this.buildSfdcCoreOverrideCss();
        }
    }

    /**
     * The div is not being found in the DOM on rerender after a mass update so we are losing the theme.. force it again.
     */
    forceThemeOverrides() {
        this.buildFormThemeOverrideCss();
        this.buildSfdcCoreOverrideCss();
    }
    /**
     * Loads font awesome js and css for fonts not available in SLDS.
     * @todo only load what is needed. we are probably loading too much here.
     */
    loadFontAwesome() {
        Promise.all([
            //loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/style.css'),
        ])
            .then(() => {
                console.log( 'debug',' === loaded font awesome ===');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }

    buildFormThemeOverrideCss() {
        let css = '';
        const style = document.createElement('style');
        css += '.accel-input_override .slds-input {width: 100%;display: inline-block;height: 40px!important; ';
        css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
        css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;};';


        style.innerText = css;
        let target = this.template.querySelector('.form-theme-overrides-class');
        if(target) {
            target.appendChild(style);
            this._hasOverrodeTheme = true;
        }
    }

    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     */
    buildSfdcCoreOverrideCss() {
        themeOverrider.buildSfdcCoreOverrideCss(this);
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
    get showLastModDate()  {
        return this.rpsWrapper && this.rpsWrapper.rtStatus !== 'Not Started' && this.rpsWrapper.lastModNotEqualCreated;
    }
    get showRtStartReplenishmentMsg() {
        return this.rpsWrapper && !this.rpsWrapper.rpsRtStartReplenishmentDate;
    }
    get startButtonHelpText() {
        let lbl  = 'Please click the button to START your RT Replenishment for ';
        return lbl + this.rpsWrapper.rpsAccountName;
    }
    get endButtonHelpText() {
        let lbl  = 'Please click the button to END your RT Replenishment for ';
        return lbl + this.rpsWrapper.rpsAccountName;
    }

    /**
     * This will the RPS RT End Replenishment Button if:
     *
     *   1. A Route_Processing_Sheet__c.End_VGT_Collection_Date__c is not populated.
     *   2. Meters are considered 'finished'.
     *   3. The checkbox on the custom metadata has been toggled checked
     *      ie. Cash_Logistics_Setting__mdt[Meter_Readings].Show_RPS_Location_Timestamp__c = true.
     *
     * @returns {number|boolean}  Indicating if we should show the VGT End Collection Msg.
     */
    // get showRtEndReplenishmentMsg() {
    //     let showIt;
    //     if(this.rpsWrapper) {
    //         let dateNotPopulated = this.rpsWrapper && !this.rpsWrapper.rpsRtEndReplenishmentDate;
    //         let statusComplete = this.rpsWrapper && this.rpsWrapper.rtStatus === 'Complete' && this.rpsWrapper.rpsCollectionStatus != 'Skipped';
    //         alert(statusComplete);
    //         let mdtShowIt = this._mdtMeterReadings && this._mdtMeterReadings.Show_RPS_Location_Timestamp__c;
    //
    //         //showIt = mdtShowIt & dateNotPopulated && metersFinished;
    //         showIt = mdtShowIt & dateNotPopulated && statusComplete;
    //
    //         if (showIt && !this._hasScrolledToTop) {
    //             try {
    //                 //  Experimental. scroll to the top but do it only once per page life.
    //                 window.scrollTo({top: 0, behavior: 'smooth'});
    //                 this._hasScrolledToTop = true;
    //             } catch (e) {
    //                 console.error(e);
    //             }
    //         }
    //     }
    //     alert('show it='+showIt);
    //     return showIt;
    // }

    get showRtEndReplenishmentMsg() {
        let showIt;
        let dateNotPopulated = this.rpsWrapper && !this.rpsWrapper.rpsRtEndReplenishmentDate;
        showIt = dateNotPopulated && this.rpsWrapper.rtStatus === 'Complete' & this.rpsWrapper.rpsCollectionStatus !== 'Skipped';;
        if(showIt && !this._hasScrolledToTop) {
            try {
                window.scrollTo({top: 0, behavior: 'smooth'});
                this._hasScrolledToTop = true;
            } catch (e) {
                console.error(e);
            }
        }
        return showIt;
    }
    get showRtCoinImages() {
        let showIt = true;
        if(this._wiredPageMdt) {
            showIt = this._wiredPageMdt.Show_RT_Coin_Images__c;
        }
    }
    handleFormSubmit(evt) {
        console.log('--> rt handle child form submit..');
        refreshApex(this._wiredRpsDto);
        this.triggerSurveyFormSave();
    }
    handleSaveSubmit(evt) {
        try {
            this.template.querySelector('c-cl-cassette-inbound-form').triggerSaveEvent();
            console.log('trigger save');
        } catch (e) {
            console.error(e);
        }
    }
    handleSurveyFormSubmitted(evt) {ƒ
        //@todo check return result.
        this._isUpdating = false;
        this._isLoading = false;
        console.log('---> survery form submitted successfully');
        // if( (!this.meterReadings || this.meterReadings.length < 1) && this._isUiModifyAll) {
           // this.showToast('', 'Notes saved successfully', 'success');
        // }
        this._isUiModifyAll = false;
    }
    handleImageOptionClick(evt) {
        let optionClicked = evt.detail.value;
        console.log('--> optionClicked='+optionClicked);

        switch (optionClicked) {
            case 'delete' :
                this.processImageDeleteClick(evt,false);
                break;
            case 'download':
                this.processDownloadClick(evt);
                break;
            case 'preview':
                this.showToast('','Preview is reserved for future functionality if desired!');
                //this.processPreviewClick(evt);
                break;
            default :
                break;
        }
    }
    processDownloadClick(evt) {

        let dataset = evt.target.dataset;
        console.log('dataset',dataset);;
        let rpsId = dataset.rpsid;
        let dlLink = this.template.querySelector('a[data-rpsid="'+rpsId+'"]');
        console.log('dllink',dlLink);
        dlLink.click();
    }

    //@todo
    get showImageMetadata() {
        return false;
    }
    handleRedemptionSectionClick(evt) {
        if(this._isAccordionProcessing) //  prevent double click
            return;
        let sectionTitleId = evt.currentTarget.dataset.sectiontitleid;
        if(sectionTitleId) {
            let eleSectionContent = this.template.querySelector("div[data-sectioncontentid="+sectionTitleId+"]");
            let eleSectionArrow = this.template.querySelector("div[data-sectionarrowid="+sectionTitleId+"]");
            //console.log(JSON.stringify(eleSectionArrow));
            if(eleSectionContent) {
                const sectionOpen  = eleSectionContent.getAttribute('class').search( 'slds-show') != -1;
                if(sectionOpen) {
                    eleSectionContent.classList.remove('slds-show');
                    eleSectionContent.classList.add('slds-hide');
                    animationHelper.animateSection(eleSectionContent,eleSectionArrow,'close')
                    this._chevronTitle = 'Click to expand content';
                } else {
                    eleSectionContent.classList.remove('slds-hide');
                    eleSectionContent.classList.add('slds-show');
                    animationHelper.animateSection(eleSectionContent,eleSectionArrow,'open');
                    this._chevronTitle = 'Click to collapse content';
                }
            }
        }
    }
    processImageDeleteClick(evt,promptConfirm){
        let dataset = evt.target.dataset;
        if(dataset && dataset.docid && dataset.rpsid) {
            //const payload = {docId: dataset.docid, meterId: dataset.meterid, actionType: 'deleteDoc'}
            if (promptConfirm) {
                //this.originalMessage = payload;
                //this.isDialogVisible = true;
            } else {
                this.deleteDocument(dataset.docid, dataset.rpsid);
            }
        } else {
            this.showToast('', 'Unable to delete image!', 'error');
            console.error('--> dataset=' + JSON.stringify(dataset));
        }
    }
}