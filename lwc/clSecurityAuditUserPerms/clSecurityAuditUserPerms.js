import {LightningElement,wire,track,api} from 'lwc';
import {reduceErrors} from 'c/ldsUtils';
import {loadScript} from "lightning/platformResourceLoader";
import CSVPARSER from '@salesforce/resourceUrl/papaparse';
import { getConstants } from 'c/clConstantUtil';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {dtHelper} from "./clSecurityAuditUserPermsDatatableHelper";
import {uiHelper} from "./clSecurityAuditUserPermsUiHelper";
import retrieveUserPermissions from '@salesforce/apex/clSecurityAuditController.retrieveUserPermissions';
import retrieveUserPermissionsByParams   from '@salesforce/apex/clSecurityAuditController.retrieveUserPermissionsByParams';

import lblCardSubtitle from '@salesforce/label/c.CL_Security_User_Audit_Card_Subtitle';
import lblCardTitle from '@salesforce/label/c.CL_Security_User_Audit_Card_Title';
import lblExportButtonTitle from '@salesforce/label/c.CL_Security_User_Audit_Export_Button_Title';
import lblInfoAssistantTitle from '@salesforce/label/c.CL_Security_User_Audit_Info_Assistant_Title';


const   GLOBAL_CONSTANTS             = getConstants();
const   PAPAPARSE_LIBPATH            = '/lib/papaparse.js';
const   MAP_KEY_COL_HEADERS          = 'MAP_KEY_COL_HEADERS';
const   MAP_KEY_USER_PERM_DATA       = 'MAP_KEY_USER_PERM_DATA';
const   MAP_KEY_SECURITY_AUDIT_MDT   = 'MAP_KEY_SECURITY_AUDIT_MDT';
const   ROW_DISPLAY_LIMIT            = 250;
const   DELAY                        = 25;

export default class ClSecurityAuditUserPerms extends LightningElement {

    _wiredUserPermsDto;
    _sObjectApiNames;
    _profileNames;
    _permSetNames;
    _isLoading;
    _parserLoaded;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    @track fieldPermColumns;
    @track userPermData;
    @track filteredData;
    @track summaryData;
    @track summaryColumns;
    @track colHeaders;
    @track csvColHeaders;
    @track csvColData;
    @track securityAuditMdt;
    @track dtData;
    @track sortBy;
    @track sortDirection;
    @track exportFilePermsAssistanceBulletPoints;
    @track exportDatas = [];

    //  parameters
    @track showSearch;
    @track profiles;
    @track permissions;
    @track sObjects;
    @track filterData = {};
    @track filterSelectedValues;
    @track defaultSelections = {};

    labels = {lblCardTitle,lblCardSubtitle,lblExportButtonTitle,lblInfoAssistantTitle};

    constructor() {
        super();
        console.info('%c----> /lwc/clSecurityAuditUserPerms',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this._isLoading = true;
    }

    connectedCallback() {
        this.showDatatableFilters = true;
        this.showSearch = false;
        this.loadParser();
    }

    @wire(retrieveUserPermissions)
    wiredUserPerms(wiredData) {
        this._wiredUserPermsDto = wiredData;
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
            this.userPermData = JSON.parse(JSON.stringify(this._accelUtils.getMapValue(MAP_KEY_USER_PERM_DATA, dtoData)));
            this.generateColHeaders();
            this.generateDatatable();
            this.generateFileAssistanceBulletPoints(this.securityAuditMdt);
            if(this.debugConsole) {
                this.debugServerData();
            }
            this._isLoading = false;
        }
    }

    @wire(retrieveUserPermissionsByParams,{ profileNames: '$profiles', permSetNames:'$permissions'})
    wiredUserPermsByParams(wiredData) {
        this._wiredUserPermsDto = wiredData;
        const {data, error} = wiredData;
        if (error) {
            this.error = reduceErrors(error);
            console.error(this.error);
            this._isLoading = false;
            uiHelper.showToast(this,'Error getting data',this.error,'error');
        } else if (data) {
            const dtoData = JSON.parse(JSON.stringify(data)).values;
            this.securityAuditMdt = this._accelUtils.getMapValue(MAP_KEY_SECURITY_AUDIT_MDT, dtoData);
            this.userPermData = JSON.parse(JSON.stringify(this._accelUtils.getMapValue(MAP_KEY_USER_PERM_DATA, dtoData)));
            this.generateColHeaders();
            this.generateDatatable();
            this.generateFileAssistanceBulletPoints(this.securityAuditMdt);
            this.debugServerData();
            this._isLoading = false;
        }
    }


    generateDefaultFilterSelections() {
        if(this.securityAuditMdt) {
            this.defaultSelections.profiles = this.securityAuditMdt.Profile_Names__c.split(',');
            this.defaultSelections.permSets = this.securityAuditMdt.Permission_Set_Names__c.split(',');
            this.filterData = this.defaultSelections;
            if(this.debugConsole) {
                console.log('---> parent default mdt selections', JSON.parse(JSON.stringify(this.defaultSelections)));
            }
        }
    }

    generateColHeaders() {
        let securityEntityNames;
        if(this.userPermData) {
            securityEntityNames = Object.keys(this.userPermData);
            this.colHeaders = dtHelper.getColHeaders(securityEntityNames);
        }
    }

