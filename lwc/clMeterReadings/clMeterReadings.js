import {LightningElement, track, wire} from 'lwc';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {reduceErrors} from 'c/ldsUtils';
import {refreshApex} from "@salesforce/apex";
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import stencil from './clMeterReadingsStencil.html';
import mainTemplate from './clMeterReadings.html';
import { animationHelper} from "./clMeterReadingsAnimation";
import { themeOverrider} from "./clMeterReadingsThemeOverrides";
import retrieveMeterReadings   from '@salesforce/apex/clMeterReadingsController.retrieveRpsMeterReadings';
import retrieveRpsData   from '@salesforce/apex/clMeterReadingsController.retrieveRouteProcessingSheet';
import upsertMeterReading from '@salesforce/apex/clMeterReadingsController.upsertMeterReading';
import upsertMeterReadings from '@salesforce/apex/clMeterReadingsController.upsertMeterReadings';
import retrieveSurveyMdts from '@salesforce/apex/clRouteProcessingSheetsController.retrieveSurveyMetadatas'
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import deleteDoc from '@salesforce/apex/clMeterReadingsController.deleteDoc';
import updateRpsVgtStartDate from '@salesforce/apex/clMeterReadingsController.updateRpsVgtCollectionStartDate';
import updateRpsVgtEndDate from '@salesforce/apex/clMeterReadingsController.updateRpsVgtCollectionEndDate';
import updateRpsCollectionStatus from '@salesforce/apex/clMeterReadingsController.updateRpsCollectionStatus';
import updateAllMetersToCannotCollect from '@salesforce/apex/clMeterReadingsController.updateAllMeterReadingsToCannotCollect';
import lblSurveyFormTitle from '@salesforce/label/c.CL_Collector_Meter_Readings_RPS_Survey_Form_Title';
import lblCardTitleRedemption from '@salesforce/label/c.CL_Process_Fill_Outbound_Fill_Card_Title_Redemption'
import lblSkipRouteLinkDesc from '@salesforce/label/c.CL_Collector_Meters_Action_Skip_Link_Desc';
import lblSkipRouteDialogButtonConfirm from '@salesforce/label/c.CL_Collector_Meters_Action_Skip_Dialog_Button_Confirm';
import lblSkipRouteDialogButtonCancel from '@salesforce/label/c.CL_Collector_Meters_Action_Skip_Dialog_Button_Cancel';
import lblSkipRouteDialogIcon from '@salesforce/label/c.CL_Collector_Meters_Action_Skip_Dialog_Icon';
import lblSkipRouteDialogTitle from '@salesforce/label/c.CL_Collector_Meters_Action_Skip_Dialog_Title';
import lblSkipRouteDialogMsg from '@salesforce/label/c.CL_Collector_Meters_Action_Skip_Dialog_Msg';
import lblCannotCollect from '@salesforce/label/c.CL_Collector_Meters_Labels_Cannot_Collect';

import METER_READING_OBJECT from '@salesforce/schema/Meter_Reading__c';
import METER_READING_FIELD_ID from '@salesforce/schema/Meter_Reading__c.Id';
import METER_READING_FIELD_CURR_LT_CASH_IN from '@salesforce/schema/Meter_Reading__c.Current_Lifetime_Cash_In__c';
import METER_READING_FIELD_ASSETID from '@salesforce/schema/Meter_Reading__c.Asset__c';
import METER_READING_FIELD_RPSID from '@salesforce/schema/Meter_Reading__c.Route_Processing_Sheet__c';
import METER_READING_CANNOT_COLLECT_FIELD from '@salesforce/schema/Meter_Reading__c.Cannot_Collect__c';
import METER_READING_READING_STATUS_FIELD from '@salesforce/schema/Meter_Reading__c.Reading_Status__c';
import TIMEZONE from "@salesforce/i18n/timeZone";
import LOCALE from "@salesforce/i18n/locale";




const GLOBAL_CONSTANTS = getConstants();
const RECORD_TYPE_VGT = 'VGT';
const RECORD_TYPE_REDEMPTION = 'Redemption';
const DEFAULT_MACHINE_TYPE = RECORD_TYPE_VGT;
const MAP_KEY_METERS_DATA = 'METER_READING_WRAPS';  //  A meter readings for the rps.
const MAP_KEY_METER_READING_WRAP = 'METER_READING_WRAP';
const MAP_KEY_METER_READING_RECORD = 'METER_READING_RECORD';
const MAP_KEY_RPS_DATA = 'ROUTE_PROCESSING_SHEET_DATA';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const MAP_KEY_SURVEY_MDTS = 'SURVEY_MDTS';
const MAP_KEY_MDT_METER_READINGS = 'MDT_METER_READINGS';
const MDT_RPS_SURVEY_CUSTOM_DEV_NAME = 'RPSQuestions';
const PAGE_RPS_SHEETS = 'home';
const DEFAULT_IMG_COMPRESSION_RATIO = 0.5;
const MDT_DEV_NAME = 'Meter_Readings';
const LBL_START_VGT_COLLECTION_BUTTON = 'Start VGT Collection';
const LBL_END_VGT_COLLECTION_BUTTON = 'End VGT Collection';
const LBL_START_VGT_COLLECTION_TITLE = 'Start VGT Collection';
const LBL_END_VGT_COLLECTION_TITLE = 'End VGT Collection';


/**
 *  Top down general structure is..
 *  1. Lifecycle Methods.
 *  2. Wired methods.
 *  3. Nav State setters.
 *  4. Window event handlers.
 *  5. Accessor methods.
 *  6. DOM Event handlers.
 *  7. Misc.
 */
