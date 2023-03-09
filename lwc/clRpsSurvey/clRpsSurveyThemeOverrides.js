/**
 * Note the use of ref to pass the module's this context into the helper function.
 * @type {{animateSection(*=, *=, *): void}}
 */
export const themeOverrider = {

    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     */
    buildFormOverrideCss(ref) {
        let css = '';
        css += 'textarea { min-height: '+ref.fieldRteMinHeight + '!important } ';
        css += '.accel-input_override .slds-input {width: 100%;display: inline-block;height: 40px!important; ';
        css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);';
        css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;};';
        css += '.accel-input_override .slds-form-element__label {font-weight:bold!important}';
        css += '.accel-input_override .slds-form-element_stacked {padding:0!important}';
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector('.form-theme-overrides-class');
        if(target) {
            target.appendChild(style);
            ref._hasOverrodeSfdcCss = true;
           // console.log('--> appended custom style');
        } else {
            ref._hasOverrodeSfdcCss = false;
            console.warn('---- no target for overrides in dom');
        }
    }
}