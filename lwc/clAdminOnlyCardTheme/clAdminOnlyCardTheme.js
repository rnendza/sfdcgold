/**
 * Note the use of ref to pass the module's this context into the helper function.
 * @type {{animateSection(*=, *=, *): void}}
 */
export const themeOverrider = {

    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     */
    buildAdminCardOverrideCss(ref) {
        let css = '';
        css += '.accel-admin-only-card .slds-card { ';
        css += '  color:black!important;background-color: rgb(243,242,242); ';
        css += '} '
        css += '.accel-admin-only-card .slds-card__header {';
        css += '    background-color:black; color:white;padding-bottom:.35rem;padding-top:.40rem;border-top-right-radius:5px;border-top-left-radius:5px;';
        css += '} ';
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector('.fake-sfdc-admin-card-overrides-class');
        if(target) {
            if(!target.contains(style)) {
                target.appendChild(style);
            }
            //ref._hasOverrodeSfdcCss = true;
        }
    },
    getCardTitleStyle(ref) {
        return 'font-size:.80em';
    }
}