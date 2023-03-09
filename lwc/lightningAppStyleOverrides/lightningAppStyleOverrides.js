import {LightningElement} from 'lwc';

export default class LightningAppStyleOverrides extends LightningElement {

    _hasRendered = false;

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            this.buildLightningAppPageThemeOverrides();
        }
    }
    /**
     * override the lightning app Header and anything e`lse here.
     */
    buildLightningAppPageThemeOverrides() {
        let css = ' header.flexipageHeader.slds-page-header.uiBlock.oneAnchorHeader {';
        css += '        display: none;';
        css +='     }';
        css +='flexipageComponent:not(:last-child):not(:empty) {margin-bottom:0}';
        css += ' app_flexipage-lwc-app-flexipage > app_flexipage-lwc-app-flexipage-decorator > app_flexipage-header > div {'
        css += '  display:none; ';
        css += ' } ';
        css += '.slds-template_default {padding-top:0 }';
        const style = document.createElement('style');
        style.innerText = css;
        try {
            let target = this.template.querySelector('.fake-app-page-theme-overrides-class');
            target.appendChild(style);
        } catch (e) {
            console.error(e);
        }
    }
}