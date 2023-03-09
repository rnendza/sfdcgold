import {LightningElement,api} from 'lwc';
//import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_stripped_down';
import COMPRESSOR from  '@salesforce/resourceUrl/compressor';
import {loadScript, loadStyle} from "lightning/platformResourceLoader";
import {reduceErrors} from 'c/ldsUtils';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import saveTheChunkFile from '@salesforce/apex/FileUploadSvc.saveTheChunkFile';
import deleteDocument from '@salesforce/apex/FileUploadSvc.deleteDoc';

const MAX_FILE_SIZE = 4500000;
//const CHUNK_SIZE = 150000;
const CHUNK_SIZE = 3500000;
const IMG_COMPRESSION_QUALITY = 0.6;


export default class UiCameraLauncher extends LightningElement {

    @api allowCamLaunch = false;

    @api parentRecordId;
    @api imgTitle;
    @api imgCompressionRatio = .2;
    @api contentDocumentId;
    @api contentVersionId;
    @api iconZoom = 4;
    /**
     * [Current Cassette,Current Coin]
     */
    @api redemptionImageType;

    /**
     * The height to set on the div to render.
     * @type {number}
     * @access public
     * @default 10
     */
    @api height = 10;

    /**
     * The width to set on the div to render.
     * @type {number}
     * @access public
     */
    @api width;

    @api iconStyle;

    @api camLauncherClick(){
        console.log("Child LWC Component method invoked");
        let input =   this.template.querySelector('input');
        input.click();
    }

    connectedCallback() {
        console.log('--- connected callBack uiCamLaunders43');
    }

    renderedCallback() {
        //console.log('---- rendered callback');
        if(!this._hasRendered) {
            this._hasRendered = true;
            this.loadFontAwesome();
        }
    }

    handleFileInputFocus() {
        //console.log(' file input focus handler!');
    }

    handleCamClick(evt) {
        evt.stopPropagation();
        console.log('-- handle cam click');
        //window.addEventListener('focus', this.onCancelListener.bind(this));
        //window.addEventListener('focus', this.onCancelListener.bind(this));
        window.addEventListener('focus', this.onCancelListener.bind(this));
    }
    fileName = '';
    filesUploaded = [];
    isLoading = false;
    accelCamStyle = 'display:block';
    progressPercent = 0;
    progressLabel = 'Starting upload..';
    fileSize;

    _interval;

    connectedCallback() {
        // console.log('--- parent record id=' + this.parentRecordId
        // + ' title='+this.imgTitle);
        this.iconStyle+= ';font-size:4.0em';
    }

    onCancelListener(evt) {
        console.info('--- cancel / focus listener');
        console.info('--- files updated=' + this.filesUploaded);
        let payload = {
            contentDocumentId: this.contentDocumentId,
            contentVersionId: this.contentVersionId,
            meterId: this.parentRecordId
        };
        const myEvt = new CustomEvent('filereplacecanceled', {detail: payload, bubbles: true, composed: true});
        console.info('fire filereplacecanceled with pl=' + JSON.stringify(payload));
        this.dispatchEvent(myEvt);
        console.log('----------after fire of event');
        window.removeEventListener('focus', this.onCancelListener);
        console.log('---- remove listener from window');
    }

    handleCancel() {
        alert('cancel');
    }

    disconnectedCallback() {
        clearInterval(this._interval);
    }

    renderedCallback() {
        if (!this._hasRendered) {
            this._hasRendered = true;
           // this.loadFontAwesome();
            this.loadCompressor();
        }
    }
    get containerStyle() {
        return `${this.containerHeight}; ${this.containerWidth}; ${this.containerRadius}`;
    }

    get containerHeight() {
        return `height: ${this.height}px`;
    }
    get iconClass() {
        // if(!this.iconZoom) {
        //     return 'fas fa-camera fa-4x';
        // } else {
        //     return `fas fa-camera fa-${this.iconZoom}x`;
        // }
        return ' icon-camera ';
    }

    get containerWidth() {
        if (!this.width) {
            return 'width: 100%';
        }
        return `width: ${this.width}px`;
    }

    get progressStyle() {
        return `height:${this.height}px;width:100%`;
    }

    handleFilesChange(event) {
        console.log('--- file change handler!');
        this.isLoading = true;
        if(event.target.files.length > 0) {
            this._interval = setInterval(this.updateProgress.bind(this), 750);
            this.filesUploaded = event.target.files;
            console.log('---> title='+this.imgTitle);
            let fn = event.target.files[0].name;
            let lastDot = fn.lastIndexOf('.');
            let ext = fn.slice(lastDot + 1);
            if(!this.imgTitle) {
                this.fileName = event.target.files[0].name;
            } else {
                this.fileName = this.imgTitle + '.'+ ext;
            }
            this.compressIt(this.filesUploaded[0]);
        }
    }

    updateProgress() {
        this.progressPercent = this.progressPercent === 100 ? this.resetProgress() : this.progressPercent + 10;
    }