export default class ClMeterReadings extends NavigationMixin(LightningElement) {

    @track meterReadings;
    @track currentPageReference = null;
    @track urlStateParameters = null;
    @track uiErrorMsg = {};
    @track rpsId;
    @track rpsRecord;
    @track surveyFields;


    @track startVgtStartCollectionPayload;
    @track confirmDisplayMessage;
    @track skipDialogVisible;
    @track skipDialogPayload;


    _lblStartVgtCollectionBtn = LBL_START_VGT_COLLECTION_BUTTON;
    _lblEndVgtCollectionBtn = LBL_END_VGT_COLLECTION_BUTTON;
    _lblStartVgtCollectionTitle = LBL_START_VGT_COLLECTION_TITLE;
    _lblEndVgtCollectionTitle = LBL_END_VGT_COLLECTION_TITLE;

    labels = {
        lblSurveyFormTitle, lblCardTitleRedemption, lblSkipRouteLinkDesc,
        lblSkipRouteDialogIcon,lblSkipRouteDialogButtonConfirm,lblSkipRouteDialogMsg,
        lblSkipRouteDialogTitle,lblSkipRouteDialogButtonCancel,lblCannotCollect
    };
    _wiredPageMdt;
    _wiredSurveyDevName;
    _defaultMachineType = DEFAULT_MACHINE_TYPE;
    _noDataBodyText = 'No Data found';
    _rpsId;
    _routeId;
    _accountId;
    _view;
    _beforePopState;
    _beforeUnload;
    _prevTemplateSize = 'SMALL';
    _outerContainerClass= 'slds-m-around_xxx-small accel-test-borders';
    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _mdtMeterReadings;
    _wiredRpsDto;
    _wiredMetersDto;
    _pageMdtDevName = MDT_DEV_NAME;
    _isLoading = false;
    _isMachineTypeSwitch = false;
    _hasRendered;
    _hasOverrodeTheme;
    _hasOverrodeSfdcCss;
    _machineTypeSelected; /* = this._defaultMachineType;*/
    _imageWidth = 150;
    _imageHeight = 150;
    _isUiModifyAll;
    _isUpdating;
    _meterUpdateSucceed;
    _forceMetersRefresh;
    _bFindCamLauncher = false;
    _selectedAssetId;
    _currentPageReference;
    _isAccordionProcessing = false;
    _chevronTitle = 'Click to collapse content';
    _fieldRteMinHeight = '100px';
    _surveyCustomDevName;
    _surveySObjectApiName;
    _surveyTitle = 'blah survey';
    _mdtRpsSurveyRecords;
    _hasScrolledToTop;

