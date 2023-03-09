import {LightningElement, api, track,wire} from 'lwc';
import {reduceErrors} from "c/ldsUtils";
import {getConstants} from "c/clConstantUtil";
import CSVPARSER from '@salesforce/resourceUrl/papaparse';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveContentVersion from '@salesforce/apex/clRelatedFiles.retrieveContentVersion';
import retrieveRouteImport from '@salesforce/apex/clRelatedFiles.retrieveRouteImport';
import modifyRoutes from '@salesforce/apex/clRelatedFiles.doModifyRoutes';
import {loadScript} from "lightning/platformResourceLoader";
import {dtHelper} from "./clRelatedFilesPublisherDatatableHelper";
import {uiHelper} from "./clRelatedFilesPublisherUiHelper";
import {publish} from "lightning/messageService";
import {refreshApex} from "@salesforce/apex";
import {NavigationMixin} from "lightning/navigation";

const PAPAPARSE_LIBPATH = '/lib/papaparse.js';
const MAP_KEY_ROUTE_IMPORT = 'ROUTE_IMPORT';
const MAP_KEY_SUCCESS_FILEWRAP = 'SUCCESS_FILEWRAP';
const MAP_KEY_CSVDATA_FILEWRAP = 'CSVDATA_FILEWRAP';


export default class clRelatedFilesPublisher extends NavigationMixin(LightningElement) {

    @api visible = false; //used to hide/show dialog
    @api title = ''; //modal title
    @api name; //reference name of the component
    @api message = ''; //modal message
    @api confirmLabel; //confirm button label
    @api cancelLabel = ''; //cancel button label
    @api useCsvParser;
    @api assistanceHeader = 'Route Publisher Assistant';
    @api relatedRecordId;
    @api
    set originalMessage(val) {
        this._originalMessage = val;
        if(this._originalMessage) {
            console.log('---original message=',JSON.parse(JSON.stringify(this._originalMessage)));
            if(this._originalMessage.contentDocumentId) {
                this._isLoading = true;
                this.loadParser();
            }
        } else {
            console.log('in setter no message');
        }
    } //any event/message/detail to be published back to the parent component
    get originalMessage() {
        return this._originalMessage;
    }

    @api headerIcon;

    @track contentDocumentId;
    @track helpFileContentDocumentId = '0697h000000CKpjAAG';
    @track routeImportRecord;
    @track csvString;
    @track closeLabel;
    @track allParsedRowData;
    @track previewParsedRowData;
    @track customCsvErrors = [];
    @track parsedCsvMsg;
    @track preUploadColumns                 = dtHelper.getPreUploadDtColumns();
    @track preUploadErrorsColumns           = dtHelper.getPreUploadErrorsDtColumns();
    @track assistanceBulletPoints;
    @track cvWrapper;
    @track cvWrapperHelpFile;
    _assistanceHeader = this.assistanceHeader;
    _uploadStatus;



    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _wiredFileDto;
    _wiredImportDto;
    _originalMessage;
    _parseResults;
    _hasParserErrors;
    _isProcessing;
    _isLoading;
    _successFile;
    _anyErrorsExist;

    constructor() {
        super();
    }

    connectedCallback() {
        this._isLoading = true;
        this._assistanceHeader = 'Route Publisher Assistant';
        console.log('---> confirm label1:',this.confirmLabel);
    }

    @wire(retrieveContentVersion, {contentDocumentId: '$contentDocumentId'})
    retrieveFile(wiredDto) {
        this._wiredFileDto = wiredDto;
        const { data, error } = this._wiredFileDto;
        if(data) {
            const dto = data;
            //console.log('data',JSON.stringify(dto));
            this.cvWrapper = this._accelUtils.getMapValue(MAP_KEY_CSVDATA_FILEWRAP, dto.values);
            //console.log('---> json=',JSON.parse(JSON.stringify(obj.csvData)));
            this.csvString = JSON.parse(JSON.stringify(this.cvWrapper.csvData));
            this.parseCsvString();
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            uiHelper.showToast(this,'','Problem retrieving file data: '+this.error,'error');
            this._isLoading = false;
        }
    }

    @wire(retrieveRouteImport, {routeImportId: '$relatedRecordId'})
    retrieveRouteImportRecord(wiredDto) {
        this._wiredImportDto = wiredDto;
        const { data, error } = this._wiredImportDto;
        if(data) {
            const dto = data;
            this.routeImportRecord = this._accelUtils.getMapValue(MAP_KEY_ROUTE_IMPORT, dto.values);
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            uiHelper.showToast(this,'','Problem retrieving route import record: '+this.error,'error');
            this._isLoading = false;
        }
    }

    /**
     * The main parsing of the upload csv.
     */
    parseCsvString() {
        Papa.parse(this.csvString, {
            quoteChar: '"',
            header: true,
            skipEmptyLines: true,
            dynamicTyping: true,
            complete: (results) => {
                this._parseResults = results;
                console.log('---> papa parse results',results);
                this.processPapaResults();
            },
            error: (error) => {
                this._isLoading = false;
                console.error(error);
                let msg = error;
                uiHelper.showToast(this,'',msg,'error');
            }
        })
    }

