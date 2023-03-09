export const dtHelper = {
    getColHeaders()  {
        let columns = [
            {
                label: 'Parent Record',
                fieldName: 'parentUrl',
                type: 'url',
                hideDefaultActions: true,
                typeAttributes: {
                    label: {fieldName: 'parentName'}, target: '_blank'
                },
                sortable: true
            },
            {
                label: 'Change Date',
                fieldName: 'createdDate',
                type: 'date',
                hideDefaultActions: true,
                sortable: true,
                typeAttributes: {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: true
                }
            },
            {
                label: 'Field',
                fieldName: 'fieldLabel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Original Value',
                fieldName: 'oldValue',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'New Value',
                fieldName: 'newValue',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: 'Changed By',
                fieldName: 'userUrl',
                type: 'url',
                hideDefaultActions: true,
                typeAttributes: {
                    label: {fieldName: 'createdByName'}, target: '_blank'
                },
                sortable: true
            },
        ];
        return columns
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
    }
}