    /**
     * Takes a label and replaces values such as {0}, {1}
     *
     * @param stringToFormat       The label itself.
     * @param formattingArguments  A comma delim array of replacement values.
     * @returns {string}           The substituted label.
     * @todo  move to a service.
     *
     * Example call:
     *   let msg = ClMeterReadings.formatLabel(lbl, [val1ToReplace,val2ToReplace]);
     */
    static formatLabel(stringToFormat, ...formattingArguments) {
        if (typeof stringToFormat !== 'string') {
            throw new Error('\'stringToFormat\' must be a String');
        }
        return stringToFormat.replace(/{(\d+)}/gm, (match, index) =>
            (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
    }

    constructor() {
        super();
        console.info('%c----> /lwc/clMeterReadings',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    render() {
        return mainTemplate;
    }

    connectedCallback() {
        this.registerWindowEvents();
    }

    /**
     * Override core sdfd classes (shadow dom thing) if necessary. Also.. if someone is attempting to replace an
     * already existing img.. fire a click event on the cam launcher component. If this is a click on the vgt / rt
     * toggle button (ie _forceMeterRefresh) force a refresh of the cache since communities is an SPA.
     */
    renderedCallback() {
        if(this._forceMetersRefresh) {
            refreshApex(this._wiredMetersDto);
            this._forceMetersRefresh = false;
        }
        if(!this._hasRendered) {
            this._hasRendered = true;
        }
        this.overrideThemes();
        // we clicked on an existing image for replace functionality. we have to wait until this control is back in the DOM!
        if( this._bFindCamLauncher) {
            this._bFindCamLauncher = false;
            let cmpCamLauncherDiv = this.template.querySelector('div[data-id="'+this._selectedAssetId+'"]');
            if(cmpCamLauncherDiv) {
                cmpCamLauncherDiv.click();
            }
        }
    }

    /**
     * @todo make sure these are unregistering?
     */
    disconnectedCallback() {
        this.removeWindowEvents();
    }

    /**
     * Reads the custom mdt to build the fields objects to pass to the child survey component.
     */
    buildSurveyFields() {
        let fields = [];
        if(this._mdtRpsSurveyRecords && Array.isArray(this._mdtRpsSurveyRecords)) {
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
                        return;  //  Loop to the next field in mdt records.
                    } else {
                        anyFundsInFieldsValues = true;
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
        let accountFundsInFieldValue = this.rpsRecord.Account__r.Funds_in_Field__c;
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

    get skipDialogMsg() {
        let msg;
        let lbl = this.labels.lblSkipRouteDialogMsg;
        if(this.rpsRecord && this.rpsRecord.Account__r) {
            msg = ClMeterReadings.formatLabel(lbl, [this.rpsRecord.Account__r.Name]);
        } else {
            msg = lbl;
        }
        return msg;
    }

    /**
     * Find the parent route processing sheet record.
     * @param wiredDto  The wired data from the server.
     */
    @wire(retrieveRpsData, {rpsId: '$_rpsId'})
    retrieveRps(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const { data, error } = this._wiredRpsDto;
        if(data) {
            const dto = data;
            if(dto.isSuccess) {
                this.rpsRecord = Object.assign({},this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, dto.values));
                if (this.rpsRecord) {
                    this.rpsId = this.rpsRecord.Id;
                    //  Fire off wired survey mdt call only after we have rps data so
                    //  we can conditionally work with parent account data.
                    this._surveyCustomDevName =  MDT_RPS_SURVEY_CUSTOM_DEV_NAME;
                }
            } else {
                this.uiErrorMsg.body = dto.message;
            }
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving rps data: '+this.error,'error');
        }
    }

    /**
     *
     * @param currentPageReference
     */
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this._currentPageReference = currentPageReference;
            this.urlStateParameters = currentPageReference.state;
            if(this.urlStateParameters) {
                this.setParametersBasedOnUrl();
            }
        }
    }

    /**
     * Call the server to retrieve the meter reading records.
     * @param wiredDto The wired Meter_Reading__c records.
     */
    @wire(retrieveMeterReadings, {rpsId: '$rpsId',assetRecordType:'$_machineTypeSelected'})
    retrieveMeterData(wiredDto) {
        this._wiredMetersDto = wiredDto;
        const { data, error } = this._wiredMetersDto;
        if(data) {
            this.forceThemeOverrides();
            if(data.isSuccess) {
                console.log('---> meter data successfully retrieved');
                let tmpReadings =  [...this._accelUtils.getMapValue(MAP_KEY_METERS_DATA, data.values)];
                this.meterReadings = tmpReadings.map(element => Object.assign({},element));
            } else {
                this._noDataBodyText = data.message;
            }
            this._isLoading = false;
        } else if (error) {
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving meter data: '+this.error,'error');
            console.error(this.error);
            this._isLoading = false;
        }
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
            //console.log('--> mdt meterreadings',this._mdtMeterReadings);
        }
    }

    /**
     *  Get the survey mdt.
     * @param wiredData
     */
    @wire(retrieveSurveyMdts, { surveyDevName: '$_surveyCustomDevName' })
    wiredMdt(wiredData) {
        this._wiredSurveyDevName = wiredData;
        const { data, error } = wiredData;
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

    /**
     * Update a single meter reading.
     * @param selectedAssetId  The selected meter reading (asset id)
     */
    modifySingleMeterReading(selectedAssetId) {
        let meterReadingWrap;
        if(selectedAssetId) {
            meterReadingWrap = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);
            let meterReading = {
                [METER_READING_FIELD_ID.fieldApiName] : meterReadingWrap.meterId,
                [METER_READING_FIELD_RPSID.fieldApiName] : this._rpsId ,
                [METER_READING_FIELD_ASSETID.fieldApiName] : selectedAssetId,
                [METER_READING_FIELD_CURR_LT_CASH_IN.fieldApiName] : meterReadingWrap.lifeTimeCashInAmount,
                [METER_READING_CANNOT_COLLECT_FIELD.fieldApiName] : meterReadingWrap.cannotCollect
            };
            this.modifyMeterReading(meterReading);
        }
    }

    /**
     * Trigger saves on the survey form.  and Call the server to update the Meter_Reading__c record.
     * @param meterReading The Meter_Reading__c record to update.
     */
    modifyMeterReading(meterReading) {

        let params = {meterReading: meterReading};
        console.log('--> calling upsertMeterReadings with mr Id:' + meterReading.Id);
        this.triggerSurveyFormSave();

        upsertMeterReading(params)
            .then(dto => {
                this._meterUpdateSucceed = dto.isSuccess;
                if (dto.isSuccess) {
                    let updatedMeterReadingWrap = this._accelUtils.getMapValue(MAP_KEY_METER_READING_WRAP, dto.values);
                    let updatedMeterReadingRecord = this._accelUtils.getMapValue(MAP_KEY_METER_READING_RECORD, dto.values);
                    console.log('updated mr wrap id=' + updatedMeterReadingWrap.meterId);
                    let meterReadingWrap = this.meterReadings.find(x => x.meterId === updatedMeterReadingWrap.meterId);
                    console.log('updated array wrap id=' + meterReadingWrap.meterId);
                    meterReadingWrap.meterReading = updatedMeterReadingRecord;
                    meterReadingWrap.meterLastModifiedDate = updatedMeterReadingRecord.LastModifiedDate;
                    meterReadingWrap.meterIconClass = updatedMeterReadingWrap.meterIconClass;
                    meterReadingWrap.meterBadgeClass = updatedMeterReadingWrap.meterBadgeClass;
                    meterReadingWrap.meterReadingCompletedTextClass = updatedMeterReadingWrap.meterReadingCompletedTextClass;
                    refreshApex(this._wiredRpsDto);
                } else {
                    console.log(' error in update' + JSON.stringify(dto));
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                this._meterUpdateSucceed = false;
                this.error = reduceErrors(error);
                this.showToast('', 'Problem updating meter data: ' + this.error, 'error');
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
    modifyAllMeterReadings(bShowUpdate,bShowRefresh) {
        let meterReadingSObjects = [];

        if(!this.meterReadings || this.meterReadings.length < 1) {
            //--> mst this._isMachineTypeSwitch = false;
            console.warn('no meterreadings in  existing modify all');
            this._isLoading = false;
        } else {
            this.meterReadings.forEach((meterWrap) => {
                let meterReadingSObject = {
                    [METER_READING_FIELD_ID.fieldApiName] : meterWrap.meterId,
                    [METER_READING_FIELD_RPSID.fieldApiName] : this._rpsId ,
                    [METER_READING_FIELD_ASSETID.fieldApiName] : meterWrap.machineAssetId,
                    [METER_READING_FIELD_CURR_LT_CASH_IN.fieldApiName] : meterWrap.lifeTimeCashInAmount,
                    [METER_READING_CANNOT_COLLECT_FIELD.fieldApiName] : meterWrap.cannotCollect
                };
                //  Added cannot connect 5/9/2022 https://accel-entertainment.monday.com/boards/1300348967/pulses/2647616920
                meterReadingSObjects.push(meterReadingSObject);
            });
            let params = { meterReadings: meterReadingSObjects };
            console.log('--> calling upsertMeterReadings2');
            if(bShowUpdate) {
                this._isUpdating = true;
            } else {
                this._isUpdating = false;
            }
            upsertMeterReadings( params )
                .then(dto => {
                    console.log('--> meter update return value='+dto.isSuccess);
                    this._meterUpdateSucceed = dto.isSuccess;
                    this._isUpdating = false;
                    if (dto.isSuccess) {
                        refreshApex(this._wiredMetersDto);
                        refreshApex(this._wiredRpsDto);
                        this._isUiModifyAll = false;
                        if(bShowUpdate) {
                            this.showToast('', 'All Meter Readings were updated successfully!', 'success');
                        } else if (bShowRefresh) {
                            this.showToast('','Meter readings refreshed successfully!','success');
                        }
                        this._isLoading = false;
                        //--> mts this._isMachineTypeSwitch = false;
                        this.forceThemeOverrides();
                    } else {
                        this._isLoading = false;
                        //--> mts this._isMachineTypeSwitch = false;
                        this.forceThemeOverrides();
                        this._isUiModifyAll = false;
                        console.log(' error in update' + JSON.stringify(dto));
                        this.showToast('', dto.message, 'error');
                    }
                })
                .catch(error => {
                    this._isUpdating = false;
                    this._isLoading = false;
                    this._isUiModifyAll = false;
                    // --> mts this._isMachineTypeSwitch = false;
                    this.forceThemeOverrides();
                    this._meterUpdateSucceed = false;
                    this.error = reduceErrors(error);

                    if(!bShowUpdate && !bShowRefresh) {
                        this.showToast('', 'Problem mass updating meter data: ' + this.error, 'error');
                    } else if (bShowUpdate) {
                        this.showToast('', 'Meter readings could not be updated.. Please check your connection','error');
                    } else if (bShowRefresh) {
                        this.showToast('','Meter readings could not be refreshed. Please check your connection','error');
                    }
                    console.error(this.error);
                });
        }

        this.triggerSurveyFormSave();
        console.info('meter readings to upload',meterReadingSObjects);


    }
    deleteDocument(docId,meterId) {
        let params = {docId : docId, meterId : meterId};
        console.log('---> calling delete doc.. params:',params);
        deleteDoc( params )
            .then(dto => {
                console.log('--> returned dto='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    refreshApex(this._wiredMetersDto);
                    this.showToast('','Delete Successful','success');
                }
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem deleting doc: '+this.error,'error');
                console.error(this.error);
            });
    }

    updateVgtCollectionStartDate() {
        let params = {rpsRecord : this.rpsRecord};
        updateRpsVgtStartDate( params )
            .then(dto => {
                console.log('--> returned dto from start date update='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    this.rpsRecord = Object.assign({},this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, dto.values));
                }
                this.showToast('',dto.message,dto.severity);
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem updating vgt collection start date: '+this.error,'error');
                console.error(this.error);
            });
    }

    updateVgtCollectionEndDate() {
        let params = {rpsRecord : this.rpsRecord};
        updateRpsVgtEndDate( params )
            .then(dto => {
                console.log('--> returned dto from end date update='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    this.rpsRecord = Object.assign({},this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, dto.values));
                }
                this.showToast('',dto.message,dto.severity);
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem updating vgt collection end date: '+this.error,'error');
                console.error(this.error);
            });
    }

    /**
     *
     * @param status  The Route_Processing_Sheet__c.Status__c picklist value.
     */
    updateRpsColStatus( status ) {
        let params = {rpsRecord : this.rpsRecord, collectionStatus : status};
        updateRpsCollectionStatus( params )
            .then(dto => {
                if (dto.isSuccess) {
                    this.rpsRecord = Object.assign({},this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, dto.values));
                    console.log('---> result of col status update.',dto.technicalMsg);
                    this.showToast('',dto.message,dto.severity);
                    refreshApex(this._wiredRpsDto);
                    this.handleBackClick();
                } else {
                    this.showToast('',dto.message,dto.severity);
                }
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem updating rps collection status: '+this.error,'error');
                console.error(this.error);
            });
    }

    /**
     * @param rpsId  The parent Route_Processing_Sheet__c.Id of the meters to update.
     */
    updateMetersToCannotCollect( rpsId ) {
        let params = {rpsId : rpsId};
        updateAllMetersToCannotCollect( params )
            .then(dto => {
                if (!dto.isSuccess) {
                    console.warn('update all to cannot collect warning',JSON.stringify(dto));
                } else {
                    console.debug('updated call meters to cannot collect!');
                }
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem updating rps meters to cannot collect: '+this.error,'error');
                console.error(this.error);
            });
    }

    setParametersBasedOnUrl() {
        if(!this._disconnectCb) {
            if(!this.urlStateParameters || !this.urlStateParameters.rpsId || !this.urlStateParameters.accountId) {
                return;
            }
            if (this.urlStateParameters.rpsId) {
                if(this.urlStateParameters.rpsId != null) {
                    this._rpsId = this.urlStateParameters.rpsId;
                }
            }
            if (this.urlStateParameters.accountId) {
                if(this.urlStateParameters.accountId != null) {
                    this._accountId = this.urlStateParameters.accountId;
                }
            }
            if (this.urlStateParameters.view) {
                if(this.urlStateParameters.view != null) {
                    this._view = this.urlStateParameters.view;
                }
            }
            if (this.urlStateParameters.routeId) {
                this._routeId = this.urlStateParameters.routeId;
            }
           // console.log('xxxx clMeterReadings state.. rpsId=' + this._rpsId + '... accountId=' + this._accountId);
        }
    }

    /**
     *
     * @param pageName
     * @todo the nav mix in is buggy with communities and caching.
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
                    routeId: this._routeId,
                    accountId: this._accountId,
                    rpsId: this._rpsId,
                    view: this._view
                }
            });
            //this._disconnectCb = true;
        } catch (e) {
            console.error(e);
        }
    }

    /**
     *
     * @param pageName
     * @todo the nav mix in is buggy with communities and caching.
     */
    navigateBack(pageName) {
        try {
            console.log('attempting to nav to pageName:' + pageName);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName
                }
            });
        } catch (e) {
            console.error(e);
        }
    }
    /*
     * ,
                state: {
                    routeId: this._routeId,
                    accountId: this._accountId,
                    rpsId: this._rpsId,
                    view: this._view
                }
     */

