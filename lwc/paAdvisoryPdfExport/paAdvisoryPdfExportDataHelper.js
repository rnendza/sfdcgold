export const dataHelper = {
    sortData(fieldname, direction,dtData) {
        // console.log('sort by ',fieldname);
        // console.log('sort dir ',direction);
        // Return the value stored in the field
        let parseData = [...dtData];

        try {
            let keyValue = (a) => {
                return a[fieldname];
            };
            // cheking reverse direction
            let isReverse = direction === 'asc' ? 1 : -1;
            // sorting data
            parseData.sort((x, y) => {
                x = keyValue(x) ? keyValue(x) : ''; // handling null values
                x = x.toLowerCase();
                y = keyValue(y) ? keyValue(y) : '';
                y = y.toLowerCase();
                // sorting values based on direction
                return isReverse * ((x > y) - (y > x));
            });
        } catch (e) {
            console.error('sorting exception',e);
        }
        return parseData;
    }
}