    processPapaResults() {
        if(this._parseResults.errors && this._parseResults.errors.length > 0) {
            this._hasParserErrors = true;
            this._isProcessing = false;
            this.prepareErrors();
            //uiHelper.showToast(this,'','Errors were found while parsing','error');
        } else {
            if(this._parseResults && this._parseResults.data.length > 0) {
                this._hasParserErrors = false;
                this.prepareUpload();
            } else {
                this._anyErrorsExist = true;
                this.confirmLabel = undefined;
                uiHelper.showToast(this,'Parsing Error','Please double check that you have the correct spreadsheet and format','error');
                let row = {rowNumber: 1};
                row.message = 'No csv data found!';
                this.customCsvErrors.push(row);
                this._anyErrorsExist = true;
            }
        }
    }
    /**
     * Do any additional validation and then place results in the routeData array
     * which will map to clRouteImport.RouteImportData.cls
     */
    prepareUpload() {
        //this.parsedCsvMsg = 'Data that will be uploaded: ';
        this.allParsedRouteData = [];
        if(this._parseResults.data) {
            this._parseResults.data.forEach( (row,index) => {
                // a mere 1 to 1 copy for now but massage further if needed.
                row.rowNumCssClass = 'slds-icon-standard-file';
                row.rowNumber = index + 1;
                if(!this.allCustomValidityChecksPassed(row)) {
                    this.confirmLabel = undefined;
                    uiHelper.showToast(this,'','Some errors exist in your csv file.','error');
                    //this.assistanceBulletPoints = undefined;

                } else {
                    row.valid = true;
                    row.validCSSClass = 'slds-text-color_success';
                }
                if(this.customCsvErrors && this.customCsvErrors.length > 0) {
                }
                this.allParsedRouteData.push(row);
            });
            console.warn('---> custom errors size',this.customCsvErrors.length);
           // this.handleSort();
            this.message = null;
            console.log('---> all parsed routeData',this.allParsedRouteData);
            this.previewParsedRowData = this.allParsedRouteData.slice(0,5);
            if(!this._anyErrorsExist) {
                this.parsedCsvMsg = this.allParsedRouteData.length + ' rows will be processed </b> (A sample of 5 shown below). Click <b>Modify Routes</b> to send your changes';
                console.log('---> parsedmsg=', this.parsedCsvMsg);
                if (!this.assistanceBulletPoints) {
                    this.assistanceBulletPoints = [];
                }
                this.assistanceBulletPoints.push({text: this.parsedCsvMsg});
            }
            this._isProcessing = false;
            this._isLoading = false;
        }
    }

    /**
     * Do any additional validation and then place results in the routeData array
     * which will map to clRouteImport.RouteImportData.cls
     */
    prepareErrors() {
        let errors  = [];
        if(this._parseResults.errors) {
            this._parseResults.errors.forEach(error => {
                // a mere 1 to 1 copy for now but massage further if needed.
                let csvRow = this._parseResults.data[error.row];
                csvRow.errorMsg = error.message;
                errors.push(csvRow);
            });
            console.error('---> errors',errors);
            let msg = 'Errors parsing csv!';
            this.confirmLabel = undefined;
            uiHelper.showToast(this,'',msg,'error');
            this._isProcessing = false;
        }
    }

