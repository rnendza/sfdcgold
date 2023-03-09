import {LightningElement,wire,track,api} from 'lwc';
import {loadScript, loadStyle} from 'lightning/platformResourceLoader';
import { getConstants } from 'c/clConstantUtil';
import COMETD from '@salesforce/resourceUrl/cometd_319';
import getSessionId from '@salesforce/apex/clPublicController.getSessionId';

const GLOBAL_CONSTANTS = getConstants();
const CLASS_NAME = '/lwc/clExpCloudEventSubscriber';

export default class ClExpCloudEventSubscriber extends LightningElement {

    @api channel;
    @api apiVersion;
    @api cometdLogLevel;

    @track sessionId;
    @track error;

    _cometdInitialized;
    _cometd;

    constructor() {
        super();
        console.info('%c----> '+CLASS_NAME,GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    connectedCallback() {
        this.apiVersion = '53.0';
    }

    /**
     * We need to get the users sessionID (server side) to pass to the SFDC cometd......
     * @param error
     * @param data
     */
    @wire(getSessionId)
    wiredSessionId({ error, data }) {
        if (data) {
            this.sessionId = data;
            this.error = undefined;
            this.loadCometd();
        } else if (error) {
            console.log(error);
            this.error = error;
            this.sessionId = undefined;
        }
    }

    /**
     * (1) Fire up org.cometd.CometD().
     * (2) Call cometd.configure().
     * (3) Call cometd.handshake().
     * (4) Call cometd.subscribe().
     */
    initCometd() {
        if(this._cometdInitialized) {
            return;
        }
        this._cometd = new window.org.cometd.CometD();
        this._cometdInitialized = true;
        this.configCometd();
        this._cometd.websocketEnabled = false;
    }

    /**
     * Configure url and auth for cometd.
     */
    configCometd() {

        let url = window.location.protocol + '//' + window.location.hostname + '/cometd/'+this.apiVersion+'/';
        let reqHeaders = { Authorization: 'OAuth ' + this.sessionId};
        let config = {
            url:url,
            requestHeaders: reqHeaders,
            appendMessageTypeToURL: false,
            logLevel: this.cometdLogLevel
        }

        this._cometd.configure(config);
        this._cometd.websocketEnabled = false;
        this.handshake();
    }

    /**
     * Perform cometd handshake and subscribe.
     */
    handshake() {
        if(this.channel) {
            this._cometd.handshake(status => {
                console.log('---> channel name=' + this.channel);
                if (status.successful) {
                    this.subscribe();
                } else {
                    console.error('--> '+CLASS_NAME+ ' error in handshaking:' + JSON.stringify(status));
                }
            });
        } else {
            console.error('--> '+CLASS_NAME+' please supply a channel name!');
        }
    }

    /**
     * subscribe to messages from channel.
     */
    subscribe() {
        this._cometd.subscribe('/event/'+ this.channel, (msg) => {
            console.log('in subs got message='+JSON.stringify(msg));
            const evt = new CustomEvent('messagereceived', { detail: msg });
            this.dispatchEvent(evt);
        });
    }

    /**
     * Load the cometD Lib.
     */
    loadCometd() {
        console.log('---> loading cometDLib');
        Promise.all([
            loadScript(this, COMETD + '/js/cometd.js')
        ]).then(() => {
            console.log('--> cometDLoaded');
            this.initCometd();
        }).catch(error => {
            console.error(error);
        });
    }
}