    resetProgress() {
        this.progressPercent = 0;
        clearInterval(this._interval);
    }

    saveFile(file){
        var fileCon = file;
        this.fileSize = this.formatBytes(fileCon.size, 2);
        if (fileCon.size > MAX_FILE_SIZE) {
            let message = 'File size cannot exceed ' + MAX_FILE_SIZE + ' bytes.\n' + 'Selected file size: ' + fileCon.size;
            this.dispatchEvent(new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            }));
            return;
        }
        var reader = new FileReader();
        var self = this;

        reader.onload = function() {

            var fileContents = reader.result;
            var base64Mark = 'base64,';
            var dataStart = fileContents.indexOf(base64Mark) + base64Mark.length;
            fileContents = fileContents.substring(dataStart);
            //self.showToast('',"Starting upload! file name = "+self.fileName + ".  File size="+self.fileSize);
            self.accelCamStyle = 'display:none';
            let payload = {fileName : self.fileName, fileSize : self.fileSize};
            console.log('---> saving total files size  = '+self.formatBytes(fileCon.size,2));
            const evt = new CustomEvent('fileuploadstarted', {detail: {payload}});
            self.dispatchEvent(evt);
            self.upload(fileCon, fileContents);
        };
        reader.readAsDataURL(fileCon);
    }

    upload(file, fileContents){
        var fromPos = 0;
        var toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);
        this.uploadChunk(file, fileContents, fromPos, toPos, '');
    }

    uploadChunk(file, fileContents, fromPos, toPos, attachId){
        this.progressPercent = this.progressPercent + 20;
        this.isLoading = true;
        var chunk = fileContents.substring(fromPos, toPos);
        console.warn('--> saving chunk frompos='+fromPos+' topos='+toPos);
        console.log('-->'+JSON.stringify(file));
        this.progressLabel = 'Saving '+this.fileName;

        saveTheChunkFile({
            parentId: this.parentRecordId,
            fileName: this.fileName,
            base64Data: encodeURIComponent(chunk),
            contentType: file.type,
            fileId: attachId,
            redemptionImageType: this.redemptionImageType
        })
            .then(result => {
                attachId = result;
                fromPos = toPos;
                toPos = Math.min(fileContents.length, fromPos + CHUNK_SIZE);
                if (fromPos < toPos) {
                    this.uploadChunk(file, fileContents, fromPos, toPos, attachId);
                }else{
                    this.progressPercent = 100;
                    this.progressLabel = 'Complete!';
                    this.dispatchEvent(new ShowToastEvent({
                        message: this.fileName + ' ( Compressed to: ' +this.fileSize + ' ) saved successfully!',
                        variant: 'success'
                    }));
                    this.isLoading = false;
                    let replacedDoc = false;
                    if(this.contentDocumentId && this.parentRecordId) {
                        this.deleteDoc(this.contentDocumentId,this.parentRecordId);
                        replacedDoc = true;
                    }
                    let payload = {docId : attachId, replacedDoc : replacedDoc};
                    console.log('fire with pl=',payload);
                    const evt = new CustomEvent('fileuploaded', {detail: {payload}});
                    this.dispatchEvent(evt);
                }
            })
            .catch(error => {
                this.error =  reduceErrors(error);
                this.showToast('','error uploading file='+this.error,'error');
                console.error('Error: ', error);
                this.isLoading = false;
            })
            .finally(()=>{
                console.log('---> finally!');
            })
    }
    deleteDoc(docId,meterId) {
        let params = {docId : docId, parentRecordId : meterId};
        deleteDocument( params )
            .then(dto => {
                console.log('--> returned dto from deleteDoc='+JSON.stringify(dto));
                if (dto.isSuccess) {
                    //
                }
            })
            .catch( error => {
                this.error = reduceErrors(error);
                this.showToast('','Problem deleting doc: '+this.error,'error');
                console.error(this.error);
            });
    }
    /**
     * Loads font awesome js and css for fonts not available in SLDS.
     */
    loadFontAwesome() {
        //alert('calling load fa');
        Promise.all([
            //loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/style.css'),
        ])
            .then(() => {
                console.log('fa loaded');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }
    loadCompressor() {
        loadScript(this, COMPRESSOR + '/dist/compressor.js')
            .then(() => {
                //console.log('compressor loaded!');
            })
            .catch(error => {
                alert(error);
            });
    }


    formatBytes(bytes,decimals) {
        if(bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
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
     * Takes the file and compresses it and then initiates a save
     * @param file  The raw html5 file given to use by the input
     */
    compressIt(file) {
        let _self = this;
        console.log('---> compressIt quality='+this.imgCompressionRatio);
        new Compressor(file, {
            quality: this.imgCompressionRatio,
            success(result) {
                
                _self.saveFile(result);
            },
            error(err) {
                console.log(err.message);
            },
        });
    }

}