    /**
     * Lord what a brain tease !
     */
    generateDatatable() {

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

        let userKeys = new Set(recursiveSearch(this.userPermData,'userId'));

        //  Final Flattened Array!
        let resultDatas = [];
        /**
         *  1. Layout templated initial flattened result data. 1 row for all users
         */
        userKeys.forEach((key) => {
            let resultData = {
                userId : key
            }
            resultDatas.push(resultData);
        });
        /**
         *  2. Roll through nested map of objects and flatten out into an array suitable for a datatable / export.
         */
        for (let securityGroup in this.userPermData) {
            let securityGroupApiName = this.formatSecurityEntityName(securityGroup);

            //  Roll through all the metadata fields and apply api name data to the results data
            userKeys.forEach( key => {
                let resultData = resultDatas.find(data => {
                    return data.userId === key;
                });
                resultData[securityGroupApiName] = securityGroupApiName;
            });
            let groupData = this.userPermData[securityGroup];

            //  Roll through all the field data for the security group. assign permission data
            for(let userId in groupData) {
                let user  = groupData[userId];
                let resultData = resultDatas.find(data => {
                    return data.userId === userId
                        && data[securityGroupApiName] === securityGroupApiName;
                });
                resultData.userName = user.userName;
                if(user.hasAccess) {
                    resultData[securityGroupApiName] = user.hasAccess;
                } else {
                    resultData[securityGroupApiName] = null;
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
        if(this.debugConsole) {
            console.log('---> resultDatas', resultDatas);
        }
    }

    executeDefaultSort(resultDatas) {
        //  Sort by Name asc.
        resultDatas.sort((a,b) =>  {
                return a.userName < b.userName ? -1 : 1;
        });
        return resultDatas;
    }

    /**
     * Shape the data so papa parse can export it via seperating the col headers and col data.
     */
    generateExport() {
        if(this.userPermData) {
            let securityEntityNames = Object.keys(this.userPermData);
            let csvColHeaders = [ 'User Name'];

            securityEntityNames.forEach( item => {
                csvColHeaders.push(item);
            })
            let csvDatas = [];
            if(this.dtData) {

                this.dtData.forEach( data => {
                    let tmpData = Object.assign({},data)
                    let csvData = [];
                    csvData.push(tmpData.userName);
                    securityEntityNames.forEach( item =>{
                        let secVal = tmpData[this.formatSecurityEntityName(item)];
                        secVal = secVal ? 'X' : '';
                        csvData.push(secVal);
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

    refireQuery() {
        if(this.filterData) {
            this.profiles = this.filterData.profiles;
            this.permissions = this.filterData.permSets;
            if(this.profiles && this.permissions) {
                this._isLoading = true;
            }
        }
    }

    handleDtSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.filteredData = dtHelper.sortData(this.sortBy, this.sortDirection,this.filteredData);
    }

    handleDtSearchKeyChange(event) {
        //window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        if(searchKey && searchKey.length > 1){
            //this.delayTimeout = setTimeout(() => {
                this.dtLoading = true;
                this.filteredData = this.dtData.filter((item) => {
                    return item['userName'].toLowerCase().includes(searchKey.toLowerCase());
                });
                this.dtLoading = false;
           //}, DELAY);
        } else {
            this.filteredData = this.dtData;
        }
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
                }
            }
            if(this.debugConsole) {
                console.log('--> filterData', JSON.parse(JSON.stringify(this.filterData)));
            }
        }
    }
    get disableRerunButton() {
        let disableIt;
        disableIt = !this.filterData.permSets || !this.filterData.profiles;
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

        let msg = 'Execution settings can be modified by an Admin via Custom Metadata Types / Cash Logistics Security Audit Settings / Manage / User Perm Audit Audit';
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
        return !this._isLoading && this.dtData && this.colHeaders;
    }
    get showAssistance() {
        return this.exportFilePermsAssistanceBulletPoints;
    }
    get showInfoAssistant() {
        return this.securityAuditMdt && this.securityAuditMdt.Show_Info_Assistant__c;
    }
    get debugConsole() {
        return this.securityAuditMdt && this.securityAuditMdt.Debug_Console__c;
    }
    get showCardActions() {
        return this.cardActions && this.cardActions.length > 0;
    }
    get showDtFilters() {
        return this.securityAuditMdt && this.securityAuditMdt.Show_Filters__c && this.showDatatable;
    }
    get maxDtRows() {
        return this.securityAuditMdt && this.securityAuditMdt.Max_Datatable_Rows__c ? this.securityAuditMdt.Max_Datatable_Rows__c : ROW_DISPLAY_LIMIT;
    }
    get dtDataRecords() {
        return this.filteredData;
    }
    get totalServerRows() {
        return this.dtData ? this.dtData.length : 0;
    }

    get totalFilteredRows() {
        return this.filteredData ? this.filteredData.length : 0;
    }

    get showDtSearch() {
        return this.securityAuditMdt && this.securityAuditMdt.Show_Datatable_Search__c && this.showDatatable;
    }
    get cardActions() {
        let actions;
        if(this.showDatatable) {
            actions = [];
            let option1 = {id: 'resetsort', label: 'Reset Sort', value: 'resetsort', prefixIconName: 'utility:sort'};
            let option2;
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
            }
            actions.push(option1);
            if(option2) {
                actions.push(option2);
            }
        }
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
        }
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
        console.log('---> userPermData=', JSON.parse(JSON.stringify(this.userPermData)));
        console.log('---> securityAuditMdt =', JSON.parse(JSON.stringify(this.securityAuditMdt)));
    }
    debugCsvData(){
        console.log('---> csvColHeaders',this.csvColHeaders);
        console.log('---> csvData',this.csvColData);
    }
}