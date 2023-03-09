import {LightningElement, api, track, wire} from 'lwc';
import retrieveMeterReadings   from '@salesforce/apex/clMeterReadingsController.retrieveRpsMeterReadingsForProcessor';
import retrieveRpsData   from '@salesforce/apex/clMeterReadingsController.retrieveRouteProcessingSheet';
import updateProcessorMeterReadings   from '@salesforce/apex/clMeterReadingsController.updateProcessorMeterReadings';
import retrieveMdt   from '@salesforce/apex/clPublicController.retrieveMdt';
import AccelUtilsSvc from "c/accelUtilsSvc";
import {reduceErrors} from "c/ldsUtils";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {themeOverrider} from "./clRpsActualDropVgtThemeOverrides";
import {animationHelper} from "./clRpsActualDropVgtAnimation";
import {refreshApex} from "@salesforce/apex";
import { getConstants } from 'c/clConstantUtil';

const MAP_KEY_METERS_DATA = 'METER_READING_WRAPS';  //  A meter readings for the rps.
const MAP_KEY_RPS_DATA = 'ROUTE_PROCESSING_SHEET_DATA';
const MAP_KEY_MDT_RECORD = 'MDT_RECORD';
const MDT_DEV_NAME = 'Meter_Readings';
const RECORD_TYPE_VGT = 'VGT';

import MR_ID_FIELD from '@salesforce/schema/Meter_Reading__c.Id';
import MR_ACTUAL_DROP_FIELD from '@salesforce/schema/Meter_Reading__c.Actual_Drop__c';
import RPS_BV_DROP_TOTAL_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.BV_Drop_Total__c';
import RPS_ID_FIELD from '@salesforce/schema/Route_Processing_Sheet__c.Id';

const GLOBAL_CONSTANTS = getConstants();


export default class ClRpsActualDropVgt extends LightningElement {

    @api rpsId;
    @api
    set machineTypeCollapseValue(val) {
        this._machineTypeCollapseValue = val;
    }
    get machineTypeCollapseValue() {
        return this._machineTypeCollapseValue;
    }

    @track meterReadings;
    @track rpsRecord;
    @track currentPageReference = null;
    @track urlStateParameters = null;
    @track uiErrorMsg = {};
    @track bvValue;
    @track actualTotal = 0;

    _machineTypeCollapseValue;
    _wiredPageMdt;
    _wiredMetersDto
    _wiredRpsDto;
    _mdtMeterReadings;
    _hasOverrodeTheme = false;
    _pageMdtDevName = MDT_DEV_NAME;
    _machineTypeSelected = RECORD_TYPE_VGT;
    _noDataBodyText;
    _isLoading = false;
    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _isUpdating;
    _grandTotalArray;
    _allNoteCountGrandTotal;

