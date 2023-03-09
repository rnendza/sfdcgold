export const dtHelper = {
    getUserColumns() {
        let columns = [
            { label: 'Advisory #', fieldName: 'paAdvisoryNumber', type: 'button',sortable: true,
                typeAttributes: { name: 'paAdvisoryNumber', value: 'paAdvisoryNumber', label: { fieldName: 'paAdvisoryNumber' },
                    variant: 'base'},
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none', style:'line-height:inherit!important'},
                hideDefaultActions: true,
                // initialWidth: 135,
            },
            {
                label: 'Name', fieldName: 'paFullName', sortable: true,
                tooltip: {
                    fieldName: 'paFullName'
                },
                // initialWidth: 185,
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' },
                hideDefaultActions: true
            },
            {
                label: 'City', fieldName: 'paCity', sortable: true,
                tooltip: {
                    fieldName: 'paCity'
                },
                // initialWidth: 150,
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' },
                hideDefaultActions: true
            },
            {
                label: 'Advisory Dt', fieldName: 'paAdvisoryDate', sortable: true,
                // initialWidth: 135,
                hideDefaultActions: true,
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' },
                tooltip: {
                    fieldName: 'paAdvisoryDate'
                },
                type: 'date-local',
                typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                },
            },
            {
                label: 'Request Dt', fieldName: 'paRequestDate', sortable: true,
                // initialWidth: 135,
                hideDefaultActions: true,
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' },
                tooltip: {
                    fieldName: 'paRequestDate'
                },
                type: 'date-local',
                typeAttributes: {
                    year: "numeric",
                    month: "2-digit",
                    day: "2-digit",
                },
            },
            {
                label: 'Exclusion Type', fieldName: 'paExclusionType', sortable: true,
                tooltip: {
                    fieldName: 'paExclusionType'
                },
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' },
                hideDefaultActions: true,
                // initialWidth: 155
            },
            {
                label: 'Exclusion Period', fieldName: 'paExclusionPeriod', sortable: true,
                tooltip: {
                    fieldName: 'paExclusionPeriod'
                },
                cellAttributes: { class: 'slds-p-vertical_none slds-m-vertical_none' },
                hideDefaultActions: true
            }
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