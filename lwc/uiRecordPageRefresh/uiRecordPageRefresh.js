import {LightningElement, api} from 'lwc';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

/**
 * Helps mitigate 403:Unknown Client errors upon subscription. Generally prevents handshaking from failing
 * on subscription to the Platform event prior to the connection being established.
 *
 * @todo see if SFDC fixes this. not the best solution but it's more on their site.
 */
//
const SUBSCRIBE_DELAY_SECONDS = 2;

export default class UiRecordPageRefresh extends LightningElement {

    @api recordId;

    _recordUpdatedEvents                    = [];
    _allSubscriptions                       = [];
    _recordUpdatedChannelName               = '/event/Record_Updated_Event__e';

    /**
     * Initialize the component.
     */
    connectedCallback() {
        // setTimeout( () =>{
            this.handleSubscribe(this._recordUpdatedChannelName);
            this.registerErrorListener();
        // },SUBSCRIBE_DELAY_SECONDS * 1000);
    }

    /**
     * Fires when a cmp is removed from the DOM. Unsubscribe from Platform Event.
     */
    disconnectedCallback() {
        console.log(' disconnected callback =========');
        this.handleUnsubscribeAll();
    }

    /**
     * Subscribe to the Platform Event.
     * @param channelName
     */
    handleSubscribe( channelName ) {
        var _self = this;
        console.log(' in handle subscribe..');
        const messageCallback = function (response) {
            console.log('New message received : ' + JSON.stringify(response));
            try {
                let pe = response;
                if (pe.channel === _self._recordUpdatedChannelName) {
                    console.log(pe.channel + ' PE = ' + JSON.stringify(pe));
                    _self._recordUpdatedEvents.push(pe);
                    const payload = pe.data.payload;
                    _self.observeUpdatePayload(payload);
                } else {
                    console.log('accel: invalid channel pe=' + JSON.stringify(pe.channel));
                }
            } catch (e) {
                console.log('accel: error 1');
                console.error(e);
            }
        };
        console.log(' attempting subscribe to channel ' + channelName);
        subscribe(channelName, -1, messageCallback).then(response => {
            console.log('Successfully subscribed to : ', JSON.stringify(response));
            this._allSubscriptions.push(response);
        });
    }

    /**
     * Observe the payload of the Platform Event, if it contains a recordId that is equal to the current record page
     * Id in ctx, force a refresh of cache.
     *
     * @param payload
     */
    observeUpdatePayload(payload) {
        if (payload.Record_Ids__c) {
            try {
                let arrIds = payload.Record_Ids__c.split(',');
                if (arrIds.includes(this.recordId)) {
                    console.log('has it!');
                    // Notify LDS that you've changed the record outside its mechanisms.
                    getRecordNotifyChange([{recordId: this.recordId}]);
                }
            } catch (e) {
                console.error(e);
            }
        }
    }

    /**
     * Called on disconnected callback. Unsubscribes from Platform Event.
     */
    handleUnsubscribeAll() {
        try {
            if (this._allSubscriptions && this._allSubscriptions.length > 0) {
                for (let i = 0; i < this._allSubscriptions.length; i++) {
                    let sub = this._allSubscriptions[i];
                    unsubscribe(sub, response => {
                        console.log('unsubscribe() response: ', JSON.stringify(response));
                    });
                }
            }
        } catch (e) {
            console.error(JSON.stringify(e));
        }
    }

    /**
     * If this gets called it might be a 403.. check to ensure the user has read access to the PE!
     */
    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            console.log('Received error from server..', JSON.stringify(error));
        });
    }
}