import {LightningElement, track, wire} from 'lwc';
import {uiHelper} from "./clFieldAuditUiHelper";
import {dtHelper} from "./clFieldAuditDatatableHelper";
import {reduceErrors} from 'c/ldsUtils';
import {loadScript} from "lightning/platformResourceLoader";
import CSVPARSER from '@salesforce/resourceUrl/papaparse';
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveFieldHistoryByParams   from '@salesforce/apex/clFieldAuditController.retrieveFieldHistoryByParams';
import retrieveFieldHistoryMdt from '@salesforce/apex/clFieldAuditController.retrieveFieldHistoryMetadata';
import {refreshApex} from "@salesforce/apex";

const   GLOBAL_CONSTANTS             = getConstants();
const   PAPAPARSE_LIBPATH            = '/lib/papaparse.js';
const   MAP_KEY_FIELD_HISTORY_MDT    = 'MAP_KEY_FIELD_HISTORY_MDT';
const   MAP_KEY_FIELD_HISTORY_DATA   = 'MAP_KEY_FIELD_HISTORY_DATA';
const   MDT_FIELD_HISTORY_DEV_NAME   = 'CL_Field_History';
const   ROW_DISPLAY_LIMIT            = 1000;

export default class ClFieldAudit extends LightningElement {

    _wiredFieldHistoryMdtDto;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _isLoading = false;
    _parserLoaded;
    _cacheBust;
    _searchExecuted;
    _mdt_field_history_dev_name =  MDT_FIELD_HISTORY_DEV_NAME;

    @track filterData = {};
    @track filteredHistoryObjects;
    @track infoAssistantBulletPoints;
    @track defaultSelections = {};
    @track toggleValue = true;

    @track mdtFieldHistory;

    @track dtData;
    @track filteredData;
    @track colHeaders;
    @track sortBy;
    @track sortDirection;

    @track csvColHeaders;
    @track csvColData;      //  csv only data regardless of the ui

    constructor() {
        super();
        console.info('%c----> /lwc/clFieldAudit',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.colHeaders = dtHelper.getColHeaders();
        this.loadParser();
    }

    doHistorySearch() {
        let params = {startDate:this.filterData.selectedStartDate,
            endDate:this.filterData.selectedEndDate,
            historyObj:this.filterData.selectedHistObj,
            historyFields:this.filterData.selectedHistFields
        };
        this._isLoading = true;
        this.dtData = null;
        console.log('---> calling history search with params,',params);
        retrieveFieldHistoryByParams(params)
            .then((result) => {
                const dtoData = JSON.parse(JSON.stringify(result)).values;
                this.fieldHistoryData = this._accelUtils.getMapValue(MAP_KEY_FIELD_HISTORY_DATA, dtoData);
                this.generateDatatable();
                this.debugServerData();
                this._isLoading = false;
                this._searchExecuted = true;
            })
            .catch((error) => {
                this.error = reduceErrors(error);
                console.error(this.error);
                this._isLoading = false;
                uiHelper.showToast(this,'Error getting data',this.error,'error');
                this._searchExecuted = true;
            });

    }

    /**
     * Retrieve custom metadata for this component.
     * @param wiredData
     */
    @wire(retrieveFieldHistoryMdt,{ mdtDevName: '$_mdt_field_history_dev_name' })
    wiredFieldHistoryMdt(wiredData) {
        this._wiredFieldHistoryMdtDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            const dtoData = JSON.parse(JSON.stringify(data)).values;
            this.mdtFieldHistory = this._accelUtils.getMapValue(MAP_KEY_FIELD_HISTORY_MDT, dtoData);
            console.log('---> mdt data',JSON.parse(JSON.stringify(data)));
            this.generateDefaultFilterSelections();
            this.generateFileAssistanceBulletPoints(this.mdtFieldHistory);
            this._isLoading = false;
        }
    }

    createCsv() {
        let csv = Papa.unparse( {"fields" : this.csvColHeaders, "data" : this.csvColData});
        return csv;
    }

