export const exportHelper = {
    /**
     * Shape the data so papa parse can export it with the col headers and col data.
     */
    generateExport( rawExportData,ref) {
        if(rawExportData) {
            let csvColHeaders = [
                'Audit Trail Id','Created By Id','Created By Full Name','Created by Last Name','Created By First Name',
                'Created By Username','Created Date','Action','Display','Section'
            ];

            let csvDatas = [];
            if(rawExportData) {
                rawExportData.forEach( data => {
                    let csvData = [];
                    csvData.push(data.auditTrailId);
                    csvData.push(data.createdById);
                    csvData.push(data.createdByFullName);
                    csvData.push(data.createdByLastName);
                    csvData.push(data.createdByFirstName);
                    csvData.push(data.createdByUserName);
                    csvData.push(data.createdDate);
                    csvData.push(data.action);
                    csvData.push(data.display);
                    csvData.push(data.section);
                    csvDatas.push(csvData);
                });
            }
            ref.csvColHeaders = csvColHeaders;
            ref.csvColData = csvDatas;
        }
    }
}