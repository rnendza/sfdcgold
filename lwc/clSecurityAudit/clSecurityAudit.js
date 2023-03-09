import {LightningElement,wire,track,api} from 'lwc';
import {reduceErrors} from 'c/ldsUtils';
import {loadScript} from "lightning/platformResourceLoader";
import CSVPARSER from '@salesforce/resourceUrl/papaparse';
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {dtHelper} from "./clSecurityAuditDatatableHelper";
import {uiHelper} from "./clSecurityAuditUiHelper";
import retrieveFieldPermissions   from '@salesforce/apex/clSecurityAuditController.retrieveFieldPermissions';
import retrieveFieldPermissionsByParams   from '@salesforce/apex/clSecurityAuditController.retrieveFieldPermissionsByParams';

import lblCardSubtitle from '@salesforce/label/c.CL_Security_Field_Audit_Card_Subtitle';
import lblCardTitle from '@salesforce/label/c.CL_Security_Field_Audit_Card_Title';
import lblExportButtonTitle from '@salesforce/label/c.CL_Security_Field_Audit_Export_Button_Title';
import lblInfoAssistantTitle from '@salesforce/label/c.CL_Security_Field_Audit_Info_Assistant_Title';
import lblFieldDescColHeader from '@salesforce/label/c.CL_Security_Field_Audit_Datatable_FieldDesc_ColHeader';

const   GLOBAL_CONSTANTS             = getConstants();
const   PAPAPARSE_LIBPATH            = '/lib/papaparse.js';
const   MAP_KEY_FIELD_PERM_DATA      = 'MAP_KEY_FIELD_PERM_DATA';
const   MAP_KEY_SECURITY_AUDIT_MDT   = 'MAP_KEY_SECURITY_AUDIT_MDT';
const   ROW_DISPLAY_LIMIT            = 250;
const   DELAY                        = 25;

export default class ClSecurityAudit extends LightningElement {

    _wiredFieldPermDto;
    _sObjectApiNames;
    _profileNames;
    _permSetNames;
    _isLoading;
    _parserLoaded;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    @track fieldPermData;
    @track colHeaders;
    @track csvColHeaders;
    @track csvColData;      //  csv only data regardless of the ui
    @track securityAuditMdt;
    @track dtData;
    @track filteredData;
    @track sortBy;
    @track sortDirection;
    @track exportFilePermsAssistanceBulletPoints;

    //  parameters
    @track showSearch;   //  Server side with multiselect
    @track profiles;
    @track permissions;
    @track sObjects;
    @track filterData = {};
    @track filterSelectedValues;
    @track defaultSelections = {};
    @track dtLoading = false;

    labels = {lblCardTitle,lblCardSubtitle,lblExportButtonTitle,lblInfoAssistantTitle,lblFieldDescColHeader};

    constructor() {
        super();
        console.info('%c----> /lwc/clSecurityAudit',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
    }

    connectedCallback() {
        this.showDatatableFilters = true;
        this.showSearch = false;
        this.loadParser();
    }

    @wire(retrieveFieldPermissions)
    wiredFieldPerms(wiredData) {
        this._wiredFieldPermDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            const dtoData = JSON.parse(JSON.stringify(data)).values;
            this.securityAuditMdt = this._accelUtils.getMapValue(MAP_KEY_SECURITY_AUDIT_MDT, dtoData);
            this.generateDefaultFilterSelections();
            this.fieldPermData = JSON.parse(JSON.stringify(this._accelUtils.getMapValue(MAP_KEY_FIELD_PERM_DATA, dtoData)));
            this.generateColHeaders();
            this.generateDatatable();
            if(this.debugConsole) {
                this.debugServerData();
            }
            this.generateFileAssistanceBulletPoints(this.securityAuditMdt);
            this._isLoading = false;
        }
    }


