export const dtHelper = {
    getLogsColumns() {
        let columns = [
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
                label: 'Login Type', fieldName: 'loginType', sortable: true,
                tooltip: {
                    fieldName: 'loginType'
                },
                hideDefaultActions: false
            },
            {
                label: 'Session Type', fieldName: 'sessionType', sortable: true,
                tooltip: {
                    fieldName: 'sessionType'
                },
                hideDefaultActions: false
            },
            {
                label: 'Platform', fieldName: 'loginHistoryPlatformAndBrowser', sortable: true,
                tooltip: {
                    fieldName: 'loginHistoryPlatformAndBrowser'
                },
                hideDefaultActions: true
            },
            {
                label: 'City', fieldName: 'city', sortable: true,
                tooltip: {
                    fieldName: 'numSecondsValid'
                },
                initialWidth: 125,
                hideDefaultActions: true
            },
            {
                label: 'Ip', fieldName: 'sourceIp', sortable: true,
                tooltip: {
                    fieldName: 'sourceIp'
                },
                initialWidth: 115,
                hideDefaultActions: true
            },
            {
                label: 'Login Time',
                fieldName: 'loginTime',
                type: 'date',
                typeAttributes: {
                    // day: 'numeric',
                    // month: '2-digit', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                },
                ideDefaultActions: true,
                initialWidth: 115, sortable: true,
                tooltip: {
                    fieldName: 'loginType'
                },
            },
            {
                label: 'Last Mod',
                fieldName: 'lastModifiedDate',
                type: 'date',
                typeAttributes: {
                    // day: 'numeric',
                    // month: '2-digit', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                },
                ideDefaultActions: true,
                initialWidth: 115, sortable: true,
                tooltip: {
                    fieldName: 'lastModifiedDate'
                },
            },
            // {
            //     label: '# Secs Valid', fieldName: 'numSecondsValid', sortable: true,
            //     tooltip: {
            //         fieldName: 'numSecondsValid'
            //     },
            //     initialWidth: 85,
            //     hideDefaultActions: true
            // },
        ];
        return columns
    },
    // getDtClasses() {
    //     const classes = 'slds-table_header-fixed_container slds-border_top slds-no-row-hover slds-max-medium-table_stacked slds-table_bordered';
    //     return classes;
    // },
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