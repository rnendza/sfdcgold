import {LightningElement, track, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import retrieveVideoMetadata from '@salesforce/apex/VideoController.retrieveVideoMetadata';
import AccelUtilsSvc from 'c/accelUtilsSvc';

const VIDEO_METADATA                        = 'VIDEO_METADATA';
const VIDEO_SETTINGS_COMMUNITY_RECORDTYPE   = 'Community';
const SUCCESS_VARIANT                       = 'success';
const ERROR_VARIANT                         = 'error';

export default class AcVideoPlayer extends LightningElement {

    @api    videoId;
    @api
    get showVideo() {
        return this.videoId && this.videoMetadataLoaded; //  Show after we have metadata and a videoId
    }
    @api
    get iFrameSource() {
        return this.endPoint + this.videoId;  //  https://player.vimeo.com/video/[vimeoid]
    }

    @track  processing = true;
    @track  iFrameAllowSettings;            //  Populated via custom Mdt
    @track  iFrameInitialWidth = "640";
    @track  iFrameInitialHeight = "427";    //  Must do for an iframe. will be changed by css to be responsive
    @track  wiredVideoMetadata;
    @track  videoMetadataLoaded = false;
    @track  endPoint;                       //  Populated via custom Mdt

    _debugConsole = true;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _hasRendered = false;
    _videoMetaData;
    _settingsRecord = VIDEO_SETTINGS_COMMUNITY_RECORDTYPE;

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
        }
    }

    @wire(retrieveVideoMetadata, {settingsRecord: '$_settingsRecord'})
    wiredRetrieveVideoMetadata(wiredVideoMetaData) {
        this.processing = false;
        this.wiredVideoMetadata = wiredVideoMetaData;
        const {data, error} = this.wiredVideoMetadata;
        if (data) {
            if (data.isSuccess) {
                this._videoMetaData = this._accelUtils.getMapValue(VIDEO_METADATA, data.values);
                if (this._videoMetaData && this._videoMetaData.Endpoint__c) {
                    this.endPoint = this._videoMetaData.Endpoint__c;
                    this.iFrameAllowSettings = this._videoMetaData.iFrameAllowSettings__c;
                    this.videoMetadataLoaded = true;
                }
            } else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        message: dto.message,
                        variant: dto.severity,
                    }),
                );
            }
        } else if (error) {
            this.showToast(JSON.stringify(error),ERROR_VARIANT);
            this.accounts = undefined;
        }
    }
    handleVideoSelected(event) {
        if(event.detail && event.detail.value) {
            this.videoId = event.detail.value;
            //  @todo remove pw prompt
            this.showToast('pw is accel1wins',SUCCESS_VARIANT);
        }
    }
    /**
     * @param msg   The Msg to display in the toast.
     * @variant [warning,error,success]
     * @TODO move to utils
     */
    showToast(msg, variant) {
        const evt = new ShowToastEvent({
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}