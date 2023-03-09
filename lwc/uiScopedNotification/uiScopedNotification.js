import { LightningElement, api,track } from 'lwc';
import anime from 'c/anime';
export default class UiScopedNotification extends LightningElement {

    @api message = 'Your message here';
    @api customIconSize = 'small';
    @api theme = '';
    @api customClass = '';
    @api iconName = 'utility:info';
    @api showAsLink = false;
    @api name="vehicle_alert";
    @api animate = false;
    @api dismissible = false;

    @api
    set iconVariant(val) {
        this._iconVariant = val;
    }
    get iconVariant() {
        if(!this._iconVariant) {
            if (this.theme == 'dark' || this.theme =='error') {
                this._iconVariant = 'inverse';
            }
        }
        return this._iconVariant;
    }

    @track isClosed = false;

    _hasRendered;
    _iconVariant

    handleContainerClick(evt) {
        this.dispatchEvent( new CustomEvent('alertcontainerclicked', {detail: { name: this.name }}) );
    }

    handleLinkClick(evt) {
        evt.preventDefault();
        this.dispatchEvent( new CustomEvent('alertlinkclicked', {detail: { name: this.name }}) );
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            let divId = 'alertcontainer';
            let ele = this.template.querySelector("div[data-id="+divId+"]");
            anime({
                targets: ele,
                easing: 'linear',
                duration: 1000,
                delay:800,
                autoplay: false
            });
        }
    }
    handleClose(evt) {
        evt.preventDefault();
        this.dispatchEvent( new CustomEvent('alertcontainerdismissed', {detail: { name: this.name }}) );
        this.isClosed = true;
    }

    get scopedNotificationClass() {
        let className = null;
        className = 'slds-scoped-notification slds-media slds-media_center';
        switch (this.theme) {
            case 'light':
                className += ' slds-scoped-notification_light';
                break;
            case 'dark':
                className += ' slds-scoped-notification_dark';
                break;
            case 'warning':
                className += ' slds-theme_warning';
                break;
            case 'success':
                className += ' slds-theme_success slds-notify_success slds-alert_success ';
                break;
            case 'error':
                className += ' slds_theme_error slds-notify_alert slds-alert_error';
                break;
            default:
               // no theme. just take on bg color of parent!
        }
        if(this.customClass) {
            className += ' '+this.customClass;
        }
        return className;
    }

    get closeIconVariant() {
        let iconVariant = null;
        if (this.theme == 'dark' || this.theme =='error' || this.theme =='success') {
            iconVariant = 'inverse';
        }
        return iconVariant;
    }
}