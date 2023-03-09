/**
 * Note the use of ref to pass the module's this context into the helper function.
 * @type {{animateSection(*=, *=, *): void}}
 */
export const themeOverrider = {

    /**
     * Gets around LWC shadow DOM limitations.
     */
    buildSfdcCoreOverrideCss(ref) {
        let css = '';

    //.slds-form-element__ico
        css += '.accel-help-text-override, .slds-form-element__icon {';
        css += '   padding-top:0!important; ';
        css += '} ';
        css += '.accel-tile_title-override .slds-tile__title {';
        css += '   font-weight:bold!important; ';
        css += '} ';

        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector('.fake-sfdc-overrides-class');
        if(target) {
            target.appendChild(style);
            ref._hasOverrodeSfdcCss = true;
            console.info('---- fired css override');
        } else {
            ref._hasOverrodeSfdcCss = false;
            console.warn('---- no target for overrides in dom');
        }
    }
}