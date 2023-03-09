import {LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {getConstants} from "c/clConstantUtil";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveRelatedFiles from '@salesforce/apex/clRelatedFiles.retrieveRelatedFiles';
import retrievePermissions from '@salesforce/apex/clRelatedFiles.retrievePermissions';
import deleteRelatedFile from '@salesforce/apex/clRelatedFiles.deleteRelatedFile';
import {reduceErrors} from "c/ldsUtils";
import {uiHelper} from "./clImportHistoryUiHelper";
import {dtHelper} from "./clImportHistoryDatatableHelper";


const  GLOBAL_CONSTANTS = getConstants();
const  ROUTE_IMPORT_UPLOAD_TYPE = 'Route Import Success Log';
const  MAP_KEY_RELATED_FILES = 'RELATED_FILES';
const MAP_KEY_PL_OPTIONS_FILE_CREATED_BY = 'PL_OPTIONS_FILE_CREATED_BY';
const MAP_KEY_PL_OPTIONS_UPLOAD_STATUS = 'PL_OPTIONS_UPLOAD_STATUS';
const MAP_KEY_PERMISSIONS = 'PERMISSIONS';
const MAP_KEY_DELETE_FILE = 'DELETE_FILE';
const relatedFilesColumns = dtHelper.getFilesDtColumns();

/**
 *  We have to do some tricks here as tabs are lazy loaded so we need to constantly refresh
 *  on tab click but this cmp is not available util a few seconds after tab click
 *  so we need to constantly try to force refreshes via the refreshDummy reactive variable.
 */
export default class ClImportHistory extends NavigationMixin(LightningElement) {
    _needsRefresh;
    _routeImportRecordId;

    @api
    set routeImportRecordId(val) {
        this._routeImportRecordId = val;
        console.info('in setting routeImport Record val ',val);
        if(this._routeImportRecordId) {
            if(this._needsRefresh) {
                this.doRetrieveFiles();
                this._needsRefresh = false;
            }
        }
    }
    get routeImportRecordId () {
        return this._routeImportRecordId;
    }
    @api
    set refreshDummy(val) {
        this._refreshDummy = val;
        if(this._refreshDummy) {
            console.info('in refresh dummy setter1..');
            if(this._routeImportRecordId) {
                this.doRetrieveFiles();
            } else {
                this._needsRefresh = true;
            }
        }
    }
    get refreshDummy() {
        return this._refreshDummy;
    }
    @api
    set customPermissions(val) {
        let test = {action: "delete", name: "CL_Delete_Route_Import_Files", enabled:false};
        let tests = [];
        tests.push(test);
        this._permissions = tests;
        this.doRetrievePerms();
    }
    get customPermissions() {
        return this._permissions;
    }

    @track allFilesData;
    @track filteredFilesData;
    @track filesCreatedByPlOptions;
    @track filesUploadStatusPlOptions;
    @track filesColumns = relatedFilesColumns;
    @track isActionDialogVisible;
    @track isPublisherDialogVisible;
    @track dialogPayload;
    @track confirmLabel;
    @track confirmTitle;
    @track confirmDisplayMessage;
    @track confirmIcon = 'standard:question_feed'
    @track confirmIconSize = 'small';
    @track historyAssistanceBulletPoints;

    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _isLoading;
    _isProcessing;
    _permissions;
    _customPermissions;
    _refreshDummy;

    constructor() {
        super();
        console.info('%c----> /lwc/clImportHistory',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this.customPermissions = 'bogus';
    }

    connectedCallback() {
        this.doRetrieveFiles();
    }

    doRetrieveFiles() {
        console.info('----> running retrieve history files');
        this._isLoading = true;
        const params = {recordId: this._routeImportRecordId, uploadType : ROUTE_IMPORT_UPLOAD_TYPE};

        retrieveRelatedFiles(params)
            .then(dto => {
                if(dto.isSuccess) {
                    this.historyAssistanceBulletPoints = [];
                    this.historyAssistanceBulletPoints.push({text: 'The below shows the results of your route imports'});

                    this.allFilesData = this._accelUtils.getMapValue(MAP_KEY_RELATED_FILES, dto.values);
                    let data = [...this.allFilesData];
                    this.filteredFilesData = this.allFilesData.map( row => {
                        let newRow = {...row};
                        newRow.fileLinkName = row.fileDownloadUrl;
                        row.icon = 'doctype:csv';
                        return newRow;
                    });

                    //this.filteredFilesData = [...this.allFilesData];
                    this.filesCreatedByPlOptions = this._accelUtils.getMapValue(MAP_KEY_PL_OPTIONS_FILE_CREATED_BY, dto.values);
                    this.filesUploadStatusPlOptions = this._accelUtils.getMapValue(MAP_KEY_PL_OPTIONS_UPLOAD_STATUS, dto.values);
                    console.log('--->allFilesData',JSON.parse(JSON.stringify(this.allFilesData)));
                    console.log('--->files created by pl options',JSON.parse(JSON.stringify(this.filesCreatedByPlOptions)));
                    console.log('--->files upload status pl options',JSON.parse(JSON.stringify(this.filesUploadStatusPlOptions)));
                } else {
                    this.historyAssistanceBulletPoints = [];
                    this.historyAssistanceBulletPoints.push({text: 'There is no publishing history for this region.'});
                    this.filteredFilesData = undefined;
                    this.allFilesData = undefined;
                    console.log(dto, JSON.stringify(dto));
                }
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'','Problem retrieving related files data: '+this.error,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    handleRowAction(evt){
        const row = evt.detail.row;
        const action = evt.detail.action;
        const actionName = action.name;
        console.log('--->',JSON.parse(JSON.stringify(row)));
        console.log('---> action:',JSON.parse(JSON.stringify(action)));
        switch (actionName) {
            case 'preview':
                this.doPreviewFile(row.contentDocumentId);
                break;

            case 'Download':
                // this.downloadFile(row);
                break;
            case 'delete':
                //this.doDeleteFile(row.contentDocumentId);
                this.handleDeleteRow(evt,row);
                break;
            default:
        }
    }
    doPreviewFile(contentDocumentId){
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: contentDocumentId
            }
        });
    }
    doRetrievePerms() {
        const params = {permissions: this.customPermissions};
        console.log('---> params for parms',params);
        retrievePermissions(params)
            .then(dto => {
                if(dto.isSuccess) {
                    console.log(dto, JSON.stringify(dto));
                    this._customPermissions = this._accelUtils.getMapValue(MAP_KEY_PERMISSIONS, dto.values);
                } else {
                    console.log(dto, JSON.stringify(dto));
                }
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'','Problem retrieving related files data: '+this.error,'error');
            })
            .finally(() => {
                this._isLoading = false;
            });
    }
    doDeleteFile(contentDocumentId) {
        this._isProcessing = true;
        const params = {contentDocumentId : contentDocumentId};
        deleteRelatedFile(params)
            .then(dto => {
                if(dto.isSuccess) {
                    const fileDeleted =  this._accelUtils.getMapValue(MAP_KEY_DELETE_FILE, dto.values);
                    this.doRetrieveFiles();
                    uiHelper.showToast(this,'','Successfully deleted file '+ fileDeleted.Title, 'success');
                    console.log('--->filesData',JSON.parse(JSON.stringify(fileDeleted)));
                } else {
                    console.log(dto, JSON.stringify(dto));
                }
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'','Problem deleting file: '+this.error,'error');
            })
            .finally(() => {
                this._isProcessing = false;
            });
    }
    /**
     * Handle the Delete button dt row action / fire a confirmation modal.
     * @param evt
     */
    handleDeleteRow(evt,row) {
        evt.preventDefault();
        evt.stopPropagation();

        let hasPermission = this.hasPermission('delete');
        const docId = row.contentDocumentId;
        const payload = {contentDocumentId: docId, action: 'delete'};
        this.dialogPayload = payload;
        this.confirmIcon = 'action:delete';
        this.confirmIconSize = 'x-small';
        this.confirmTitle = 'Confirm Delete';
        if(hasPermission) {
            this.confirmDisplayMessage = 'You have indicated that you wish to delete file ' + row.fileTitle + '.  Are you sure?';
            console.info('--> permissions:'+this._customPermissions);
            this.confirmLabel = 'Delete File';
        } else {
            this.confirmDisplayMessage = 'You do not have the required permissions to delete this file. Please contact your administrator.';
            this.confirmLabel = undefined;
        }
        this.isActionDialogVisible = true;
    }
    /**
     * Handle the Assign to me confirmation of the assign action.  if confirmed.
     * caLl selectRouteSchedule with selected route schedule id.
     * @param evt
     */
    handleModalConfirmClick(evt) {
        if(evt.detail !== 1){
            const detail = evt.detail.originalMessage;
            if(evt.detail.status === 'confirm') {
                if(detail.action){
                    if(detail.action == 'delete') {
                        if(detail.contentDocumentId) {
                            this.doDeleteFile(detail.contentDocumentId);
                        }
                    }
                }
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.isActionDialogVisible = false;
    }
    hasPermission(action) {
        let hasIt = false;
        if(this._customPermissions) {
            let perm = this._customPermissions.find(x => x.action == action);
            if(perm) {
                hasIt = perm.enabled;
            }
        }
        return hasIt;
    }

    get showAssistance() {
        return !this._isProcessing;
    }

    get showDatatable() {
        return this.filteredFilesData;
    }

    handleImporterSvrMsg(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            if(payload && payload.Route_Import_Id__c === this.relatedRecordId) {
                this.doRetrieveFiles();
            }
        }
    }

    handleContentVersionSvrMsg(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            alert(JSON.stringify(payload));
        }
    }


}