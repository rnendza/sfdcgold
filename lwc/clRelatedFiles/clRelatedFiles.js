import {LightningElement, api, track, wire} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import {getRecordNotifyChange} from "lightning/uiRecordApi";
import {dtHelper} from "./clRelatedFilesDatatableHelper";
import {uiHelper} from "./clRelatedFilesUiHelper";
import {themeOverrider} from "./clRelatedFilesThemeOverrider";
import {reduceErrors} from "c/ldsUtils";
import {getConstants} from "c/clConstantUtil";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveRelatedFiles from '@salesforce/apex/clRelatedFiles.retrieveRelatedFiles';
import retrieveRouteImport from '@salesforce/apex/clRelatedFiles.retrieveRouteImport';
import retrievePermissions from '@salesforce/apex/clRelatedFiles.retrievePermissions';
import deleteRelatedFile from '@salesforce/apex/clRelatedFiles.deleteRelatedFile';

const relatedFilesColumns = dtHelper.getFilesDtColumns();
const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_RELATED_FILES = 'RELATED_FILES';
const MAP_KEY_DELETE_FILE = 'DELETE_FILE';
const MAP_KEY_PL_OPTIONS_FILE_CREATED_BY = 'PL_OPTIONS_FILE_CREATED_BY';
const MAP_KEY_PL_OPTIONS_UPLOAD_STATUS = 'PL_OPTIONS_UPLOAD_STATUS';
const MAP_KEY_PERMISSIONS = 'PERMISSIONS';
const MAP_KEY_ROUTE_IMPORT = 'ROUTE_IMPORT';
const ROUTE_IMPORT_UPLOAD_TYPE = 'Route Import';

export default class ClRelatedFiles extends NavigationMixin(LightningElement) {

    @api title;
    @api showDetails;
    @api showFileUpload;
    @api showsync;
    @api recordId;
    @api usedInCommunity;
    @api showFilters;
    @api accept = '.csv';
    @api progressHeight       = '10'
    @api fileFieldValue;
    @api fileFieldName;
    @api displayHelpVideoLink;
    @api helpFileTitle; 
    @api
    set customPermissions(val) {
        if(val) {
            this._permissions = val;
            this.doRetrievePerms();
        }
    }
    get customPermissions() {
        return this._permissions;
    }

    @track cvWrapperHelpFile;
    @track allFilesData;
    @track filteredFilesData;
    @track filesColumns = relatedFilesColumns;
    @track filesCreatedByPlOptions;
    @track filesUploadStatusPlOptions;
    @track permissions;
    @track isActionDialogVisible;
    @track isPublisherDialogVisible;
    @track dialogPayload;
    @track confirmLabel;
    @track confirmTitle;
    @track confirmDisplayMessage;
    @track confirmIcon = 'standard:question_feed';
    @track confirmIconSize = 'small';
    @track selectedDocId;
    @track uploaderAssistanceBulletPoints;
    @track routeImportRecord;

    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _isLoading;
    _isProcessing;
    _permissions;
    _customPermissions;
    _wiredImportDto;
    _hasOverrodeSfdcCss;

