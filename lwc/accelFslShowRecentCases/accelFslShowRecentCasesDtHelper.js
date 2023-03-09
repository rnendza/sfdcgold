export const dtHelper = {
    getCasesColumns(ref) {
        let columns = [
            {
                label: 'Created Date',
                fieldName: 'createdDate',
                type: 'date',
                sortable: ref.allowColumnSort,
                iconName: ref.showColHeaderIcons ? 'standard:event' : null,
                typeAttributes:{day:'numeric',month:'2-digit',year:'numeric',
                    hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
                initialWidth: 160,
                tooltip: {
                    fieldName: 'createdDate'
                },
                hideDefaultActions: true,
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none', style:'line-height:inherit!important'},
            },
            {   label: 'Case #',
                fieldName: 'caseNumber',
                type: 'button',
                sortable: ref.allowColumnSort,
                typeAttributes: {
                    name: 'viewCase',
                    value: 'viewCase',
                    label: { fieldName: 'caseNumber' },
                    variant: 'base'
                },
                cellAttributes: {
                    class: 'slds-p-vertical_none slds-m-vertical_none',
                    style:'line-height:0!important'
                },
                hideDefaultActions: false,
                initialWidth: 75,
            },
            {
                label: 'Status',
                fieldName: 'status',
                sortable: ref.allowColumnSort,
                type: 'string',
                tooltip: {
                    fieldName: 'status'
                },
                initialWidth: 90,
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none', style:'line-height:inherit!important'},
            },
            {   label: 'Resource',
                fieldName: 'assignedResourceName',
                type: 'button',
                sortable: ref.allowColumnSort,
                iconName: ref.showColHeaderIcons ? 'standard:user' : null,
                typeAttributes: {
                    name: 'viewAssignedResource',
                    value: 'viewAssignedResource',
                    label: { fieldName: 'assignedResourceName' },
                    variant: 'base'
                },
                cellAttributes: {
                    class: 'slds-p-vertical_none slds-m-vertical_none',
                    style:'line-height:0!important'
                },
                initialWidth: 120,
            },
            {
                label: 'Svc Category',
                fieldName: 'serviceCategory',
                sortable: ref.allowColumnSort,
                type: 'string',
                tooltip: {
                    fieldName: 'serviceCategory'
                },
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none', style:'line-height:inherit!important'},
            }
        ];
        return columns
    },
    getDtClasses() {
        const classes = 'accel-table_button_links slds-table_header-fixed_container slds-border_top slds-no-row-hover ' +
            'slds-max-medium-table_stacked slds-table_bordered accel-datatable_class accel-condensed_datatable';
        return classes;
    },
    sortData(fieldname, direction, dtData) {
        // Return the value stored in the field
        let parseData = [...dtData];

        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        return parseData;
    },
}