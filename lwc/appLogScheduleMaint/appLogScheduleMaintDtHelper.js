export const dtHelper = {
    getJobsColumns() {
        const rowActions = [
            { label: 'Abort', name: 'abort' },
        ];
        let columns = [

            {
                label: 'Job Name', fieldName: 'jobName', sortable: true,
                tooltip: {
                    fieldName: 'jobName'
                },
                initialWidth:  150,
                hideDefaultActions: false
            },
            {
                label: 'Class Name', fieldName: 'apexClassName', sortable: true,
                tooltip: {
                    fieldName: 'apexClassName'
                },
                hideDefaultActions: false
            },
            {
                label: 'Status', fieldName: 'status', sortable: true,
                tooltip: {
                    fieldName: 'status'
                },
                initialWidth: 105,
                hideDefaultActions: true
            },
            {
                label: 'State', fieldName: 'state', sortable: true,
                tooltip: {
                    fieldName: 'state'
                },
                initialWidth: 105,
                hideDefaultActions: true
            },
            {
                label: 'Next Fire', fieldName: 'nextFireTime',type: 'date',
                typeAttributes:{day:'numeric',month:'2-digit',year:'numeric',
                    hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
                initialWidth: 185,
            },
            {
                label: 'Start Time', fieldName: 'startTime',type: 'date',
                typeAttributes:{day:'numeric',month:'2-digit',year:'numeric',
                    hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
                initialWidth: 185,
            },
            {
                type: 'action',
                typeAttributes: { rowActions: rowActions },
            },
        ];
        return columns
    },
    getDtClasses() {
        const classes = 'slds-table_header-fixed_container slds-border_top slds-no-row-hover ' +
            'slds-max-medium-table_stacked slds-table_bordered slds-table_col-bordered';
        return classes;
    },
    sortData(fieldname, direction,dtData) {
        // Return the value stored in the field
        let parseData = [...dtData];

        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
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