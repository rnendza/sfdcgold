import {LightningElement} from 'lwc';

/**
 * @see https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.mobile_disable_pull_to_refresh_in_the_mobile_app
 */
export default class UiDisablePullToRefresh extends LightningElement {

    connectedCallback() {
        this.disablePullToRefresh();
    }

    disablePullToRefresh () {
        const disable_ptr_event = new CustomEvent("updateScrollSettings", {
            detail: {
                isPullToRefreshEnabled: false
            },
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(disable_ptr_event);
    }
}