export const exportHelper = {
    /**
     * Shape the data so papa parse can export it with the col headers and col data.
     */
    generateExport( rawExportData,ref) {
        if(rawExportData) {
            let csvColHeaders = [
                'Service Resource Id', 'Service Resource Name','Device Id','Serial Number','VIN','Name'
            ];

            let csvDatas = [];
            if(rawExportData) {
                rawExportData.forEach( data => {
                    let csvData = [];
                    csvData.push(data.serviceResourceId);
                    csvData.push(data.serviceResourceName);
                    csvData.push(data.id);
                    csvData.push(data.serialNumber);
                    csvData.push(data.vehicleIdentificationNumber);
                    csvData.push(data.name);
                    csvDatas.push(csvData);
                });
            }
            ref.csvColHeaders = csvColHeaders;
            ref.csvColData = csvDatas;
        }
    }
}