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
        css += '.accel-status-published {';
        css += '    color:green;';
        css += '} ';
        css += '.accel-status-uploaded {';
        css += '    color:orange;';
        css += '} ';
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector('.fake-sfdc-overrides-class');
        if(target) {
            target.appendChild(style);
            ref._hasOverrodeSfdcCss = true;
            console.log('--> appended custom style');
        } else {
            ref._hasOverrodeSfdcCss = false;
            console.warn('---- no target for overrides in dom');
        }
    }
}