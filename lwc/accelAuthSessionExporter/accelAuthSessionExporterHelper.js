export const exportHelper = {
    /**
     * Shape the data so papa parse can export it with the col headers and col data.
     */
    generateExport( rawExportData,ref) {
        if(rawExportData) {
            let csvColHeaders = [
                'Auth Session Id', 'Login Type','Session Type','Platform','City','IP','Login Time', 'Last Modified Date'
            ];

            let csvDatas = [];
            if(rawExportData) {
                rawExportData.forEach( data => {
                    let csvData = [];
                    csvData.push(data.authSessionId);
                    csvData.push(data.loginType);
                    csvData.push(data.sessionType);
                    csvData.push(data.loginHistoryPlatformAndBrowser);
                    csvData.push(data.city);
                    csvData.push(data.sourceIp);
                    csvData.push(data.loginTime);
                    csvData.push(data.lastModifiedDate);
                    csvDatas.push(csvData);
                });
            }
            ref.csvColHeaders = csvColHeaders;
            ref.csvColData = csvDatas;
        }
    }
}