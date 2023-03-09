export const dtHelper = {
    getSyncColumns() {
        let columns = [
            {
                label: 'Date',
                fieldName: 'msgDateTime',
                type: 'date',
                iconName: 'standard:event',
                typeAttributes: {
                    day: 'numeric',
                    month: '2-digit', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                },
                hideDefaultActions: true,
                initialWidth: 185,
                tooltip: {
                    fieldName: 'msgDateTime'
                },
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none', style:'line-height:inherit!important'},
            },
            {
                label: 'Action', fieldName: 'msg',
                initialWidth: 415,
                tooltip: {
                    fieldName: 'msg'
                },
                iconName: 'standard:invocable_action',
                hideDefaultActions: false,
            },
            {
                label: 'Criteria', fieldName: 'criteria',
                tooltip: {
                    fieldName: 'criteria'
                },
                initialWidth: 340,
                iconName: 'standard:filter_criteria_rule',
                hideDefaultActions: false,
            },
        ];
        return columns
    },
    getAsyncColumns() {
        let columns = [
            {
                label: 'Apex Class', fieldName: 'apexClassName',
                tooltip: {
                    fieldName: 'apexClassName'
                },
                initialWidth: 275,
                iconName: 'standard:apex',
                hideDefaultActions: true,
            },
            {
                label: 'Type', fieldName: 'jobType',
                tooltip: {
                    fieldName: 'jobType'
                },
                iconName: 'standard:category',
                initialWidth: 110,
                hideDefaultActions: true,
            },
            {
                label: 'Status', fieldName: 'status',
                tooltip: {
                    fieldName: 'status'
                },
                iconName: 'standard:stage',
                hideDefaultActions: false,
                initialWidth: 145,
            },
            {
                label: 'Batches', fieldName: 'totalJobItems',
                tooltip: {
                    fieldName: 'totalJobItems'
                },
                initialWidth: 75,
                hideDefaultActions: true,
            },
            {
                label: ' Processed', fieldName: 'jobItemsProcessed',
                tooltip: {
                    fieldName: 'jobItemsProcessed'
                },
                initialWidth: 95,
                hideDefaultActions: true,
            },
            {
                label: 'Completion Date',
                fieldName: 'completedDate',
                type: 'date',
                iconName: 'standard:event',
                typeAttributes: {
                    day: 'numeric',
                    month: '2-digit', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                },
                hideDefaultActions: true,
                initialWidth: 195, sortable: true,
                tooltip: {
                    fieldName: 'completedDate'
                },
            },
        ];
        return columns
    },
    getDtClasses() {
        const classes = 'accel-table_button_links slds-table_header-fixed_container slds-border_top slds-no-row-hover ' +
            'slds-max-medium-table_stacked slds-table_bordered slds-table_col-bordered accel-datatable_class accel-condensed_datatable';
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