    /**
     * Shape server data suitable for a datatable adding urls and such. limit the display of server data to the
     * filteredData array.
     */
    generateDatatable() {
        if(this.fieldHistoryData) {
            let newArray = [];
            this.fieldHistoryData.forEach(row => {
                let rowCopy = Object.assign({},row);
                rowCopy.oldValue = rowCopy.oldValue ? rowCopy.oldValue : '';
                rowCopy.newValue = rowCopy.newValue ? rowCopy.newValue : '';
                rowCopy.parentName = rowCopy.parentName ? rowCopy.parentName : '';
                rowCopy.parentUrl = `/${rowCopy.parentId}`;
                rowCopy.userUrl = `/${rowCopy.createdById}`;
                rowCopy.dtKey = rowCopy.fieldId;
                newArray.push(rowCopy);
            });
            newArray = this.executeDefaultSort(newArray);
            this.dtData = newArray;
            this.filteredData = [...this.dtData];
            if(newArray && newArray.length > this.maxDtRows) {
                this.filteredData.length = this.maxDtRows;
                uiHelper.showToast(this,'Info','Displayed data preview limited to ' +this.maxDtRows + ' rows. Click Export details to csv file to view the full result set.','info');
            }
        }
    }

    executeDefaultSort(rows) {
        //  Sort by SObjectLabel asc, Field Label asc.

        rows.sort((a,b) =>  {
            if(a.fieldLabel === b.fieldLabel) {
                return a.createdDate > b.createdDate ? -1 : 1;
            } else  {
                return a.fieldLabel > b.fieldLabel ? -1 : 1;
            }
        });
        return rows;
    }

    generateDefaultFilterSelections() {
        if(this.mdtFieldHistory) {
            this.defaultSelections.filteredHistoryObjects = this.mdtFieldHistory.Field_History_Objects__c.split(',');
            this.filterData = this.defaultSelections;
            if(this.debugConsole) {
                console.log('---> parent default mdt selections', JSON.parse(JSON.stringify(this.defaultSelections)));
            }
        }
    }
    handleButtonClick(event){
        if(event && event.currentTarget && event.currentTarget.dataset) {
            const buttonId = event.currentTarget.dataset.id;
            switch (buttonId) {
                case 'export':
                    try {
                        this.generateExport();
                        let csv = this.createCsv();
                        this.downloadToBrowser(csv);
                    } catch (e) {
                        alert(e);
                    }
                    break;
                case 'runsearch':
                    this.runSearch();
                    break;
            }
        }
    }

    /**
     * The wired method will not get fired if the params are exactly the same.
     */
    runSearch() {
        console.log('----> RUNSEARCH: <------');
        this.debugFilterData();
        if(this.filterData) {
            this.doHistorySearch();
        }
    }

    /**
     * Formats the current date / time and takes the file name prefix from the custom mdt to formulate the filename.
     * Creates a hidden link in the html markup using text/csv and utf-8 as its encoding type as well as
     * calls encodeUriComponent on the csvString.  dynamically append the link the markup and auto click to download
     * the csv.
     *
     * @param csvString
     */
    downloadToBrowser(csvString) {
        try {
            let objName = '';
            if(this.filterData) {
                if(this.filterData.selectedHistObj) {
                    objName = this.filterData.selectedHistObj
                }
            }
            let dFormatter = new Intl.DateTimeFormat('en-US');
            let sDate = dFormatter.format(new Date());
            let fileName = this.mdtFieldHistory.Csv_Export_File_Name_Prefix__c + '_' +objName + '_'+ sDate + '.csv';
            let downloadElement = document.createElement('a');
            downloadElement.href = `data:text/csv;charset=utf-8,${encodeURIComponent(csvString)}`;
            downloadElement.target = '_self';
            downloadElement.download = fileName;
            document.body.appendChild(downloadElement);
            downloadElement.click();
        } catch (e) {
            alert(e);
        }
    }

