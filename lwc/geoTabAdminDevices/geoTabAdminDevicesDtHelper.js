export const dtHelper = {
    getDevicesColumns() {
        let columns = [
            {
                label: 'Service Resource',
                fieldName: 'sfdcUrl',
                iconName: "standard:service_resource",
                type: 'url',
                typeAttributes: {label: { fieldName: 'sfdcName' }, target: '_blank'},
                sortable: true
            },
            {
                label: 'Device Id', fieldName: 'id', sortable: true,
                tooltip: {
                    fieldName: 'id'
                },
                initialWidth: 90,
                hideDefaultActions: true
            },
            {
                label: 'Serial #', fieldName: 'serialNumber', sortable: true,
                tooltip: {
                    fieldName: 'serialNumber'
                },
                initialWidth: 155,
                hideDefaultActions: true
            },
            {
                label: 'VIN', fieldName: 'vehicleIdentificationNumber', sortable: true,
                tooltip: {
                    fieldName: 'vehicleIdentificationNumber'
                },
                // initialWidth: 185,
                hideDefaultActions: true
            },
            {
                label: 'Name', fieldName: 'name', sortable: true,
                tooltip: {
                    fieldName: 'name'
                },
                // initialWidth: 185,
                hideDefaultActions: true
            },
            {
                label: 'Major', fieldName: 'major', sortable: true,
                tooltip: {
                    fieldName: 'major'
                },
                 initialWidth: 105,
                hideDefaultActions: true
            },
            {
                label: 'Minor', fieldName: 'minor', sortable: true,
                tooltip: {
                    fieldName: 'minor'
                },
                initialWidth: 105,
                hideDefaultActions: true
            },
        ];
        return columns
    },
    getUserDtClasses() {
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