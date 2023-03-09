export const dtHelper = {
    getNotificationsColumns() {
        let columns = [
            {   label: 'Name',
                fieldName: 'recordName',
                type: 'button',
                sortable: true,
                typeAttributes: {
                    name: 'viewNotificationSent',
                    value: 'viewNotificationSent',
                    label: { fieldName: 'recordName' },
                    variant: 'base'
                },
                hideDefaultActions: false,
            },
            {
                label: 'Sent Date',
                fieldName: 'sentDate',
                type: 'date',
                typeAttributes: {
                    day: 'numeric',
                    month: '2-digit', year: 'numeric',
                    hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true
                },
                hideDefaultActions: true,
                sortable: true,
                tooltip: {
                    fieldName: 'createdDate'
                },
            },
            {
                label: 'Sent to',
                fieldName: 'recipientName',
                sortable: true,
                hideDefaultActions: false,
            },
            // {
            //     label: 'Alert Type',
            //     fieldName: 'alertType',
            //     sortable: true,
            //     hideDefaultActions: false,
            // },
            // {
            //     label: 'Title',
            //     fieldName: 'msgTitle',
            //     sortable: true,
            //     hideDefaultActions: false,
            // },
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