    handleHistObjSelect(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if (payload) {
                this.filterData.selectedHistObj = payload.historySObjName;
                this.filterData.selectedHistFields = null;

                //this.generateFileAssistanceBulletPoints();
                 this.historyFields = null;
                 this.dtData = null;
                 this._searchExecuted = false;
            }
        }
    }

    handleStartDateChange(evt) {
        console.log('---> start date change handler parent',JSON.parse(JSON.stringify(evt.detail)));
        if(evt.detail) {
            const payload = evt.detail.payload;
            if (payload) {
                this.filterData.selectedStartDate = payload.value;
            }
        }
    }

    handleEndDateChange(evt) {
        console.log('---> end date change handler parent',JSON.parse(JSON.stringify(evt.detail)));
        if(evt.detail) {
            const payload = evt.detail.payload;
            if (payload) {
                this.filterData.selectedEndDate = payload.value;
            }
        }
    }
    /**
     * Process the card menu option selected.
     * @param evt`
     */
    handleCardMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        console.log('card menu select selectedItemValue:',selectedItemValue);
        if(selectedItemValue === 'clearsearch') {
            uiHelper.showToast(this,'','Clear Search not yet functional','info');
            this.filterData = {};
            this.defaultSelections = {};
            this.generateDefaultFilterSelections();
            this.filteredData = null;
            this.dtData = null;
            this.template.querySelector('c-accel-field-history-filters').generateDefaults();
        }
    }
    handleFieldSelect(evt) {
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                switch (evt.detail.name) {
                    case 'histFieldSelect':
                        this.filterData.selectedHistFields = payload.values;
                        break;
                }
            }
        }
    }

    handleFieldRemove(evt) {
        console.log('evt parent field remove',JSON.parse(JSON.stringify(evt.detail)));
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload && payload.optionsRemoved) {
                //if(evt.detail.name === '') {
                    this.filterData.selectedHistFields = this.filterData.selectedHistFields.filter((item) => !payload.optionsRemoved.includes(item));
                //}
            }
            if(this.debugConsole) {
               this.debugFilterData();
            }
        }
    }

    handleDtSearchKeyChange(event) {
        const searchKey = event.target.value;
        if(searchKey && searchKey.length > 1){
            this.dtLoading = true;
            this.filteredData = this.dtData.filter((item) => {
                let newVal = item['newValue'];
                let parentName = item['parentName'];
                let oldVal = item['oldValue'];
                let createdByName = item['createdByName'];
                let field = item['fieldLabel'];
                createdByName = createdByName ? createdByName + '' : '';
                newVal = newVal ? newVal +'' : '';
                oldVal = oldVal ? oldVal +'': '';
                field = field ? field +'': '';
                parentName = parentName ? parentName + '' : '';

                return createdByName.toLowerCase().includes(searchKey.toLowerCase())
                    || newVal.toLowerCase().includes(searchKey.toLowerCase())
                    || oldVal.toLowerCase().includes(searchKey.toLowerCase())
                    || parentName.toLowerCase().includes(searchKey.toLowerCase())
                    || field.toLowerCase().includes(searchKey.toLowerCase())
            });
            this.dtLoading = false;
        } else {
            this.filteredData = this.dtData;
        }
    }
    handleCheckboxToggle(event) {
        this.isRunningUpdate = true;
        event.preventDefault();
        let name = event.target.name;
        let value = event.target.checked;
        this.toggleValue = value;
        this.filterNewRecords();
    }

    filterNewRecords() {
        let showThem  = this.toggleValue;
        this.filteredData = this.dtData.filter((item) => {
            if(!showThem) {
                return item.oldValue !== '[New Record]';
            } else {
                return item;
            }
        });
    }

    handleDtSort(event) {
        this.dtLoading = true;
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.filteredData = dtHelper.sortData(this.sortBy, this.sortDirection,this.filteredData);
        this.dtLoading = false;
    }

    /**
     * Shape the data so papa parse can export it via seperating the col headers and col data.
     */
    generateExport() {
        if(this.dtData) {
            let csvColHeaders = [ 'Parent Record', 'Parent Id','Change Date','Field','Field Api Name','Original Value',
                'New Value','Changed By User Id','Change By User Name'];

            let csvDatas = [];
            if(this.dtData) {
                this.dtData.forEach( data => {
                    let csvData = [];
                    csvData.push(data.parentDisplayLabel);
                    csvData.push(data.parentId);
                    csvData.push(data.createdDate);
                    csvData.push(data.fieldLabel);
                    csvData.push(data.fieldName);
                    csvData.push(data.oldValue);
                    csvData.push(data.newValue);
                    csvData.push(data.createdById);
                    csvData.push(data.createdByName);
                    csvDatas.push(csvData);
                });
            }
            this.csvColHeaders = csvColHeaders;
            this.csvColData = csvDatas;
        }
    }
    generateFileAssistanceBulletPoints(mdt) {
        this.infoAssistantBulletPoints = [];

        let msg = 'Execution settings can be modified by an Admin via Custom Metadata Types / Cash Logistics Security Audit Settings / Manage / CL Field History';
        this.infoAssistantBulletPoints.push({text: msg, severity: 'info'});
        msg = '<b>History Objects Available:</b>  '+mdt.Field_History_Objects__c;
        this.infoAssistantBulletPoints.push({text: msg, severity: 'info'});
        if(!this.filterData.selectedHistObj) {
            msg = 'Select the Object you wish to view history data for';
            this.infoAssistantBulletPoints.push({text: msg, severity: 'info'});
        } else {
            msg = '<span class="slds-text-color_success">';
            msg =  this.filterData.selectedHistObj + ' selected.';
            msg += '</span>';
            this.infoAssistantBulletPoints.push({text: msg, severity: 'info'});
        }
        msg = 'Select the Fields you wish to view history for';
        this.infoAssistantBulletPoints.push({text: msg, severity: 'info'});
        msg = 'Select the Start Date and End Date range for which the values changed.';
        this.infoAssistantBulletPoints.push({text: msg, severity: 'info'});
        msg = 'Click column headers to sort data.';
        this.infoAssistantBulletPoints.push({text: msg, severity: 'info'});
    }
    get dtDataRecords() {
        // return this.showDtSearch ? this.filteredData : this.dtData;
        return this.filteredData;
    }
    get cardActions() {
        let actions;
        actions = [];
        let option1 = {id: 'clearsearch', label: 'Clear Search', value: 'clearsearch', prefixIconName: 'utility:delete'};
        actions.push(option1);
        return actions;
    }

    get showInfoAssistant() {
        return this.mdtFieldHistory && this.mdtFieldHistory.Show_Info_Assistant__c;
    }
    get showAssistance() {
        return this.infoAssistantBulletPoints && !this._isLoading;
    }
    get showDatatable() {
        return this.dtData  && this.totalServerRows > 1;;
    }
    get showProgressBar() {
        return this._isLoading;
    }
    get showStencil() {
        return this._isLoading;
    }
    get totalFilteredRows() {
        return this.filteredData ? this.filteredData.length : 0;
    }
    get debugConsole() {
        return true;
    }

    get totalServerRows() {
        return this.dtData ? this.dtData.length : 0;
    }
    get maxDtRows() {
        return this.mdtFieldHistory  && this.mdtFieldHistory.Max_Datatable_Rows__c ? this.mdtFieldHistory.Max_Datatable_Rows__c : ROW_DISPLAY_LIMIT;
    }
    get showNoData() {
        return !this._isLoading && this._searchExecuted && this.totalServerRows < 1;
    }

    get isLoading() {
        return this._isLoading;
    }

    loadParser() {
        loadScript(this, CSVPARSER + PAPAPARSE_LIBPATH)
            .then(() => {
                console.info('---> papaparser loaded');
                this._parserLoaded = true;
            })
            .catch(error => {
                uiHelper.showToast(this,'Error','Error loading parser '+error,'error');
            })
            .finally(() => {

            });
    }

    get disableSearchButton() {
        console.log('disable method.. filterdata=',JSON.parse(JSON.stringify(this.filterData)));
        return !this.filterData
            || !this.filterData.selectedHistObj
            || !this.filterData.selectedHistFields
            || !this.filterData.selectedStartDate
            || !this.filterData.selectedEndDate;
    }
    debugServerData() {
        console.log('===============   Server Data Debug ====================');
        console.log('---> fieldHistoryData=', JSON.parse(JSON.stringify(this.fieldHistoryData)));
        console.log('---> mdtFieldHistory =', JSON.parse(JSON.stringify(this.mdtFieldHistory)));
        console.log('---> dtData =', JSON.parse(JSON.stringify(this.dtData)));
        console.log('---> filteredData=', JSON.parse(JSON.stringify(this.filteredData)));
    }
    debugFilterData() {
        console.log('--> searchFilterData',JSON.parse(JSON.stringify(this.filterData)));
    }

}