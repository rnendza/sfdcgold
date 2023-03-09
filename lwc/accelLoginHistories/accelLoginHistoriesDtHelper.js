export const dtHelper = {
    getAuditTrailsColumns() {
        let columns = [
            {
                label: 'Login time',
                fieldName: 'loginTime',
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
                    fieldName: 'loginTime'
                },
            },
            {
                label: 'User',
                fieldName: 'userLink',
                iconName: "standard:user",
                type: 'url',
                initialWidth: 135,
                typeAttributes: {label: {fieldName: 'userFullName'}, target: '_blank'},
                sortable: true,
                hideDefaultActions: false,
                tooltip: {
                    fieldName: 'userFullName'
                },
            },
            {
                label: 'IP', fieldName: 'sourceIp', sortable: true,
                iconName: "custom:custom63",
                tooltip: {
                    fieldName: 'sourceIp'
                },
                initialWidth: 115,
                hideDefaultActions: true
            },
            {
                label: 'Location', fieldName: 'location', sortable: true,
                iconName: "standard:location",
                tooltip: {
                    fieldName: 'location'
                },
                hideDefaultActions: false
            },
            {
                label: 'Status', fieldName: 'loginStatus', sortable: true,
                iconName: "standard:stage",
                tooltip: {
                    fieldName: 'loginStatus'
                },
                hideDefaultActions: false
            },
            {
                label: 'Platform', fieldName: 'platform', sortable: true,
                iconName: "standard:bot",
                tooltip: {
                    fieldName: 'platform'
                },
                hideDefaultActions: false
            },
            {
                label: 'Login URL', fieldName: 'loginUrl', sortable: true,
                iconName: "standard:address",
                tooltip: {
                    fieldName: 'loginUrl'
                },
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