    @wire(retrieveFieldPermissionsByParams,{ profileNames: '$profiles', permSetNames:'$permissions',sObjectApiNames:'$sObjects'  })
    wiredFieldPermsByParams(wiredData) {
        this._wiredFieldPermDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            const dtoData = JSON.parse(JSON.stringify(data)).values;
            this.securityAuditMdt = this._accelUtils.getMapValue(MAP_KEY_SECURITY_AUDIT_MDT, dtoData);
            this.fieldPermData = this._accelUtils.getMapValue(MAP_KEY_FIELD_PERM_DATA, dtoData);
            this.generateColHeaders();
            this.generateDatatable();
            if(this.debugConsole) {
                this.debugServerData();
            }
            this.generateFileAssistanceBulletPoints(this.securityAuditMdt);
            this._isLoading = false;
        }
    }

    generateDefaultFilterSelections() {
        if(this.securityAuditMdt) {
            this.defaultSelections.profiles = this.securityAuditMdt.Profile_Names__c.split(',');
            this.defaultSelections.permSets = this.securityAuditMdt.Permission_Set_Names__c.split(',');
            this.defaultSelections.sObjects = this.securityAuditMdt.sObject_Api_Names__c.split(',');
            this.filterData = this.defaultSelections;
            if(this.debugConsole) {
                console.log('---> parent default mdt selections', JSON.parse(JSON.stringify(this.defaultSelections)));
            }
        }
    }

    generateColHeaders() {
        let securityEntityNames;
        if(this.fieldPermData) {
            securityEntityNames = Object.keys(this.fieldPermData);
            this.colHeaders = dtHelper.getColHeaders(securityEntityNames,this.securityAuditMdt,this.labels);
        }
    }

    /**
     * @todo this is way too intense.
     */
    generateDatatable() {
        this.dtLoading = true;
        const isObject = (obj) => obj != null && obj.constructor.name === "Object";

        /**
         * Used to find all field keys are we are dealing with nested objects and not an array returned from
         * the server.
         *
         * @param obj
         * @param searchKey
         * @param results
         * @returns {*[]}
         */
        const recursiveSearch = (obj, searchKey, results = []) => {
            const r = results;
            Object.keys(obj).forEach(key => {
                const value = obj[key];
                if(key === searchKey  && !isObject(value)){
                    r.push(value);
                }else if(isObject(value)){
                    recursiveSearch(value, searchKey, r);
                }
            });
            return r;
        };

        let fieldKeys = new Set(recursiveSearch(this.fieldPermData,'fieldKey'));
        //  Final Flattened Array!
        let resultDatas = [];
        /**
         *  1. Layout templated initial flattened result data. 1 row for search sObject / Field.
         */
        fieldKeys.forEach((key) => {
           let sObjApiName = key.split('.')[0];
           let fieldApiName = key.split('.')[1];
           let resultData = {
               sObjApiName : sObjApiName,
               fieldApiName : fieldApiName
           }
           resultDatas.push(resultData);
        });
        let iNumDisplayRows = 0;
        /**
         *  2. Roll through nested map of objects and flatten out into an array suitable for a datatable / export.
         */
        for (let securityGroup in this.fieldPermData) {
            let securityGroupApiName = this.formatSecurityEntityName(securityGroup);

            //  Roll through all the metadata fields and apply api name data to the results data
            //  As well as dynamically add columns based on profile / permission set.
            fieldKeys.forEach( key => {
                let sObjApiName = key.split('.')[0];
                let fieldApiName = key.split('.')[1];
                let resultData = resultDatas.find(data => {
                    return data.sObjApiName === sObjApiName && data.fieldApiName === fieldApiName;
                });
                resultData[securityGroupApiName] = securityGroupApiName;
            });
            let groupData = this.fieldPermData[securityGroup];

            //  Roll through all the field data for the security group. assign permission data
            for(let sObjApiName in groupData) {
                let sObjData = groupData[sObjApiName];

                for (let fieldApiName in sObjData) {
                    let fieldData = sObjData[fieldApiName];
                    let resultData = resultDatas.find(data => {
                        return data.sObjApiName === sObjApiName && data .fieldApiName === fieldApiName
                            && data[securityGroupApiName] === securityGroupApiName;
                    });
                    //  Dynamically add object property according to perm set / profile name.
                    resultData[securityGroupApiName] = fieldData.permissionDisplay;
                    resultData.fieldLabel = fieldData.fieldLabel;
                    resultData.permissionEdit = fieldData.permissionEdit;
                    resultData.permissionRead = fieldData.permissionRead;
                    resultData.fieldDesc = fieldData.fieldDesc ? fieldData.fieldDesc : '[No Description]';
                    resultData.fieldHelp = fieldData.fieldHelpText ? fieldData.fieldHelpText : '[No Help Text]';
                    resultData.sObjLabel = fieldData.sObjLabel;
                    resultData.dtKey = securityGroupApiName + '.' + fieldData.fieldKey;
                }
            }
        }

        this.executeDefaultSort(resultDatas);
        this.dtData = resultDatas;
        this.filteredData = [...this.dtData];
        if(resultDatas && resultDatas.length > this.maxDtRows) {
            this.filteredData.length = this.maxDtRows;
            uiHelper.showToast(this,'Info','Displayed data preview limited to ' +this.maxDtRows + ' rows. Click Export details to csv file to view the full result set.','info');
        }
        this._isLoading = false;
        this.dtLoading = false;
    }

    executeDefaultSort(resultDatas) {
        //  Sort by SObjectLabel asc, Field Label asc.

        resultDatas.sort((a,b) =>  {
            if(a.sObjLabel === b.sObjLabel) {
                return a.fieldLabel < b.fieldLabel ? -1 : 1;
            } else  {
                return a.sObjLabel < b.sObjLabel ? -1 : 1;
            }
        });
        return resultDatas;
    }

    /**
     * Shape the data so papa parse can export it via seperating the col headers and col data.
     */
    generateExport() {
        if(this.fieldPermData) {
            let securityEntityNames = Object.keys(this.fieldPermData);

            let csvColHeaders = [ 'Object Name', 'Field Name'];
            if(this.securityAuditMdt && this.securityAuditMdt.Show_Field_Description__c) {
                let lblFieldDesc = this.labels.lblFieldDescColHeader ? this.labels.lblFieldDescColHeader : ' ';
                csvColHeaders.push(lblFieldDesc)
            }

            securityEntityNames.forEach( item => {
                csvColHeaders.push(item);
            })
            let csvDatas = [];
            if(this.dtData) {
                this.dtData.forEach( data => {
                    let csvData = [];
                   csvData.push(data.sObjLabel);
                   csvData.push(data.fieldLabel);
                    if(this.securityAuditMdt && this.securityAuditMdt.Show_Field_Description__c) {
                        csvData.push(data.fieldDesc);
                    }
                   securityEntityNames.forEach( item =>{
                        csvData.push(data[this.formatSecurityEntityName(item)]);
                    });
                   csvDatas.push(csvData);
                });
            }
            this.csvColHeaders = csvColHeaders;
            this.csvColData = csvDatas;
            if(this.debugConsole) {
                this.debugCsvData();
            }
        }
    }

    formatSecurityEntityName(name) {
        return name ?  name.replaceAll(' ','_') : null;
    }

    handleButtonClick(event){
        if(event && event.currentTarget && event.currentTarget.dataset) {
            const buttonId = event.currentTarget.dataset.id;
            switch (buttonId) {
                case 'export':
                    this.generateExport();
                    let csv = this.createCsv();
                    this.downloadToBrowser(csv);
                    break;
                case 'rerunquery':
                    this.refireQuery();
                    break;
            }
        }
    }

    /**
     * The wired method will not get fired if the params are exactly the same.
     */
    refireQuery() {
         if(this.filterData) {
             let sameParams = false;
             if(JSON.stringify(this.profiles) === JSON.stringify(this.filterData.profiles)
                 && JSON.stringify(this.permissions) === JSON.stringify(this.filterData.permSets)
                 && JSON.stringify(this.sObjects) === JSON.stringify(this.filterData.sObjects)) {
                 sameParams = true;
             }
             this.profiles = this.filterData.profiles;
             this.permissions = this.filterData.permSets;
             this.sObjects = this.filterData.sObjects;
             if(this.profiles && this.permissions && this.sObjects) {
                 if(!sameParams) {
                     this._isLoading = true;
                 } else {
                     uiHelper.showToast(this,'','Please change your search filters to Rerun the Query','info');
                 }
             }
         }
     }

    handleDtSort(event) {
        this.dtLoading = true;
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.filteredData = dtHelper.sortData(this.sortBy, this.sortDirection,this.filteredData);
        this.dtLoading = false;
    }

    handleFilterSelect(evt) {
        if(this.debugConsole) {
            console.log('evt select', JSON.parse(JSON.stringify(evt.detail)));
        }
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload) {
                switch (evt.detail.name) {
                    case 'profileSelect':
                        this.filterData.profiles = payload.values;
                        break;
                    case 'permsetSelect':
                        this.filterData.permSets = payload.values;
                        break;
                    case 'sobjectSelect':
                        this.filterData.sObjects = payload.values;
                        break;
                }
            }
            if(this.debugConsole) {
                console.log('--> filterData', JSON.parse(JSON.stringify(this.filterData)));
            }
        }
    }

    handleFilterRemove(evt) {
        //console.log('evt select',JSON.parse(JSON.stringify(evt.detail)));
        if(evt.detail) {
            const payload = evt.detail.payload;
            if(payload && payload.optionsRemoved) {
                switch (evt.detail.name) {
                    case 'profileSelect':
                        this.filterData.profiles = this.filterData.profiles.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                    case 'permsetSelect':
                        this.filterData.permSets = this.filterData.permSets.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                    case 'sobjectSelect':
                        this.filterData.sObjects = this.filterData.sObjects.filter((item) => !payload.optionsRemoved.includes(item));
                        break;
                }
            }
            if(this.debugConsole) {
                console.log('--> filterData', JSON.parse(JSON.stringify(this.filterData)));
            }
        }
    }

    handleDtSearchKeyChange(event) {
        //window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        if(searchKey && searchKey.length > 1){
           // this.delayTimeout = setTimeout(() => {
                this.dtLoading = true;
                this.filteredData = this.dtData.filter((item) => {
                    return item['sObjLabel'].toLowerCase().includes(searchKey.toLowerCase())
                        || item['fieldLabel'].toLowerCase().includes(searchKey.toLowerCase());
                });
                this.dtLoading = false;
           // }, DELAY);
        } else {
            this.filteredData = this.dtData;
        }
    }

    get dtDataRecords() {
      // return this.showDtSearch ? this.filteredData : this.dtData;
        return this.filteredData;
    }

    get disableRerunButton() {
        let disableIt;
        disableIt = !this.filterData.permSets || !this.filterData.profiles || !this.filterData.sObjects;
        return disableIt;
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

        let dFormatter = new Intl.DateTimeFormat('en-US');
        let sDate = dFormatter.format(new Date());
        let fileName = this.securityAuditMdt.Csv_Export_File_Name_Prefix__c + '_'+sDate + '.csv';
        let downloadElement = document.createElement('a');
        downloadElement.href = `data:text/csv;charset=utf-8,${encodeURIComponent(csvString)}`;
        downloadElement.target = '_self';
        downloadElement.download = fileName;
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    createCsv() {
        let csv = Papa.unparse( {
            "fields" : this.csvColHeaders,
            "data" : this.csvColData
        });
        return csv;
    }

    generateFileAssistanceBulletPoints(securityAuditMdt) {
        this.exportFilePermsAssistanceBulletPoints = [];

        let msg = 'Execution settings can be modified by an Admin via Custom Metadata Types / Cash Logistics Security Audit Settings / Manage / Field Audit';
        this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
        msg = '<b>SObject Api Names:</b>  '+securityAuditMdt.sObject_Api_Names__c;
        this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
        msg = '<b>Profile Names:</b>  '+securityAuditMdt.Profile_Names__c;
        this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
        msg = '<b>Permission Set Api Names:</b>  '+securityAuditMdt.Permission_Set_Names__c;
        this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
        msg = 'Click column headers to sort data.';
        this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
        if(this.showDtFilters) {
            msg = 'Display search filters via the top right settings menu.';
            this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
        }
        if(this.showDtSearch) {
            msg = 'You can use the search box to further filter your results.';
            this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
        }
        msg = 'Reset the sort via the top right settings menu.';
        this.exportFilePermsAssistanceBulletPoints.push({text: msg, severity: 'info'});
    }

    get showStencil() {
        return this._isLoading;
    }
    get showProgressBar() {
        return this._isLoading;
    }
    get showDatatable() {
        return !this._isLoading && this.dtDataRecords && this.totalServerRows > 0 && this.colHeaders;
    }
    get showAssistance() {
        return this.exportFilePermsAssistanceBulletPoints && !this._isLoading;
    }
    get showCardActions() {
        return this.cardActions && this.cardActions.length > 0;
    }
    get showDtFilters() {
        return this.securityAuditMdt && this.securityAuditMdt.Show_Filters__c;
    }
    get totalServerRows() {
        return this.dtData ? this.dtData.length : 0;
    }

    get totalFilteredRows() {
        return this.filteredData ? this.filteredData.length : 0;
    }
    get debugConsole() {
        //return this.securityAuditMdt && this.securityAuditMdt.Debug_Console__c;
        return true;
    }
    get showDtSearch() {
        return this.securityAuditMdt && this.securityAuditMdt.Show_Datatable_Search__c && !this._isLoading;
    }
    get showInfoAssistant() {
        return this.securityAuditMdt && this.securityAuditMdt.Show_Info_Assistant__c;
    }

    get maxDtRows() {
        return this.securityAuditMdt && this.securityAuditMdt.Max_Datatable_Rows__c ? this.securityAuditMdt.Max_Datatable_Rows__c : ROW_DISPLAY_LIMIT;
    }

    get showNoData() {
        return !this._isLoading && this.totalServerRows < 1;
    }

    get cardActions() {
        let actions;
        //if(this.showDatatable) {
            actions = [];
            let option1 = {id: 'resetsort', label: 'Reset Sort', value: 'resetsort', prefixIconName: 'utility:sort'};
            let option2;
            let option3;
            if(this.showDtFilters) {
                if(this.showSearch) {
                    option2 = {
                        id: 'hideSearch',
                        label: 'Hide Search filters',
                        value: 'hideSearch',
                        prefixIconName: 'utility:hide'
                    };
                } else {
                    option2 = {
                        id: 'showSearch',
                        label: 'Show Search filters',
                        value: 'showSearch',
                        prefixIconName: 'utility:search'
                    };
                }
                option3 = {
                    id: 'resetSearch',
                    label: 'Reset Search',
                    value: 'resetSearch',
                    prefixIconName: 'utility:undo'
                };
            }
            actions.push(option1);
            if(option2) {
                actions.push(option2);
                actions.push(option3);
            }
       // }
        return actions;
    }

    /**
     * Process the card menu option selected.
     * @param evt`
     */
    handleCardMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        if(this.debugConsole) {
            console.log('---> selectedItemValue', selectedItemValue);
        }
        if(selectedItemValue === 'resetsort') {
           this.filteredData = [...this.executeDefaultSort(this.filteredData)];
        } else if (selectedItemValue === 'showSearch') {
            this.showSearch = true;
        } else if (selectedItemValue === 'hideSearch') {
            this.showSearch = false;
        } else if (selectedItemValue === 'resetSearch') {
            this.generateDefaultFilterSelections();
            this.refireQuery();
        }
    }


    resetSearch() {

    }
    handleSearchFiltersClose(evt) {
        this.showSearch = false;
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

    debugServerData() {
        console.log('---> fieldPermData1=', JSON.parse(JSON.stringify(this.fieldPermData)));
        console.log('---> securityAuditMdt1 =', JSON.parse(JSON.stringify(this.securityAuditMdt)));
        console.log('---> dtData =', JSON.parse(JSON.stringify(this.dtData)));
        console.log('---> filteredData=', JSON.parse(JSON.stringify(this.filteredData)));
    }
    debugCsvData(){
        console.log('---> csvColHeaders',JSON.parse(JSON.stringify(this.csvColHeaders)));
        console.log('---> csvData',JSON.parse(JSON.stringify(this.csvColData)));
    }
}