    doModifyRoutes() {
        this.assistanceBulletPoints = undefined;
        this._assistanceHeader = 'Route Import Status..';
        this.addAssistanceBullet('Calling server with '+this.allParsedRouteData.length + ' rows.');
        this._isProcessing = true;
        const params = {
            routeImportRows: this.allParsedRouteData,
            contentDocumentId: this.contentDocumentId,
            routeImportId: this.relatedRecordId
        };
        console.log('---> upload data params=',params);

        modifyRoutes(params)
            .then(dto => {
                console.log('dto',JSON.parse(JSON.stringify(dto)));
                if(dto.isSuccess) {
                    this._successFile = this._accelUtils.getMapValue(MAP_KEY_SUCCESS_FILEWRAP, dto.values);
                    //console.log('---> success file=',JSON.parse(JSON.stringify(this._successFile)));
                    this.addAssistanceBullet(dto.message);
                    let bullet = 'You may click the button below to view details results or access results in the History tab.';
                    this.addAssistanceBullet(bullet);
                    this._uploadStatus = 'success';
                    this.cancelLabel = undefined;
                    this.confirmLabel = undefined;
                    this.closeLabel = 'Close';
                    let msg = 'Routes were successfully modified!'
                    uiHelper.showToast(this,'',msg,'success');
                    this.title = 'Publish Results';
                } else {
                    console.log(dto, JSON.stringify(dto));
                    uiHelper.showToast(this,'',dto.message,'error');
                }
            })
            .catch(error => {
                console.error(JSON.stringify(error));
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'','Problem deleting file: '+this.error,'error');
            })
            .finally(() => {
                this._isProcessing = false;
                //this.confirmLabel = undefined;
            });
    }
    addAssistanceBullet(text) {
        if(!this.assistanceBulletPoints) {
            this.assistanceBulletPoints = [];
        }
        this.assistanceBulletPoints.push({text: text});
    }

    handleClick(event){
        if(event.currentTarget.dataset.id == 'confirm') {
            if(this.originalMessage.action === 'modifyroutes') {
                this.doModifyRoutes();
                return;
            }
        }
        let finalEvent = {originalMessage: this.originalMessage, status: event.target.name};
        this.dispatchEvent(new CustomEvent('modalaction', {detail: finalEvent}));
    }

    handleImporterSvrMsg(evt) {
        let payload;
        if(evt.detail) {
            payload = evt.detail;
            if(payload && payload.Route_Import_Id__c === this.relatedRecordId) {
                this.addAssistanceBullet(payload.Ui_Message__c);
            }
        }
    }
    handleDownloadClick(evt) {
        uiHelper.navigateToStandardWebPage(this,this._successFile.fileDownloadUrl);
    }
    handleDownloadOriginalClick(evt) {

        uiHelper.navigateToStandardWebPage(this,this.cvWrapper.fileDownloadUrl);
    }
    handlePreviewHelpFile(evt) {
       // let contentDocId = this.helpFileContentDocId;
        //uiHelper.navigateToNamedPage(this,'firePreview',contentDocId);
        uiHelper.navigateToStandardWebPage(this,this.cvWrapperHelpFile.fileDownloadUrl);
    }

    /**
     * Checks all fields for non null values and data types.  If any not valid adds a custom error message
     * as well as adds to an error array for display to the user, hides modify button.
     *
     * @param row
     * @return {string|*|boolean}
     */
    allCustomValidityChecksPassed(row) {
        let valid = row.accountId
            && row.routeName
            && row.collectionType
            && row.replenishmentType
            && row.stopNumber
            && Number.isInteger(row.x1FillLevel)  && Number.isInteger(row.x5FillLevel)
            && Number.isInteger(row.x20FillLevel)  && Number.isInteger(row.x50FillLevel)
            && Number.isInteger(row.x100FillLevel) && Number.isInteger(row.stopNumber);

        row.valid = valid;
        if(!valid) {
            let msg = '';
            if(!row.accountId) {msg += ' Invalid accountId '};
            if(!row.routeName) {msg += ' Invalid routeName '};
            if(!row.collectionType) {msg+= ' Invalid collectionType '};
            if(!row.replenishmentType) {msg+= ' Invalid replenishmentType '};
            if(!row.stopNumber || !Number.isInteger(row.stopNumber)) {msg+= ' Invalid stopNumber '};
            if(!Number.isInteger(row.x1FillLevel)) { msg+= ' Invalid x1FillLevel '};
            if(!Number.isInteger(row.x5FillLevel)) { msg+= ' Invalid x5FillLevel '};
            if(!Number.isInteger(row.x20FillLevel)) { msg+= ' Invalid x20FillLevel '};
            if(!Number.isInteger(row.x50FillLevel)) { msg+= ' Invalid x50FillLevel '};
            if(!Number.isInteger(row.x100FillLevel)) { msg+= ' Invalid x100FillLevel '};
            let customError = {...row, message: msg};
            this.customCsvErrors.push(customError);
            this._anyErrorsExist = true;
        } else {
            row.validCSSClass =  'slds-icon-standard-store';
        }

        return valid;
    }
    loadParser() {
        loadScript(this, CSVPARSER + PAPAPARSE_LIBPATH)
            .then(() => {
                console.info('---> parserloaded');
                this._parserLoaded = true;
                this.contentDocumentId = this._originalMessage.contentDocumentId;
            })
            .catch(error => {
                alert(error);
            })
            .finally(() => {
                this._isLoading = false;
            });
    }
    get showCsvData() {
        return !this._isLoading && !this._isProcessing && !this._uploadStatus && this._uploadStatus !== 'success';
    }

    get showUploadDetails() {
        return this._uploadStatus === 'success';
    }

    get showStencil() {
        return this._isLoading || this._isProcessing;
    }

    get showAssistant() {
        return this.parsedCsvMsg;
    }

    get showProgressBar() {
        return this._isProcessing;
    }

    get firePeSubscriber() {
        return this._isProcessing;
    }
    get successDownloadLabel() {
        let label;
        if(this._successFile) {
            label = 'Download Success Results';
        }
        return label;
    }
    get originalFileDownloadLabel() {
        let label = 'Download ';
        if(this.cvWrapper) {
            label = 'Download '+this.cvWrapper.fileTitle;
        }
        return label;
    }
}