    constructor() {
        super();
        console.info('%c----> /lwc/clRpsActualDropVgt',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {

    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
        }
        this.overrideThemes();
    }

    @wire(retrieveRpsData, {rpsId: '$rpsId'})
    retrieveRps(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const { data, error } = this._wiredRpsDto;
        if(data) {
            const dto = data;
            if(dto.isSuccess) {
                this.rpsRecord = this._accelUtils.getMapValue(MAP_KEY_RPS_DATA, dto.values);
                this.bvValue = this.rpsRecord && this.rpsRecord.BV_Drop_Total__c ? this.rpsRecord.BV_Drop_Total__c : null;
            } else {
                //this.uiErrorMsg.body = dto.message;
            }
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving rps data: '+this.error,'error');
        }
    }

    @wire(retrieveMeterReadings, {rpsId: '$rpsId',assetRecordType:'$_machineTypeSelected'})
    retrieveMeterData(wiredDto) {
        this._wiredMetersDto = wiredDto;
        const { data, error } = this._wiredMetersDto;
        if(data) {
            //this.forceThemeOverrides();
            if(data.isSuccess) {
                let tmpReadings =  [...this._accelUtils.getMapValue(MAP_KEY_METERS_DATA, data.values)];
                this.meterReadings = tmpReadings.map(element => Object.assign({},element));
                this.meterReadings.forEach((meterWrap) => {
                    if(meterWrap.actualDrop == 0) {
                        meterWrap.actualDrop = null;
                    }
                });
                if(!this.disableSaveAllButton) {
                    this.buildVgtTotal();
                }

                //console.log('---> meter readings',JSON.parse(JSON.stringify(this.meterReadings)));
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
    wiredMdt(wiredData) {
        this._wiredPageMdt = wiredData;
        const { data, error } = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
        } else if (data) {
            this._mdtMeterReadings = this._accelUtils.getMapValue(MAP_KEY_MDT_RECORD, data.values);
        }
    }

    overrideThemes() {
        if(!this._hasOverrodeTheme) {
            this.buildFormThemeOverrideCss();
        }
        if(!this._hasOverrodeSfdcCss) {
            this.buildSfdcCoreOverrideCss();
        }
    }

    get showStencil() {
        return !this.showMeterReadings;
    }
    get showMeterReadings() {
        return !this._isLoading && this.meterReadings && !this._isUpdating;
    }

    /**
     *
     * @return {boolean}
     * @todo either formula field with header total on rps or make this more concise!
     */
    get disableSaveAllButton() {
        let disableIt = false;
        if(this.meterReadings) {
            let anyMissing = false;
            this.meterReadings.forEach((meterWrap) => {
                if(!meterWrap.actualDrop) {
                    anyMissing = true;
                }
            });
            disableIt = anyMissing;
        }
        return disableIt;
    }

    handleActualDropBlur(evt) {
        // let actualDrop = evt.detail.value;
        // let selectedAssetId = evt.target.dataset.assetid;
        // if(selectedAssetId) {
        //     let meterReading = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);
        //
        //     if (meterReading) {
        //         // if(actualDrop) {
        //         //     meterReading.actualDrop = actualDrop;
        //         // }
        //         let tmpTotal = 0;
        //         this.meterReadings.forEach((meterWrap) => {
        //             if(meterWrap.actualDrop) {
        //                 tmpTotal += meterReading.actualDrop;
        //             }
        //         });
        //         this.actualTotal = tmpTotal;
        //         console.log(this.actualTotal);
        //     }
        // }
    }
    /**
     *
     * @param evt
     * @todo fix this it's convoluted!
     */
    handleActualDropChange(evt) {
        let actualDrop = evt.detail.value;
        let selectedAssetId = evt.target.dataset.assetid;
        let selectedMeterId = evt.target.dataset.meterid;
        if(selectedAssetId) {
            let meterReading = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);

            if (meterReading) {
                meterReading.actualDrop = actualDrop;
                this.buildVgtTotal();
                // if (actualDrop) {
                //     meterReading.actualDrop = actualDrop;
                // }
            }
        }
    }

    /**
     *
     * @param evt
     * @todo fix this it's convoluted!
     */
    handleActualDropFocusOut(evt) {
        console.log('focus out');
        let actualDrop = evt.detail.value;
        let selectedAssetId = evt.target.dataset.assetid;
        let selectedMeterId = evt.target.dataset.meterid;
        if(selectedAssetId) {
            let meterReading = this.meterReadings.find(x => x.machineAssetId === selectedAssetId);

            if (meterReading) {
                if (actualDrop) {
                    meterReading.actualDrop = actualDrop;
                }
            }
        }
    }
    handleGrandTotalFieldChanged(evt) {
        if(evt && evt.detail && evt.detail.fieldArray) {
            this._grandTotalArray = evt.detail.fieldArray;
            this.buildAllNoteCountGrandTotal()
        }
    }
    /**
     *
     * @param evt
     * @todo fix this it's convoluted!
     */
    handleBvChange(evt) {
        this.bvValue = evt.detail.value;
        this.buildVgtTotal();
    }
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
    handleUpdateAll(evt) {

        // this._isUiModifyAll = true;
        // this._isLoading = true;
        if(this.doesGrandTotalMatch()) {
            this.modifyAllMeterReadings(true);
        }
    }
    handleChildFormSubmit() {
        try {
            this.template.querySelector('c-cl-cash-can-totals').triggerSaveEvent();
            console.log('trigger save');
        } catch (e) {
            console.error(e);
        }
    }

    /**
     * Simulate the Server Side Formula Field to calc the note count grand total.
     *
     * (X1_Note_Count_Grand_Total__c * 1)
     * + (X5_Note_Count_Grand_Total__c * 5)
     * + (X10_Note_Count_Grand_Total__c * 10)
     * + (X20_Note_Count_Grand_Total__c * 20)
     * + (X50_Note_Count_Grand_Total__c * 50)
     * + (X100_Note_Count_Grand_Total__c * 100)
     */
    buildAllNoteCountGrandTotal() {
        let total = 0;
        this._grandTotalArray.forEach( noteCount => {
            total+= ( noteCount.fieldValue * noteCount.multiplier);
        });
        this._allNoteCountGrandTotal = total;
        console.log('---> all note count total',this._allNoteCountGrandTotal);
    }

    buildVgtTotal() {
        let tmpTotal = Number(0);
        this.meterReadings.forEach((meterWrap) => {
            if (meterWrap.actualDrop) {
                tmpTotal += Number(meterWrap.actualDrop);
            }
        });
        this.actualTotal = tmpTotal;
        if(this.bvValue) {
            this.actualTotal += Number(this.bvValue);
        }
    }

    modifyAllMeterReadings(bShowUpdate) {
        this.buildVgtTotal();
        let meterReadingSObjects = [];
        let rpsSObject = {
            [RPS_ID_FIELD.fieldApiName] : this.rpsId,
            [RPS_BV_DROP_TOTAL_FIELD.fieldApiName] : this.bvValue
        };
        if(!this.meterReadings || this.meterReadings.length < 1) {
            console.warn('no meterradings existing modify all');
            this._isLoading = false;
            return;
        }
        this.meterReadings.forEach((meterWrap) => {
            let meterReadingSObject = {
                [MR_ID_FIELD.fieldApiName] : meterWrap.meterId,
                [MR_ACTUAL_DROP_FIELD.fieldApiName] : meterWrap.actualDrop
            };
            meterReadingSObjects.push(meterReadingSObject);
        });
        let params = { meterReadings: meterReadingSObjects,routeProcessingSheet : rpsSObject };
        //console.log('----> calling update to meterreadings with params',params);
        this.handleChildFormSubmit();
    //    this.showToast('DEVELOPER MESSSAGE','This feature is in progress and not yet saving the data..Check the console for param object that will be sent to the server.','info');
        if(bShowUpdate) {
            this._isUpdating = true;
        }
        //console.log('---> calling update with params:',params)
        updateProcessorMeterReadings( params )
            .then(dto => {
                this._isUpdating = false;
                //console.log('--> returned dto='+JSON.stringify(dto));

                if (dto.isSuccess) {
                    if(bShowUpdate) {
                        this.refreshAllWireds();
                        this.showToast('', dto.message, 'success');
                    }
                    this._isLoading = false;
                } else {
                    this._isLoading = false;
                    console.log(' error in update' + JSON.stringify(dto));
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                this._isUpdating = false;
                this._isLoading = false;
                this.error = reduceErrors(error);
                this.showToast('', 'Data could not be updated: ' + this.error,'error');
                console.error(this.error);
            });
    }
    refreshAllWireds() {
        refreshApex(this._wiredMetersDto)
            .then(() => {
                refreshApex(this._wiredRpsDto)
                    .then(() => {
                        this._isUpdating = false;
                        //console.log('all wireds updated');
                        //console.log('rps record='+JSON.stringify(this.rpsRecord));
                       // this.performTotalMismatchPrompt();
                    })
                    .catch( error => {
                        console.error('error refresing',error);
                        this._isUpdating = false;
                    });
            })
            .catch( error => {
                console.error('error refresing',error);
                this._isUpdating = false
            });
    }

    /**
     * If the actual vgt total is not equal to the grand (value total) of the note count, fire a toast.
     *
     *
     * @see CL27 https://accel-entertainment.monday.com/boards/1300348967/pulses/1739568973?term=total
     * @todo what to do with BV value.
     * @todo what is the verbiage desired in the prompt?
     */
    performTotalMismatchPrompt() {

        const vgtDropTotal = this.actualTotal;
        const allGrandTotal = this.rpsRecord.All_Note_Count_Grand_Total__c;

        if(vgtDropTotal !== allGrandTotal) {
            this.showToast('','The Grand Total Note Count of '+allGrandTotal
                +' does not match the VGT Drop Total of '+vgtDropTotal+ '. Data is not saved!','error','');
        }
    }

    /**
     * Does the Drop Total Match the Note Count Grand Total?
     *   1. Yes ->  return true and continue with server side save.
     *   2. No  ->  return false, block server side save and prompt a toast.
     *   
     * @returns {boolean}
     */
    doesGrandTotalMatch() {
        let doesIt = false;
        this.buildVgtTotal();
        if(this.actualTotal === this._allNoteCountGrandTotal) {
            doesIt = true;
        } else {
            this.showToast('','The Grand Total Note Count of '+this._allNoteCountGrandTotal
                +' does not match the VGT Drop Total of '+this.actualTotal + '. Data is Not Saved!','error');
        }
        return doesIt;
    }

    /**
     *
     * @param title
     * @param msg
     * @param variant
     */
    showToast(title, msg, variant,mode) {
        if(!mode) {
            mode = 'dismissable';
        }
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
    buildFormThemeOverrideCss() {
        let css = '';
        const style = document.createElement('style');
        // css += '.accel-input_override .slds-input {width: 100%;display: inline-block;height: 40px!important; ';
        // css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
        // css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;};';
        css += '.accel-input_override .slds-form-element__label {font-weight:bold!important}';


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

}