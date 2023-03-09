import {LightningElement, wire, track, api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
import { uiHelper } from 'c/portalAdminUtilsUiHelper'
import Logger from 'c/logger'
import retrievePaAdvisoryState from '@salesforce/apex/PortalAdvisoryLoaderController.retrieveCurrentPaAdvisoryObjectState';
import doUpsertPaRecords from '@salesforce/apex/PortalAdvisoryLoaderController.doUpsertPaRecords';
import {dtHelper} from "./portalAdminUtilsAdvisoryLoaderDtHelper";
import {refreshApex} from "@salesforce/apex";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_PA_ADVISORY_STATE     = 'MAP_KEY_PA_ADVISORY_STATE';
const MAP_KEY_USER_RECORDS          = 'MAP_KEY_USER_RECORDS';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class PortalAdminUtilsAdvisoryLoader extends LightningElement {

    @api timeOut = 10000;
    @api cardTitle = 'PA - Data Loader';
    @api cardSubTitle = 'Load Live REST Data';
    @api customMdtDevName = 'PGCBSelfExclusionService_Prod';
    @api upsertButtonLabel = 'Upsert recs';
    @api showAssistance;
    @api assistanceTitle = 'Loader Assistant'
    @api createdRecordsListViewFilterName;
    @api matchToSfdcReqs;

    @api
    get debugConsole() {
        return this._debugConsole;
    }
    set debugConsole(value) {
        this._debugConsole = value;
        this._logger = new Logger(this._debugConsole);
    }

    @track paAdvisoryState;
    @track paAdvisoryBulletPoints;
    @track userRecords;
    @track filteredUserRecords;
    @track columns = dtHelper.getUserColumns();
    @track dtClasses = dtHelper.getUserDtClasses();
    @track sortDirection = 'desc';
    @track sortBy = 'advisoryDate';
    @track dialogPayload;
    @track showDtFilters = true;
    @track showServerSideSearch = true;

    _wiredStateDto;
    _debugConsole;
    _logger;
    _isLoading;
    _isUpserting;
    _isUpsertSuccess;
    _showProviderError;
    _dtFilter;
    _calloutParams;

    constructor() {
        super();
        console.info('%c----> /lwc/portalAdminUtilsAdvisoryLoader', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.debugConsole = true;
        this.showAssistance = true;
        this.matchToSfdcReqs = true;
    }

    @wire(retrievePaAdvisoryState)
    wiredState(wiredData) {
        this._wiredStateDto = wiredData;
        const {data, error} = wiredData;
        if(data) {
            if(data.isSuccess) {
                this.paAdvisoryState = uiHelper.getMapValue(MAP_KEY_PA_ADVISORY_STATE,data.values);
                this.log(DEBUG,'state-->',this.paAdvisoryState);
                this.generateAssistanceBulletPoints();
            }
        } else if (error) {
            console.error(error);
        }
    }

    /**
     *
     */
    upsertPaRecords() {
        this._isUpserting = true;
        let tmpParams = Object.assign({},this._calloutParams);
        tmpParams.pullImageData = true;
        let params = { calloutParams: tmpParams};
        this.log(DEBUG,'calling upsert with params -->',params);
        doUpsertPaRecords(params)
            .then((result) => {
                if(result.isSuccess) {
                    this.log(DEBUG,'full results dto -->',result);
                    this._serverRecords = uiHelper.getMapValue(MAP_KEY_USER_RECORDS,result.values);
                    this.userRecords = [...this.shapeUserTableData(this._serverRecords)];
                    this.filteredUserRecords = dtHelper.sortData(this.sortBy,this.sortDirection,this.userRecords);
                    refreshApex(this._wiredStateDto);
                    uiHelper.showToast(this,'Upsert Result',result.message,result.severity,'dismissible');
                    this._isUpsertSuccess = true;
                } else {
                    console.error('--> search warn',result);
                    uiHelper.showToast(this,'Upsert Result',result.message,result.severity,'sticky');
                }
            })
            .catch((error) => {
                console.error(error);
                let msg = error.body.exceptionType + ' - ' + error.body.message;
                uiHelper.showToast(this,'Upsert Error!',msg,'error','sticky');
            })
            .finally(() => {
                this._isLoading = false;
                this._isSearching = false;
                this._isUpserting = false;
            });
    }

    handleButtonClick(event){
        if(event && event.currentTarget && event.currentTarget.dataset) {
            const buttonId = event.currentTarget.dataset.id;
            switch (buttonId) {
                case 'upsertrecords':
                    if(this.totalFilteredRows !== this.totalServerRows) {
                        let filteredRowCount = this.totalServerRows - this.totalFilteredRows;
                        let msg = 'You have filtered out '+filteredRowCount +' rows.';
                        msg +=' Upserts will occur on the full superset and not only the filtered rows.';
                        uiHelper.showAlert(msg,'success','Filter warning');
                    }
                    this.upsertPaRecords();
                    break;
            }
        }
    }

    /**
     * Fired by the child search component.
     * @param evt
     */
    handleSearchCompleted(evt) {
        if(evt.detail && evt.detail.success) {
            const searchResults = evt.detail.payload.values;
            this._calloutParams = evt.detail.payload.calloutParams;
            this.log(DEBUG,'---> searchResults',searchResults);
            this._serverRecords = searchResults;
            this.userRecords = this.shapeUserTableData(searchResults);
            this.filteredUserRecords = dtHelper.sortData(this.sortBy,this.sortDirection,this.userRecords);
        } else if (evt.detail && evt.detail.failure) {
            const searchResults = evt.detail.payload.values;
            this._calloutParams = evt.detail.payload.calloutParams;
            this.log(DEBUG,'---> searchResults failed',searchResults);
            this._serverRecords = [];
            this.userRecords = [];
            this.filteredUserRecords = [];
        }
    }

    handleDtSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.filteredUserRecords = dtHelper.sortData(this.sortBy, this.sortDirection,this.filteredUserRecords);
    }

    /**
     * Process the card menu option selected.
     * @param evt`
     */
    handleCardMenuSelect(evt) {
        const selectedItemValue = evt.detail.value;
        this.log(DEBUG,'---> selectedItemValue', selectedItemValue);

        if(selectedItemValue === 'resetsort') {
            //this.filteredData = [...this.executeDefaultSort(this.filteredData)];
        } else if (selectedItemValue === 'showSearch') {
            this.showServerSideSearch = true;
        } else if (selectedItemValue === 'hideSearch') {
            this.showServerSideSearch = false;
        } else if (selectedItemValue === 'showAssist') {
            this.showAssistance = true;
        } else if (selectedItemValue === 'hideAssist') {
            this.showAssistance = false;
        }
    }

    /**
     * @param event
     */
    handleDtSearchKeyChange(event) {
        const searchKey = event.target.value;
        this._dtFilter = searchKey;

        if(searchKey && searchKey.length > 1){
            this.filteredUserRecords = this.userRecords.filter((item) => {
                return item['userName'].toLowerCase().includes(searchKey.toLowerCase());
            });
        } else {
            this.filteredUserRecords = this.userRecords;
        }
    }

    /**
     * Clone records for purposes of sorting and denormalize for datatable usage.
     *
     * @param userRecords
     * @returns {*[]}
     */
    shapeUserTableData(userRecords) {
        let records = [];
        if (userRecords && userRecords.length > 0) {
            let tmp = JSON.parse(JSON.stringify(userRecords));
            tmp.forEach(user => {
                let record = {};
                record.advisoryNumber = user.advisoryNumber;
                if(user.paAdvisory) {
                    record.sfdcName = user.paAdvisory.Name;
                    record.sfdcUrl = '/'+user.paAdvisory.Id;
                }
                record.advisoryDate = user.dAdvisoryDate;
                record.userBirthDate = user.dBirthDate;
                record.userFirstName = user.firstName;
                record.userLastName = user.lastName;
                record.userName = user.firstName ? user.firstName : '';
                record.userName += user.lastName ? ' ' + user.lastName : '';
                record.userCellPhone = user.cellPhoneNumber;
                record.userExclusionPeriod = user.sExclusionPeriod;
                record.viewToolTip = 'View ' + record.userName + ' Details';
                record.docketNumber = user.docketNumber;
                record.advisoryType = user.advisoryType;
                records.push(record);
            });
        }
        console.log('--> shaped data',records);
        return records;
    }

    /**
     * Bullet points for child assistant / help cmp.
     */
    generateAssistanceBulletPoints() {
        this.paAdvisoryBulletPoints = [];
        let msg = '<i>Total Records:</i><b> '+this.paAdvisoryState.totalRecords+'</b>';
        this.paAdvisoryBulletPoints.push({text: msg, severity: 'info'});
        if(this.paAdvisoryState.minAdvisoryDate) {
            msg = '<i>Min Advisory Date Loaded:</i><b> ' + this.paAdvisoryState.minAdvisoryDate + '</b>';
            this.paAdvisoryBulletPoints.push({text: msg, severity: 'info'});
        }
        if(this.paAdvisoryState.maxAdvisoryDate) {
            msg = '<i>Max Advisory Date Loaded:</i><b> ' + this.paAdvisoryState.maxAdvisoryDate + '</b>';
            this.paAdvisoryBulletPoints.push({text: msg, severity: 'info'});
        }
    }

    get cardActions() {
        let actions = [];

            if(this.showServerSideSearch) {
                let option = { id: 'hideSearch', label: 'Hide Search filters', value: 'hideSearch', prefixIconName: 'utility:hide'};
                actions.push(option);
            } else {
                let option = { id: 'showSearch', label: 'Show Search filters', value: 'showSearch', prefixIconName: 'utility:search'};
                actions.push(option);
            }
            if(this.showAssistance) {
                let option = { id: 'hideAssist', label: 'Hide Assistance', value: 'hideAssist', prefixIconName: 'utility:hide'};
                actions.push(option);
            } else {
                let option = { id: 'showAssist', label: 'Show Assistance', value: 'showAssist', prefixIconName: 'utility:search'};
                actions.push(option);
            }

        return actions;
    }

    get paAdvisoryBulletPointCategory() {
        return 'Current State of PA Advisory sObject:';
    }

    get showCardActions() {
        return this.cardActions && this.cardActions.length > 0;
    }

    get showProgressBar() {
        return this._isLoading || this._isUpserting;
    }

    get dtDataRecords() {
        return this.filteredUserRecords;
    }

    get dtKeyField() {
        return 'advisoryNumber';
    }

    get showUserRecords() {
        return !this._isLoading && this.userRecords && this.userRecords.length > 0;
    }

    get disableUpsertButton() {
        return this._isUpserting;
    }

    get totalServerRows() {
        return this.userRecords ? this.userRecords.length : 0;
    }

    get totalFilteredRows() {
        return this.filteredUserRecords ? this.filteredUserRecords.length : 0;
    }

    /**
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger && this.debugConsole) {
            switch (logType) {
                case DEBUG:
                    this._logger.logDebug(msg,obj);
                    break;
                case ERROR:
                    this._logger.logError(msg,obj);
                    break;
                case INFO:
                    this._logger.logInfo(msg,obj);
                    break;
                default:
                    this._logger.log(msg, obj);
            }
        }
    }
}