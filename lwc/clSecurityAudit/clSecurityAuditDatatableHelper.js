export const dtHelper = {
    getColHeaders(securityEntityNames,mdt,labels)  {
        let columns = [
            {
                label: '',
                fieldName: 'sObjLabel',
                hideDefaultActions: true,
                sortable: true
            },
            {
                label: '',
                fieldName: 'fieldLabel',
                hideDefaultActions: true,
                sortable: true
            },
        ];
        if(mdt && mdt.Show_Field_Description__c) {
            let col = {
                label: labels.lblFieldDescColHeader,
                fieldName: 'fieldDesc',
                hideDefaultActions: true,
                sortable: true
            }
            columns.push(col);
        }

        securityEntityNames.forEach(name => {
            let fieldName = name.replaceAll(' ','_');
            let col = {
                label: name,
                fieldName: fieldName,
                hideDefaultActions: true,
                sortable: true
            };
            columns.push(col);
        });
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