    beforePopStateHandler() {
        console.info('---> before popstate handler.. FORCE SAVE OF DATA!!');
        this.modifyAllMeterReadings(false);
    }

    /**
     * Fires a call to the server to save any form data before a browser reload occurs.
     * @param evt
     */
    beforeUnloadHandler() {
        console.info('---> before unload handler.. FORCE SAVE OF DATA!!');
        this.modifyAllMeterReadings(false,false);
    }

    get imgCompressionRatio() {
        if(this._mdtMeterReadings && this._mdtMeterReadings.Image_Compression_Ratio__c) {
            return this._mdtMeterReadings.Image_Compression_Ratio__c;
        } else {
            return  DEFAULT_IMG_COMPRESSION_RATIO;
        }
    }
    get showImageMetadata () {
        return this._mdtMeterReadings && this._mdtMeterReadings.Display_Image_Metadata__c;
    }
    get cardSecondSubTitle() {
        let value;
        if(this.showRts) {
            //alert(JSON.stringify(this.rpsRecord));
            if (this.rpsRecord && this.rpsRecord.Redemption_Type_From_Asset__c) {
                value = this.labels.lblCardTitleRedemption + ': ' + this.rpsRecord.Redemption_Type_From_Asset__c;
            }
        }
        return value;
    }