    constructor() {
        super();
        console.info('%c----> /lwc/clRelatedFiles',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this.showFilters = true;
        this.showFileUpload = true;
        this.fileFieldName = 'Route Import';
        this.fileFieldValue = 'Cash_Logistics_Upload_Type_fileupload__c';
    }

    connectedCallback() {
        this.doRetrieveFiles();
    }

    renderedCallback() {
        if(!this._hasOverrodeSfdcCss) {
            themeOverrider.buildSfdcCoreOverrideCss(this);
        }
    }

    @wire(retrieveRouteImport, {routeImportId: '$recordId'})
    retrieveRouteImportRecord(wiredDto) {
        this._wiredImportDto = wiredDto;
        const { data, error } = this._wiredImportDto;
        if(data) {
            const dto = data;
            this.routeImportRecord = this._accelUtils.getMapValue(MAP_KEY_ROUTE_IMPORT, dto.values);
            if(this.routeImportRecord) {
                //alert('clear it');
                this.uploaderAssistanceBulletPoints = [];
                let msg = 'Please click upload files or drop a new file to upload a new route csv';
                msg+= this.routeImportRecord ? ' for <b>'+this.routeImportRecord.Name + '.</b>' : '.';
                this.uploaderAssistanceBulletPoints.push({text: msg, severity: 'info'});
                if(this.filteredFilesData && this.filteredFilesData.length > 0) {
                    let msg2 = 'You may take action on each upload via clicking the drop down on the right.';
                    this.uploaderAssistanceBulletPoints.push({text: msg2, severity: 'info'});
                    let msg3 = '<b>Note:</b> stopNumber is now required as a column in the spreadsheet as of 5/5/2022.';
                    this.uploaderAssistanceBulletPoints.push({text: msg3, severity: 'info'});
                }
            }
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            uiHelper.showToast(this,'','Problem retrieving route import record: '+this.error,'error');
            this._isLoading = false;
        }
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
                //this._isLoading = false;
            });
    }
    handlePreviewHelpFile(evt) {
        uiHelper.navigateToStandardWebPage(this,this.cvWrapperHelpFile.fileDownloadUrl);
    }

    doRetrieveFiles() {
        this._isLoading = true;
        const params = {recordId: this.recordId, uploadType : ROUTE_IMPORT_UPLOAD_TYPE};
        retrieveRelatedFiles(params)
            .then(dto => {
                if(dto.isSuccess) {
                    this.allFilesData = this._accelUtils.getMapValue(MAP_KEY_RELATED_FILES, dto.values);
                    this.filteredFilesData = this.allFilesData.map( row => {
                        row.statusCssClass = (row.fileUploadStatus === 'Published' ? 'accel-status-published' : 'accel-status-uploaded');
                        row.icon = 'doctype:csv';
                        row.fileTitleTruncated = uiHelper.truncateString(row.fileTitle,35);
                        row.fileCreatedByLinkName = '/'+row.fileCreatedById;
                        let newRow = {...row};
                        newRow.fileLinkName = row.fileDownloadUrl;
                        return newRow;
                    });
                    if(this.filteredFilesData.length > 0) {

                        let msg2 = 'You may take action on each upload via clicking the drop down on the right.';
                        if(this.uploaderAssistanceBulletPoints) {
                            let existingVal =  this.uploaderAssistanceBulletPoints.find(x => x.text == msg2);
                            if(existingVal == undefined) {
                                this.uploaderAssistanceBulletPoints.push({text: msg2,severity: 'info'});
                            }
                        } else {
                            this.uploaderAssistanceBulletPoints = [];
                            let msg = 'Please click upload files or drop a new file to upload a new route csv';
                            msg+= this.routeImportRecord ? ' for <b>'+this.routeImportRecord.Name + '.</b>' : '.';
                            this.uploaderAssistanceBulletPoints.push({text: msg, severity: 'info'});
                            this.uploaderAssistanceBulletPoints.push({text: msg2,severity: 'info'});
                        }
                    }
                    this.filesCreatedByPlOptions = this._accelUtils.getMapValue(MAP_KEY_PL_OPTIONS_FILE_CREATED_BY, dto.values);
                    this.filesUploadStatusPlOptions = this._accelUtils.getMapValue(MAP_KEY_PL_OPTIONS_UPLOAD_STATUS, dto.values);
                } else {
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

    /**
     * Handle the Delete button dt row action / fire a confirmation modal.
     * @param evt
     */
    handlePublishRow(evt,row) {
        evt.preventDefault();
        evt.stopPropagation();

        let hasPermission = this.hasPermission('publish');
        if(row.fileUploadStatus === 'Published') {
            let msg = row.fileTitle + ' was already published!';
            uiHelper.showToast(this,'',msg,'error');
            return;
        }
        const docId = row.contentDocumentId;

        const payload = {contentDocumentId: docId, action: 'modifyroutes'};
        this.dialogPayload = payload;
        this.confirmIcon = 'standard:record_delete';
        this.confirmTitle = 'Confirm Publish';
        if(hasPermission) {
            this.confirmDisplayMessage = 'You have indicated that you wish to publish file ' + row.fileTitle + '.  Are you sure?';
            console.info('--> permissions:'+this._customPermissions);
            this.confirmLabel = 'Modify your Route data';
            this.isPublisherDialogVisible = true;
        } else {
            this.confirmDisplayMessage = 'You do not have the required permissions to publish this file. Please contact your administrator.';
            this.confirmLabel = undefined;
            this.isActionDialogVisible = true;
        }

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
    handleModalPublisherConfirmClick(evt) {
        if(evt.detail !== 1){
            const detail = evt.detail.originalMessage;
            console.log(evt.detail.status);
            if(evt.detail.status === 'confirm' || evt.detail.status === 'close') {
                let finalEvent = {};
                this.dispatchEvent(new CustomEvent('publishaction', {detail: finalEvent}));
                this.doRetrieveFiles();
                if(detail.action){
                    if(detail.action == 'publish') {
                        if(detail.contentDocumentId) {
                           console.log('--- do publish!');
                        }
                    }
                }
            }else if(evt.detail.status === 'cancel'){

            }
        }
        this.isPublisherDialogVisible = false;
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

    downloadFile(file){
        this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: file.downloadUrl
                }
            }, false
        );
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

    handleUploadFinished(evt) {
        const uploadedFiles = evt.detail.files;
        if(uploadedFiles && uploadedFiles.length) {
            let file = uploadedFiles[0];
            this.uploadedDocId = file.documentId;
            // set import type..
            console.log('--> file',JSON.parse(JSON.stringify(file)));
            let msg = file.name + ' uploaded successfully. Please select the dropdown arrow to the right to publish the file and modify your routes.';
            uiHelper.showToast(this,'',msg,'success');
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.doRetrieveFiles();
        }
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
            case 'publish':
                this.handlePublishRow(evt,row);

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


    handleSearch(event){
        let value = event.target.value;
        let name  = event.target.name;
        this.allFilesData = this.allFilesData.map( row => {
            let newRow = {...row};
            newRow.fileLinkName = row.fileDownloadUrl;
            row.icon = 'doctype:csv';
            return newRow;
        });

        switch(name) {
            case 'search_createdby':
                if(value !== '-1') {
                    this.filteredFilesData = this.allFilesData.filter(row => {
                        return row.fileCreatedById.toLowerCase().includes(value.toLowerCase());
                    });
                } else {
                    this.filteredFilesData = this.allFilesData;
                }
                break;
            case 'search_uploadstatus':
                if(value !== '-1') {
                    this.filteredFilesData = this.allFilesData.filter(row => {
                        return row.fileUploadStatus.toLowerCase().includes(value.toLowerCase());
                    });
                } else {
                    this.filteredFilesData = this.allFilesData;
                }
                break;
            case 'search_title':
                this.filteredFilesData = this.allFilesData.filter( row => {
                    return row.fileTitle.toLowerCase().includes(value.toLowerCase());
                });
                break;
        }
    }

    get showUploadOrFilters() {
        return (this.showFileUpload || this.showFilters) && !this.showStencil;
    }
    get showDtFilters() {
        return this.showUploadOrFilters && this.showFilesDatatable;
    }
    get showStencil() {
        return this._isProcessing || this._isLoading;
    }
    get progressStyle() {
        return `height:${this.progressHeight}px;width:100%`;
    }
    get progressLabel() {
        // return 'executing server code.....';
    }
    get showFilesDatatable() {
        return this.allFilesData && this.allFilesData.length > 0;
    }
    get showUploaderAssistance() {
        return this.uploaderAssistanceBulletPoints;
    }
}