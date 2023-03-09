import {api, track,LightningElement} from 'lwc';
import {loadScript} from "lightning/platformResourceLoader";
import Logger from "c/logger";
import { getConstants } from 'c/clConstantUtil';
import retrievePaAdvisoriesPdf from '@salesforce/apex/PaAdvisoryGalleryController.retrievePaAdvisoriesForPdfExport';
import PDF_LIBS from '@salesforce/resourceUrl/accel_pdf_client_generator';
import { uiHelper } from 'c/portalAdminUtilsUiHelper'
import { dataHelper } from "./paAdvisoryPdfExportDataHelper";

const GLOBAL_CONSTANTS                          = getConstants();
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn'; // logging stuff.

export default class PaAdvisoryPdfExport extends LightningElement {

    @api numColumns = 3;
    @api sortDirection = 'asc';
    @api sortBy = 'paFullName';

    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}


    //@track showPdfControls;
    @track pdfData;

    _advisoryIds;


    @api preparePdfViewPublic(advisoryIds) {
        this._advisoryIds = advisoryIds;
        this.doRetrievePdfData();
    }
    _debugConsole;
    _logger;
    _pdf_libs_loaded;
    _isLoading;
    _isRetrievingPdfData;
    _progressBarLabel;

    constructor() {
        super();
        console.info('%c----> /lwc/paAdvisoryPdfExport', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {}

    renderedCallback() {
        if(!this._pdf_libs_loaded) {
            this.loadPdfLibs();
        }
    }

    doRetrievePdfData() {
        this._isLoading = true;
        this._isRetrievingPdfData = true;
        let params = { advisoryIds: this._advisoryIds};
        this._progressBarLabel = 'Retrieving pdf data.....';
        this.log(DEBUG,'---> calling retrievePdfData with params',params);

        retrievePaAdvisoriesPdf(params)
            .then((result) => {
                this.log(DEBUG,'retrievePdfData dto',result);
                if(result.isSuccess) {
                    let rawData = uiHelper.getMapValue('ADVISORY_WRAPS',result.values);
                    this.pdfData = this.sortImages(this.shapePdfData(rawData));
                    this.log(DEBUG,'shaped and sorted pdf records',this.pdfData);
                } else {
                    this.log(ERROR,'no success from retrievePaAdvisoriesPdf call',this.result);
                }
            })
            .catch((error) => {
                console.error(error);
                let msg = error.body.exceptionType + ' - ' + error.body.message;
                if(error.body.message.includes('limit') || error.body.message.includes('heap')) {
                    msg += '. Please tighten your search parameters.';
                }
               // uiHelper.showToast(this,'Error on Call to Provider',msg,'error','sticky');
            })
            .finally(() => {
                this._isLoading = false;
                this._isSearching = false;
                this._isRetrievingPdfData = false;
            });
    }

    generate()
    {
        try
        {
            const { jsPDF } = window.jspdf;
            var verticalOffset=0.5;
            var size=12;
            var margin=0.5;

            const doc = new jsPDF('p', 'in', 'letter');
            //Landscape PDF
            //new jsPDF({   orientation: 'landscape',   unit: 'in',   format: [4, 2] })
            // jsPDF('p', 'in', 'letter')

            //Sets the text color setTextColor(ch1, ch2, ch3, ch4)
            doc.setTextColor(100);
            //Create Text


            let pdfRows = [];
            let numCols = this.numColumns ? this.numColumns : 3;

            this.pdfData.forEach(record => {
                let pdfRow = [];
                for(let i = 0; i<numCols; i++) {
                    let col = record.paFullName+'\n'+record.paAdvisoryDate;
                    pdfRow.push(col);
                }
                pdfRows.push(pdfRow);
            });
            let iNumLogs = 0;



            //  @TODO What the hell messy as fuck. clean this shit up!
            let b64String = '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';
            /**
             *  addImage explained below:
             *  param 1 -> image in code format
             *  param 2 -> type of the image. SVG not supported. needs to be either PNG or JPEG.
             *  param 3 -> X axis margin from left
             *  param 4 -> Y axis margin from top
             *  param 5 -> width of the image
             *  param 6 -> height of the image
             *
             */
            doc.autoTable({
                body: pdfRows,
                didDrawCell: (data) => {
                    if (data.section === 'body') {
                        if(iNumLogs < 2) {
                            this.log(DEBUG, '-->didDrawCell data', data);
                            iNumLogs++;
                        }
                        if (data.section === 'body') {
                            //data.row.height = 100;
                            var base64Img = 'data:image/jpeg;base64,'+b64String;
                           // doc.addImage(base64Img, 'jpg', data.cell.x, data.cell.y,100,100)
                        }
                        // var base64Img = 'data:image/jpeg;base64,iVBORw0KGgoAAAANS...'
                        // doc.addImage(base64Img, 'JPEG', data.cell.x + 2, data.cell.y + 2, 100, 100)
                    }
                },
            })


            // doc.text("All we are is dust in the wind", 10, 10);
            // doc.rect(20, 20, 10, 10);

            // Set Margins:
            // doc.setDrawColor(0, 255, 0)   //Draw Color
            //     .setLineWidth(1 / 72)  // Paragraph line width
            //     .line(margin, margin, margin, 11 - margin) // Margins
            //     .line(8.5 - margin, margin, 8.5 - margin, 11 - margin)
            //
            // var stringText='blah blah blah \n\n line 2 blah blah';
            //
            // var lines=doc.setFont('Helvetica', 'Italic')
            //     .setFontSize(12)
            //     .splitTextToSize(stringText, 7.5);
            // //doc.setFontSize(40);
            // doc.text(0.5, verticalOffset + size / 72, lines);
            // verticalOffset += (lines.length + 0.5) * size / 72;
            // //Save File
            let dFormatter = new Intl.DateTimeFormat('en-US');
            let sDate = dFormatter.format(new Date());
            let fileName = 'pa_advisories_'+ sDate;
            doc.save(fileName);

        }
        catch(error) {
            alert("Error " + error);
        }
    }
    //Convert Image into Base64
    getBase64Image(img) {
        var canvas = document.createElement("canvas");
        canvas.width = img.width;
        canvas.height = img.height;
        var ctx = canvas.getContext("2d");
        ctx.drawImage(img, 0, 0);
        var dataURL = canvas.toDataURL("image/png");
        return dataURL.replace(/^data:image\/(png|jpg);base64,/, "");
    }

    //Create PDF with Image and Text
    generatePDFImage(e)
    {
        try{
            const { jsPDF } = window.jspdf;
            // You'll need to make your image into a Data URL

            var imgData = 'data:image/jpeg;base64,'+ this.getBase64Image(this.template.querySelector('.image'));
            var doc = new jsPDF();
            doc.setFontSize(40);
            doc.text(35, 25, 'SalesforceCodex.com');
            doc.addImage(imgData, 'JPEG', 15, 40, 180, 160);
            doc.save("a4.pdf");
        }
        catch(error)
        {
            alert(error);
        }
    }

    handleButtonClick(evt) {
        if(evt && evt.detail) {
            switch (evt.detail.buttonid) {
                case 'submitCancelButton' : {
                    this.processCancelClick();
                    break;
                }
                case 'submitPdfButton' : {
                    this.processSubmitClick();
                    break;
                }
                default : {
                   this.log(ERROR,'unhandled button id',evt.detail);
                }
            }
        }
    }

    processCancelClick() {
        //this.showPdfControls = false;
        this.pdfData = null;
        this.dispatchEvent(new CustomEvent('cancelpdf'));
    }

    processSubmitClick() {
        this.generate();
    }

    /**
     * Takes the server side data and clones it for easier use.
     *
     * @param wraps    An Array of PaAdvisoryController.AdvisoryWrapper objects.
     * @returns {*[]}  An Array of cloned and flattened records suitable for datatable display.
     *
     *  Id,Name,Advisory_Date__c,Image_Base_64_String__c,Photo__c,Full_Name__c
     */
    shapePdfData(wraps) {
        let records = [];
        if (wraps && wraps.length > 0) {
            let tmp = JSON.parse(JSON.stringify(wraps));
            tmp.forEach(wrap => {
                let record = {};
                record.paAdvisoryName = wrap.advisory.Name;
                record.paAdvisoryId = wrap.advisory.Id;
                record.paAdvisoryDate = wrap.advisory.Advisory_Date__c;
                record.paFullName = wrap.advisory.Full_Name__c;
                record.paPhoto = wrap.advisory.Photo__c;
                record.paImgSrc = wrap.photoSrcUrl;
                record.paBase64 = wrap.advisory.Image_Base_64_String__c;
                records.push(record);
            });
        }
        return records;
    }

    sortImages(records) {
        let tmpSortBy = this.sortBy;


        return dataHelper.sortData(tmpSortBy,this.sortDirection,records);
    }

    get showStencil() {
        return this._isLoading;
    }
    get showProgressBar() {
        return this._isLoading || this._isRetrievingPdfData;
    }
    get numPdfRows() {
        return this.pdfData ? this.pdfData.length : 0;
    }

    get showPdfForm() {
        return this.pdfData && this.pdfData.length > 0 && this._pdf_libs_loaded;
    }

    /**
     *  //  loadScript(this, PDF_LIBS + '/lib/html2pdf.bundle.min.js'),
     */
    loadPdfLibs() {
        Promise.all([
                loadScript(this, PDF_LIBS + '/lib/html2canvas.min.js'),
                loadScript(this, PDF_LIBS + '/lib/jspdf.umd.min.js'),
                loadScript(this, PDF_LIBS + '/lib/jspdf.plugin.autotable.min.js'),
            ])
            .then(() => {
                this._pdf_libs_loaded = true;
                this.log(DEBUG,'pdf libs loaded');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            })
            .finally( () => {

            });
    }

    //  this.log(DEBUG,'--> advisoryIds',advisoryIds);

//
//
//             //this._displayPdf = true;
//             let parentDiv = this.template.querySelector('[data-id="pdfcontent"]');
//            // this.log(DEBUG,'---> parentDiv.. '+parentDiv.innerHTML,parentDiv);
//             var opt = {
//                 margin:       1,
//                 filename:     'myfile.pdf',
//                 image:        { type: 'jpeg', quality: 0.98 },
//                 html2canvas:  { scale: 2 },
//                 jsPDF:        { unit: 'in', format: 'letter', orientation: 'portrait' }
//             };
//
// // New Promise-based usage:
//            // html2pdf().set(opt).from(parentDiv).toPdf().save();
//            // html2pdf(parentDiv);
//
//             let cmp = this.template.querySelector('c-pa-advisory-pdf-export');
//             if(cmp) {
//                 let parentDiv = this.template.querySelector('[data-id="pdfcontent"]');
//                 cmp.generatePdfPublic(this.filteredUserRecords);
//             }

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