    get cardThirdSubTitle() {
        let value = '';
        if (this.rpsRecord && this.rpsRecord.Collection_Type__c) {
            value = this.rpsRecord.Collection_Type__c;
        }
        if (this.rpsRecord && this.rpsRecord.Replenishment_Type__c ) {
            value += ' - '+this.rpsRecord.Replenishment_Type__c;
        }
        return value;
    }
    get showVgts() {
        //-- mts let showIt =  this._machineTypeSelected === RECORD_TYPE_VGT && !this._isMachineTypeSwitch;
        let showIt =  this._machineTypeSelected === RECORD_TYPE_VGT;
        //console.log('----> showVgts='+showIt);
        return showIt;
    }
    get showRts() {
        let showIt = this._machineTypeSelected === RECORD_TYPE_REDEMPTION;
        return showIt;
    }

    /**
     * Roll through MR Wraps. if we find one false (req data not entered).. disable it
     */
    get disableSaveAllButton() {
        return this.meterReadings && this.meterReadings.some( mrWrap => mrWrap.reqDataEntered === false);
    }

    get options() {
        let options;
        options = [
            {
                id: 'skip',
                label: this.labels.lblSkipRouteLinkDesc,
                value: 'Skip',
                prefixIconName: 'utility:skip'
            }
        ];
        if(this.showVgts && this.meterReadings) {
            options.push({id: 'collapseall', label: 'Collapse all readings', value: 'collapseall',prefixIconName: ''});
            options.push({id: 'expandall', label: 'Expand all readings', value: 'expandall',prefixIconName: ''});
        }
        return options;
    }
    get showBackButton() {
        return this._mdtMeterReadings && this._mdtMeterReadings.Show_Back_Button__c;
    }

    /**
     * It was indicated that even if there is no meter data we want to show notes.
     *
     * @return {boolean}
     */
    get showNoData() {
        return !this._isLoading && !this.meterReadings;
    }
    get showMeterReadings() {
        return this.meterReadings && Array.isArray(this.meterReadings) && this.meterReadings.length > 0;
    }

