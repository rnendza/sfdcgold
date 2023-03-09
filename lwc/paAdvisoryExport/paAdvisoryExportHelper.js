export const exportHelper = {
    /**
     * Shape the data so papa parse can export it with the col headers and col data.
     */
    generateExport( rawExportData,ref) {
        if(rawExportData) {
            let csvColHeaders = [
                'Advisory Name','Advisory Date','Request Date','Exclusion Period','Exclusion Type',
                'Advisory Number','Advisory Type','Advisory Status', 'Intake or Removal','Docket Number',
                'First Name', 'Last Name','Birth Date','Cell Phone','Phone','SSN',
                'Address 1','Address 2','City','State','Postal Code',
                'Gender','Eye Color','Hair Color','Height Ft','Height In',
                'Comments', 'Violations'
            ];

            let csvDatas = [];
            if(rawExportData) {
                rawExportData.forEach( data => {
                    let csvData = [];
                    csvData.push(data.Name);
                    csvData.push(data.Advisory_Date__c);
                    csvData.push(data.Request_Date__c);
                    csvData.push(data.Exclusion_Period__c);
                    csvData.push(data.Exclusion_Type__c);
                    csvData.push(data.Advisory_Number__c);
                    csvData.push(data.Advisory_Type__c);
                    csvData.push(data.Advisory_Status__c);
                    csvData.push(data.Intake_Or_Removal__c);
                    csvData.push(data.Docket_Number__c);
                    csvData.push(data.First_Name__c);
                    csvData.push(data.Last_Name__c);
                    csvData.push(data.Birth_Date__c);
                    csvData.push(data.Cell_Phone__c);
                    csvData.push(data.Phone__c);
                    csvData.push(data.SSN__c);
                    csvData.push(data.Address_1__c);
                    csvData.push(data.Address_2__c);
                    csvData.push(data.City__c);
                    csvData.push(data.State_Code__c);
                    csvData.push(data.Postal_Code__c);
                    csvData.push(data.Gender__c);
                    csvData.push(data.Eye_Color__c);
                    csvData.push(data.Hair_Color__c);
                    csvData.push(data.Height_Ft__c);
                    csvData.push(data.Height_In__c);
                    csvData.push(data.Comments__c);
                    csvData.push(data.Violations__c);
                    csvDatas.push(csvData);
                });
            }
            ref.csvColHeaders = csvColHeaders;
            ref.csvColData = csvDatas;
        }
    }
}