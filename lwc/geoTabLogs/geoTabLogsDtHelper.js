export const dtHelper = {
    getLogsColumns() {
        let columns = [
            {
                label: 'Log #',
                fieldName: 'sfdcUrl',
                iconName: "standard:logging",
                type: 'url',
                initialWidth: 105,
                typeAttributes: {label: {fieldName: 'sfdcName'}, target: '_blank'},
                sortable: true,
                hideDefaultActions: true,
                tooltip: {
                    fieldName: 'logLinkTooltip'
                },
            },
            {
                label: 'Job Name', fieldName: 'jobName', sortable: false,
                tooltip: {
                    fieldName: 'jobName'
                },
                initialWidth: 175,
                hideDefaultActions: true
            },
            {
                label: 'Job Type', fieldName: 'jobType', sortable: false,
                tooltip: {
                    fieldName: 'jobType'
                },
                initialWidth: 100,
                hideDefaultActions: true
            },
            {
                label: 'Job Status', fieldName: 'jobStatus', sortable: true,
                tooltip: {
                    fieldName: 'jobStatus'
                },
                initialWidth: 95,
                hideDefaultActions: true,
                cellAttributes: {
                    class: {fieldName: 'jobStatusCls'},
                }
            },
            {
                label: 'Start Date', fieldName: 'processStartDate',type: 'date',
                typeAttributes:{day:'numeric',month:'2-digit',year:'numeric',
                    hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
                initialWidth: 175,sortable: true,
            },
            {
                label: 'End Date', fieldName: 'processEndDate',type: 'date',
                typeAttributes:{day:'numeric',month:'2-digit',year:'numeric',
                    hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
                initialWidth: 175,sortable: true,
            },
            {
                label: 'Selected', fieldName: 'totalRecordsSelected', sortable: true,
                tooltip: {
                    fieldName: 'totalRecordsSelected'
                },
                initialWidth: 85,
                hideDefaultActions: true,
            },
            {
                label: 'Processed', fieldName: 'totalRecordsProcessed', sortable: true,
                tooltip: {
                    fieldName: 'totalRecordsProcessed'
                },
                initialWidth: 85,
                hideDefaultActions: true
            },
            {
                label: 'Updated', fieldName: 'totalRecordsUpdated', sortable: true,
                tooltip: {
                    fieldName: 'totalRecordsUpdated'
                },
                initialWidth: 85,
                hideDefaultActions: true
            },
            {
                label: 'Failed', fieldName: 'totalRecordsFailed', sortable: true,
                tooltip: {
                    fieldName: 'totalRecordsFailed'
                },
                initialWidth: 85,
                hideDefaultActions: true
            },
        ];
        return columns
    },
    getDtClasses() {
        const classes = 'slds-table_header-fixed_container slds-border_top slds-no-row-hover slds-max-medium-table_stacked slds-table_bordered';
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