    /**
     *
     * @return {boolean}
     */
    get showSubmitButton() {
        return this.showSurvey || (this.meterReadings && Array.isArray(this.meterReadings) && this.meterReadings.length > 0);
    }
    get disableAddressClick() {
        if(this._mdtMeterReadings && this._mdtMeterReadings.Allow_Address_Click_to_Google_Maps__c) {
            return !this._mdtMeterReadings.Allow_Address_Click_to_Google_Maps__c;
        } else {
            return true;
        }
    }
    get noDataHeaderText() {
        return 'No Meter Readings found!'
    }
    get noDataBodyText(){
        return this._noDataBodyText;
    }
    configCamLauncher(meterReading, showIt) {
        meterReading.showCamLauncher = showIt;
        meterReading.showPicStencil = !showIt;
        console.log('config cam launcher');
    }

    /**
     * register beforeunload and popstate events to handle autosave
     */
    registerWindowEvents() {
        console.log('register window events .. before unload / popstate');
        window.addEventListener('beforeunload', this.beforeUnloadHandler);
        window.addEventListener('popstate', this.beforePopStateHandler);
    }
    /**
     * remove the beforeunload and popstate event handlers.
     */
    removeWindowEvents() {
         console.log('--> remove window event listeners')
         window.removeEventListener('beforeunload',this.beforeUnloadHandler);
         window.removeEventListener('popstate',this.beforePopStateHandler);
    }

