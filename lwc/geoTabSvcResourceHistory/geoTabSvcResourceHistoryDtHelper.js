export const dtHelper = {
    getServiceResourceHistoryColumns() {
        let columns = [
            {
                label: 'Date', fieldName: 'createdDate',type: 'date',
                typeAttributes:{day:'numeric',month:'2-digit',year:'numeric',
                    hour:'2-digit',minute:'2-digit',second:'2-digit',hour12:true},
                initialWidth: 185,
                iconName: 'standard:event',

            },
            {
                label: 'User', fieldName: 'createdByName', sortable: true,
                tooltip: {
                    fieldName: 'createdByName'
                },
                initialWidth: 160,
                hideDefaultActions: false,
                iconName: 'standard:user'
            },
            {
                label: 'Field', fieldName: 'fieldApiName', sortable: true,
                tooltip: {
                    fieldName: 'fieldApiName'
                },
                hideDefaultActions: false
            },
            {
                label: 'Original Value', fieldName: 'oldValue', sortable: true,
                tooltip: {
                    fieldName: 'oldValue'
                },
                hideDefaultActions: false
            },
            {
                label: 'New Value', fieldName: 'newValue', sortable: true,
                tooltip: {
                    fieldName: 'newValue'
                },
                hideDefaultActions: false
            },
            // {
            //     label: 'Service Resource',
            //     fieldName: 'sfdcUrl',
            //     iconName: "standard:service_resource",
            //     type: 'url',
            //     typeAttributes: {label: { fieldName: 'sfdcName' }, target: '_blank'},
            //     sortable: true
            // },
            // {
            //     label: 'Device Id', fieldName: 'deviceId', sortable: true,
            //     tooltip: {
            //         fieldName: 'deviceId'
            //     },
            //     initialWidth: 95,
            //     hideDefaultActions: true
            // },
            // {
            //     label: 'Latitude', fieldName: 'latitude', sortable: true,
            //     tooltip: {
            //         fieldName: 'latitude'
            //     },
            //     initialWidth: 145,
            //     hideDefaultActions: true
            // },
            // {
            //     label: 'Longitude', fieldName: 'longitude', sortable: true,
            //     tooltip: {
            //         fieldName: 'longitude'
            //     },
            //     initialWidth: 145,
            //     hideDefaultActions: true
            // },

        ];
        return columns
    },
    getDtClasses() {
        const classes = 'slds-table_header-fixed_container slds-border_top slds-no-row-hover slds-max-medium-table_stacked slds-table_bordered';
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