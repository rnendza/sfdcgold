export const mapHelper = {
    buildMapMarkers(dataRows) {
        let mapMarkers = [];
        dataRows.forEach( row => {
            let marker = {
                location: {
                    Latitude: row.latitude,
                    Longitude: row.longitude,
                    Street: this.formatDate(row.lastKnownLocationDate)
                },
                title:row.sfdcName,
                description: ' Latitude:'+row.latitude + ' Longitude:'+row.longitude,
                value:row.serviceResourceId
            }
            mapMarkers.push(marker);
        });
        return mapMarkers;
    },
    getDt1Classes() {

    },
    sort1Data(fieldname, direction,dtData) {
        // // Return the value stored in the field
        // let parseData = [...dtData];
        //
        // let keyValue = (a) => {
        //     return a[fieldname];
        // };
        // // cheking reverse direction
        // let isReverse = direction === 'asc' ? 1: -1;
        // // sorting data
        // parseData.sort((x, y) => {
        //     x = keyValue(x) ? keyValue(x) : ''; // handling null values
        //     y = keyValue(y) ? keyValue(y) : '';
        //     // sorting values based on direction
        //     return isReverse * ((x > y) - (y > x));
        // });
        // return parseData;
    },
    formatDate(pDt) {
        const options = {
            day: 'numeric', month: 'long',
            hour: 'numeric', minute: 'numeric',
            timeZoneName: 'short', timeZone: 'America/Chicago',
        };
        const dateTimeFormat = new Intl.DateTimeFormat('en-US',options);
        let dt = new Date(pDt);
        return dateTimeFormat.format(dt);
    }
}