    handleCashInMouseout(evt) {

    }
    handleCashInBlur(evt) {
        console.log('---> blur');
        let cashInAmount = evt.detail.value;
        let selectedAssetId = evt.target.dataset.assetid;
        if(selectedAssetId) {
            let meterReading = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);
            if (meterReading) {
                meterReading.lifeTimeCashInAmount = cashInAmount;
                this.modifySingleMeterReading(selectedAssetId);
            }
        }
    }
    handleBackClick() {
        this.modifyAllMeterReadings(false,false);
        this.navigateBack(PAGE_RPS_SHEETS);
    }
    handleButtonToggleClick() {
        let selectedButtonName = evt.target.dataset.button;
        console.log('button='+selectedButtonName);
    }

    handleCollapseExpandClick(evt) {
        this.template.querySelector('.summary-chevron-up').classList.add('accel-section-animation');
    }

    handleVgtCamLauncherClick(evt) {
        evt.preventDefault();
        let selectedAssetId = evt.target.dataset.assetid;
        if(!selectedAssetId) {
            selectedAssetId = evt.target.dataset.id;
        }
        console.log('--> camlauncher click. assetId=', selectedAssetId);
        let meterReading = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);
        meterReading.isLoading = true;
        let cmpCamLauncher = this.template.querySelector('c-ui-camera-launcher[data-assetid="' + selectedAssetId + '"]');
        console.log(cmpCamLauncher);
        cmpCamLauncher.camLauncherClick();

        //this.modifySingleMeterReading(selectedAssetId)
        this.modifyAllMeterReadings(false,false);
    }
    handleMenuSelect(evt) {
        // retrieve the selected item's value
        const selectedItemValue = evt.detail.value;
        if(selectedItemValue == 'collapseall') {
            this.handleCollapseAll(evt);
        } else if (selectedItemValue == 'expandall') {
            this.handleExpandAll(evt);
        } else if (selectedItemValue == 'skip') {
           this.handleSkipSelect(evt);
        }
    }
    handleSkipSelect(evt) {
        this.skipDialogVisible = true;
        this.skipDialogPayload = {};
    }

    /**
     *
     * @param evt
     * @todo fix this it's convoluted!
     */
    handleCashInChange(evt) {
        let cashInAmount = evt.detail.value;
        let selectedAssetId = evt.target.dataset.assetid;
        let selectedMeterId = evt.target.dataset.meterid;
        console.log('---> cash in amt:'+cashInAmount + ' assetId='+selectedAssetId + ' meterId='+selectedMeterId);

        if(selectedAssetId) {
            let meterReading = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);

            if (meterReading) {
                if(cashInAmount) {
                    meterReading.lifeTimeCashInAmount = cashInAmount;
                    if(!meterReading.showImageThumb) {
                        this.configCamLauncher(meterReading, true);
                    } else {
                        meterReading.showPicStencil= false;
                    }
                } else {
                    if(!meterReading.showImageThumb) {
                        this.configCamLauncher(meterReading, true);
                    } else {
                        meterReading.showPicStencil= false;
                    }
                }
               // console.log('---> meterreading selected and modified=',JSON.parse(JSON.stringify(meterReading)));
            }
        }
    }
    handleCannotCollectClick(evt) {
        const checked = evt.target.checked;
        const selectedAssetId = evt.target.dataset.assetid;
        if(selectedAssetId) {
            let meterReading = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);
            if(meterReading) {
                meterReading.cannotCollect = checked;
                //  this.modifySingleMeterReading(selectedAssetId);
                //  5/9/2022 modified from single update to full update.
                //  https://accel-entertainment.monday.com/boards/1300348967/pulses/2647616920
                this.modifyAllMeterReadings(false,false);
            }
        }
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

    handleFileUploaded(evt) {
        let payload = evt.detail;
        console.log('---> file upload payload = ',payload);
        this.modifyAllMeterReadings(false,false);
        refreshApex(this._wiredRpsDto);
        refreshApex(this._wiredMetersDto)
        //this._isLoading = false;
    }

    handleFileReplaceCanceled(evt) {
        refreshApex(this._wiredRpsDto);
        refreshApex(this._wiredMetersDto)
    }

    handleUpdateAll(evt) {
        this._isUiModifyAll = true;
        this._isLoading = true;
        this.modifyAllMeterReadings(true);
    }

    handleDisabledLauncherClick(evt) {
        this.showToast('', 'Please enter lifetime cash in before uploading a picture.','warning');
    }

    handleCardActionMenuClick() {
        this.showToast('Dev Note','Reserved for future use for any card action we want?','info');
    }

    handleSurveyFormSubmitted(evt) {
        //@todo check return result.
        this._isUpdating = false;
        this._isLoading = false;
        console.log('---> survery form submitted successfully');
        if( (!this.meterReadings || this.meterReadings.length < 1) && this._isUiModifyAll) {
            this.showToast('', 'Notes saved successfully', 'success');
        }
        this._isUiModifyAll = false;
    }

    handlePicIconClick(evt) {
        const assetId = evt.currentTarget.dataset.assetid;
        console.log('handing pic icon click ===assetId clicked',assetId);
        let meterReading = this.meterReadings.find(x => x.machineAssetId == assetId);
        console.log('handing pic icon click === meterReading found = ',meterReading);
        if(meterReading) {
            meterReading.showCamLauncher = true;
            meterReading.showImageThumb = false;
            this._selectedAssetId = assetId;
            this._bFindCamLauncher = true;
        }
    }

    /**
     * Event called from child image thumb component upon click. Here we find the current meterreading value
     * stored in the array and tell it to show thecam launcher. (we fire a click upon rerender as it is not yet in the
     * DOM at this point.
     * @param evt
     */
    handleUiImgClick(evt) {
        let meterId = evt.detail.meterId;
        let contentDocumentId = evt.detail.contentDocumentId;
        let contentVersionId = evt.detail.contentVersionId;
        let assetId = evt.detail.assetId;


        let meterReading = this.meterReadings.find(x => x.machineAssetId == assetId);
        console.log('handing ui img click=== meterReading found = ',meterReading);

        if(meterReading) {
            meterReading.showCamLauncher = true;
            meterReading.showImageThumb = false;
            this._selectedAssetId = assetId;
            this._bFindCamLauncher = true;
        }
    }

    handleCamIconClick(evt) {

    }

    /**
     * Evaluates the event detail machineType object. ['VGT','Redemption']
     * If RT. then call modify all to modify all meter readings. If returning back from the RT view to the VGT View
     * we need to force a data refresh to prevent cache from pulling upp but we cannot do it here. we need to
     * do it in the rendered callback.
     *
     * @param evt
     */
    handleMachineTypeSelected(evt) {
        this._isLoading = true;
        let typeSelected = evt.detail.machineType;
        this._machineTypeSelected = typeSelected;

        if (typeSelected != RECORD_TYPE_VGT) {
            this.modifyAllMeterReadings(false, false);
        } else {
            this._forceMetersRefresh = true;
        }
    }


    processImageDeleteClick(evt,promptConfirm){
        let dataset = evt.target.dataset;
        console.log('dataset='+JSON.stringify(dataset));
        console.log('promptConfirm',promptConfirm);
        if(dataset && dataset.docid && dataset.meterid) {
            //const payload = {docId: dataset.docid, meterId: dataset.meterid, actionType: 'deleteDoc'}
            if (promptConfirm) {
                //this.originalMessage = payload;
                //this.isDialogVisible = true;
            } else {
                let meterReadingWrap = this.meterReadings.find(x => x.meterId === dataset.meterid);
                if(meterReadingWrap) {
                    meterReadingWrap.isDeleting = true;
                }
                this.deleteDocument(dataset.docid, dataset.meterid);
            }
        } else {
            this.showToast('', 'Unable to delete image!', 'error');
            console.error('--> dataset=' + JSON.stringify(dataset));
        }
    }
    processDownloadClick(evt) {
        let dataset = evt.target.dataset;
        let meterId = dataset.meterid;
        let dlLink = this.template.querySelector('a[data-meterid="'+meterId+'"]');
        dlLink.click();
        return;
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

    buildFormThemeOverrideCss() {
        let css = '';
        const style = document.createElement('style');
            css += '.accel-input_override .slds-input {width: 100%;display: inline-block;height: 40px!important; ';
            css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
            css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;};';
            css += '.accel-input_override .slds-form-element__label {font-weight:bold!important}';
            css += '.accel-input_override .slds-checkbox .slds-checkbox_faux, .slds-checkbox .slds-checkbox--faux {width:1.5rem!important; height:1.5rem!important}'


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

    get showRtRightHeader() {
        return !this.options && this.showRts && this.rpsRecord && this.rpsRecord.Redemption_Asset__c;
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

    /**
     * Handle the Assign to me confirmation of the assign action.  if confirmed.
     * caLl selectRouteSchedule with selected route schedule id.
     * @param evt
     */
    handleStartVgtModalClick(evt) {
        if(evt.detail !== 1){
            this.confirmDisplayMessage = 'tst message'; // = 'Status: ' + evt.detail.status + '.';
            const detail = evt.detail.originalMessage;
            this.isStartVgtCollectionDialogVisible = false;
            if(evt.detail.status === 'confirm') {
                this.showToast('DEV DEBUG', ' Blah do update of rps here','warning');
                // if(detail.action){
                //     if(detail.action == 'assign') {
                //         if(detail.routeScheduleId) {
                //             this.selectRouteSchedule(detail.routeScheduleId);
                //         }
                //     }
                // }
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.isDialogVisible = false;
    }

    handleDateStartClickAction(evt) {
        this.updateVgtCollectionStartDate();
    }
    handleDateEndClickAction(evt) {
        this.updateVgtCollectionEndDate();
    }
    //===========================
    handleSectionClick(evt) {
        if(this._isAccordionProcessing) //  prevent double click
            return;
        let sectionTitleId = evt.currentTarget.dataset.sectiontitleid;
        if(sectionTitleId) {
            let eleSectionContent = this.template.querySelector("div[data-sectioncontentid="+sectionTitleId+"]");
            let eleSectionArrow = this.template.querySelector("div[data-sectionarrowid="+sectionTitleId+"]");
            console.log(JSON.stringify(eleSectionArrow));
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


    //===========================
    handleCollapseAll(evt) {
        let allSectionContent = this.template.querySelectorAll(".accel-accordion-content");
        let allSectionArrows = this.template.querySelectorAll(".section-arrow");
        let arrAllSectionContent = Array.from(allSectionContent);
        let arrAllSectionArrows = Array.from(allSectionArrows);
        if(arrAllSectionContent && Array.isArray(arrAllSectionContent)) {
            arrAllSectionContent.forEach(( sectionContent, index) => {
                let sectionArrow = arrAllSectionArrows[index];
                if(sectionArrow) {
                    sectionContent.classList.remove('slds-show');
                    sectionContent.classList.add('slds-hide');
                    animationHelper.animateSection(sectionContent,sectionArrow,'close',1000);
                }
            });
        }
    }
    /**
     * This will the RPS VGT Start Collection Button if:
     *
     *   1. A Route_Processing_Sheet__c.Start_VGT_Collection_Date__c is not populated.
     *   2. The checkbox on the custom metadata has been toggled checked
     *      ie. Cash_Logistics_Setting__mdt[Meter_Readings].Show_RPS_Location_Timestamp__c = true.
     *
     * @returns {number|boolean}  Indicating if we should show the VGT Start Collection Msg.
     */
    get showVgtStartCollectionMsg() {
        let showIt;

        let dateNotPopulated = this.rpsRecord && !this.rpsRecord.Start_VGT_Collection_Date__c;
        let mdtShowIt = this._mdtMeterReadings && this._mdtMeterReadings.Show_RPS_Location_Timestamp__c;

        showIt = dateNotPopulated && mdtShowIt;

        return showIt;
    }

    /**
     * This will the RPS VGT End Collection Button if:
     *
     *   1. A Route_Processing_Sheet__c.End_VGT_Collection_Date__c is not populated.
     *   2. Meters are considered 'finished'.
     *   3. The checkbox on the custom metadata has been toggled checked
     *      ie. Cash_Logistics_Setting__mdt[Meter_Readings].Show_RPS_Location_Timestamp__c = true.
     *
     * @returns {number|boolean}  Indicating if we should show the VGT End Collection Msg.
     */
    get showVgtEndCollectionMsg() {
        let showIt;
        if(this.rpsRecord) {
            let dateNotPopulated = this.rpsRecord && !this.rpsRecord.End_VGT_Collection_Date__c;
            let metersFinished = this.rpsRecord
                && (this.rpsRecord.Total_Completed_Meter_Readings__c - this.rpsRecord.Total_Meter_Readings__c == 0);
            let mdtShowIt = this._mdtMeterReadings && this._mdtMeterReadings.Show_RPS_Location_Timestamp__c;

            showIt = mdtShowIt & dateNotPopulated && metersFinished && this.rpsRecord.Status__c !== 'Skipped';

            if (showIt && !this._hasScrolledToTop) {
                try {
                    //  Experimental. scroll to the top but do it only once per page life.
                    window.scrollTo({top: 0, behavior: 'smooth'});
                    this._hasScrolledToTop = true;
                } catch (e) {
                    console.error(e);
                }
            }
        }
        return showIt;
    }

    get startButtonHelpText() {
        let lbl  = 'Please click the button to START your VGT Collection for ';
        return lbl + this.rpsRecord.Account__r.Name +'.';
    }
    get endButtonHelpText() {
        let lbl  = 'Please click the button to END your VGT Collection for ';
        return lbl + this.rpsRecord.Account__r.Name +'.';
    }
    //===========================
    handleExpandAll(evt) {
        let allSectionContent = this.template.querySelectorAll(".accel-accordion-content");
        let allSectionArrows = this.template.querySelectorAll(".section-arrow");
        let arrAllSectionContent = Array.from(allSectionContent);
        let arrAllSectionArrows = Array.from(allSectionArrows);
        if(arrAllSectionContent && Array.isArray(arrAllSectionContent)) {
            arrAllSectionContent.forEach(( sectionContent, index) => {
                let sectionArrow = arrAllSectionArrows[index];
                if(sectionArrow) {
                    sectionContent.classList.remove('slds-hide');
                    sectionContent.classList.add('slds-show');
                    animationHelper.animateSection(sectionContent,sectionArrow,'open',1000);
                }
            });
        }
    }

    /**
     * Handles the skip button click action.
     *
     * If confirmed:
     * 1.  Update the RPS Collection Status to Skipped.
     * 2.  Update all child meter readings (if they exist) to Cannot_Collect__c = true
     *
     * @param evt
     */
    handleSkipConfirmClick(evt) {
        if(evt.detail !== 1){
            this.skipDialogVisible = false;
            if(evt.detail.status === 'confirm') {
                this.updateRpsColStatus('Skipped');
                this.updateMetersToCannotCollect(this.rpsId);
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.skipDialogVisible = false;
    }
}