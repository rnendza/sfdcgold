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
        css += '.accel-scoped-tab-set .accel-scoped-tab, .slds-tabs_scoped__content, .slds-tabs--scoped__content {  ';
        css += ' padding-top:0;padding-bottom:0;';
        css += '}';
        css += '.accel-scoped-tab-set .accel-scoped-tab, .slds-tabs_scoped__nav, .slds-tabs--scoped__nav {  ';
        css += ' font-size:.90em';
        css += '}';
        css += '.accel-tab-set .accel-tab, .slds-tabs_default__nav, slds-tabs--default__nav {  ';
        css += ' font-size:.90em';
        css += '}';
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector('.fake-sfdc-overrides-class');
        if(target) {
            target.appendChild(style);
            ref._hasOverrodeSfdcCss = true;
        } else {
            ref._hasOverrodeSfdcCss = false;
        }
    }
}