/**
 * Note the use of ref to pass the module's this context into the helper function.
 * @type {{animateSection(*=, *=, *): void}}
 */
export const themeOverrider = {

    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     */
    buildSfdcCoreOverrideCss(ref) {
        let css = '';
        css += '.accel-menu-button_override, .slds-button_icon-more {';
        css += '    width: '+ref._imageWidth+'px!important;color:rgb(91,214,255);background-color:black;justify-content:flex-end;';
        css += '    height:30px;padding-right:.3rem;border-color:black;border-bottom-right-radius:0!important;';
        css += '    border-bottom-left-radius:0!important';
        css += '} ';
        css += '.accel-meter-badge-wrapper, .slds-badge { ';
        css += '   font-weight:normal!important; ';
        css += '}';
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector('.fake-sfdc-overrides-class');
        if(target) {
            target.appendChild(style);
            ref._hasOverrodeSfdcCss = true;
        } else {
            ref._hasOverrodeSfdcCss = false;
            console.warn('---- no target for overrides in dom');
        }
    }
}