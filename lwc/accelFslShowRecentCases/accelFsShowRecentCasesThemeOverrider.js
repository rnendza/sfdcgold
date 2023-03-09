export const themeOverrider = {

    /**
     * Gets around LWC shadow DOM limitations.
     */
    overrideSldsCss(ref) {

        let css = '';
        css += '.accel-condensed_datatable .slds-table .slds-button {'
        css += '    line-height:'+ref.tableDataLineHeight;
        css += '}'
        css += '.accel-condensed_datatable slds-table th, .slds-table td {';
        css += '   padding:.05rem';
        css += '}';
        css += '.accel-condensed_datatable .slds-table {';
        css += '   font-size:'+ref.tableDataFontSize;
        css += '}';
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector(ref._sldsDomOverrideSelector);
        if(target) {
            if(!target.contains(style)) {
                ref._hasOverrodeTheme = true;
                target.appendChild(style);
            }
        }
    }
}