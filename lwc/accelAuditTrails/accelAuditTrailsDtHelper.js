export const dtHelper = {
    getAuditTrailsColumns() {
        let columns = [
            {
                label: 'Created Date',
                fieldName: 'createdDate',
                type: 'date',
                iconName: 'standard:event',
                typeAttributes: {
                    day: 'numeric',
                    month: '2-digit', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                },
                ideDefaultActions: true,
                initialWidth: 175, sortable: true,
                tooltip: {
                    fieldName: 'createdDate'
                },
            },
            {
                label: 'User',
                fieldName: 'userLink',
                iconName: "standard:user",
                type: 'url',
                initialWidth: 135,
                typeAttributes: {label: {fieldName: 'createdByFullName'}, target: '_blank'},
                sortable: true,
                hideDefaultActions: false,
                tooltip: {
                    fieldName: 'createdByFullName'
                },
            },
            {
                label: 'Section', fieldName: 'section', sortable: true,
                tooltip: {
                    fieldName: 'section'
                },
                initialWidth: 200,
                iconName: 'standard:section',
                hideDefaultActions: false
            },
            // {
            //     label: 'Action', fieldName: 'action', sortable: true,
            //     tooltip: {
            //         fieldName: 'action'
            //     },
            //     iconName: 'standard:actions_and_buttons',
            //     hideDefaultActions: false
            // },
            {
                label: 'Action Taken', fieldName: 'display', sortable: true,
                tooltip: {
                    fieldName: 'display'
                },
                iconName: 'standard:actions_and_buttons',
                hideDefaultActions: false
            },
        ];
        return columns
    },
    getDtClasses() {
        const classes = 'slds-table_header-fixed_container slds-border_top slds-no-row-hover ' +
            'slds-max-medium-table_stacked slds-table_bordered slds-table_col-bordered';
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