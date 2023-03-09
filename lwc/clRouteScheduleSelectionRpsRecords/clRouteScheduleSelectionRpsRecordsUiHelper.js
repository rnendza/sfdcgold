export const uiHelper = {

    overrideDatatableStyles(ref) {
        let css = '';

        css += '.accel-datatable-overrides .slds-max-medium-table_stacked .slds-table_bordered tbody td, .slds-table_bordered tbody th, ';
        css += '.slds-table--bordered tbody td, .slds-table--bordered tbody th { ';
        css += '      }';
        css += '.accel-datatable-overrides .slds-max-medium-table_stacked .slds-table_bordered {';
        css += '      background-color:rgb(247,247,247);';
        css += '};'
        let style = document.createElement('style');
        style.innerText = css;
        let target = ref.template.querySelector('.sfdc-datatable-overrides');
        if (target) {
            target.appendChild(style);
        }
    },
    sortBy(field, reverse, primer) {

        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };

    }
}