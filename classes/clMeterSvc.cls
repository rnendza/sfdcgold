public class clMeterSvc {


//    /**
//     * @todo for future use.
//     * @param rps xx
//     *
//     * @return xx
//     */
//    public static List<Meter_Reading__c> initMeterReadings(Route_Processing_Sheet__c rps) {
//
//        List<Meter_Reading__c> meterReadingsIns = new List<Meter_Reading__c>();
//
//        Set<String> rtDevNames = new Set<String>{'VGT'};
//        List<Asset> accountMachines = AssetSvc.retrieveAccountMachines(rps.Account__c,rtDevNames);
//        for(Asset machine : accountMachines) {
//            Meter_Reading__c reading = new Meter_Reading__c();
//            reading.Asset__c = machine.Id;
//            reading.BV_Type__c = machine.BV_Type__c;
//            reading.Route_Processing_Sheet__c = rps.Id;
//            reading.Reading_Status__c = 'New';
//            meterReadingsIns.add(reading);
//        }
//        insert meterReadingsIns;
//        return meterReadingsIns;
//    }


    public static Map<Id,Meter_Reading__c> retrieveRpsMeterReadings(Id rpsId) {

        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT Id,Name,Current_Lifetime_Cash_In__c,Asset__c,Route_Processing_Sheet__c, Reading_Status__c,
                        LastModifiedDate,Actual_1_Note_Count__c,Actual_5_Note_Count__c,Actual_20_Note_Count__c,
                        CreatedDate,BV_Type__c,
                        Actual_100_Note_Count__c,Actual_Drop__c,
                        Route_Processing_Sheet__r.Account__r.Name,
                        Asset__r.SAS__c,Asset__r.RecordType.DeveloperName,Asset__r.Model__c,Asset__r.SerialNumber,
                        Asset__r.RecordType.Name,Required_Data_Entered__c,Cannot_Collect__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rpsId
                ORDER  BY LastModifiedDate DESC
        ]);
        return mMeterReadings;
    }
    /**
     * @param rpsId
     *
     * @return
     */
    public static Map<Id,Meter_Reading__c> retrieveRpsMeterReadingsSummary(Id rpsId) {

        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT  Id,Name,Route_Processing_Sheet__c, Reading_Status__c,
                        LastModifiedDate,BV_Type__c,
                        Asset__r.SAS__c,Asset__r.RecordType.DeveloperName,Asset__r.Model__c,Asset__r.SerialNumber
                FROM    Meter_Reading__c
                WHERE   Route_Processing_Sheet__c = :rpsId
                ORDER  BY Asset__r.SAS__c ASC
        ]);
        return mMeterReadings;
    }

    public static Map<Id,Meter_Reading__c> retrieveRpsMeterReadings(Id rpsId, String rtDevName) {

        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT  Id,Name,Current_Lifetime_Cash_In__c,Asset__c,Route_Processing_Sheet__c, Reading_Status__c,
                        LastModifiedDate, Actual_1_Note_Count__c,Actual_5_Note_Count__c,Actual_20_Note_Count__c,
                        CreatedDate,
                        Actual_100_Note_Count__c,Actual_Drop__c,
                        Route_Processing_Sheet__r.Account__r.Name,
                        Asset__r.SAS__c,Asset__r.RecordType.DeveloperName,Asset__r.Model__c,Asset__r.SerialNumber,
                        Asset__r.RecordType.Name, Required_Data_Entered__c,Cannot_Collect__c,Snapshot__c
                FROM    Meter_Reading__c
                WHERE   Route_Processing_Sheet__c = :rpsId
                AND     Asset__r.RecordType.DeveloperName = :rtDevName
                ORDER  BY Asset__r.SAS__C ASC
        ]);
        return mMeterReadings;
    }

    public static Meter_Reading__c retrieveSingleMeterReading(Id meterId) {
        Meter_Reading__c meterReading;
        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT Id,Name,Current_Lifetime_Cash_In__c,Asset__c,Route_Processing_Sheet__c, Reading_Status__c,
                        LastModifiedDate, Actual_1_Note_Count__c,Actual_5_Note_Count__c,Actual_20_Note_Count__c,
                        Actual_100_Note_Count__c,Actual_Drop__c,
                        Route_Processing_Sheet__r.Account__r.Name,
                        CreatedDate,
                        Asset__r.SAS__c,Asset__r.RecordType.DeveloperName,Asset__r.Model__c,Asset__r.SerialNumber,
                        Asset__r.RecordType.Name, Snapshot__c,Required_Data_Entered__c,Cannot_Collect__c
                FROM   Meter_Reading__c
                WHERE  Id = :meterId
        ]);
        if(!mMeterReadings.isEmpty()) {
            meterReading = mMeterReadings.values()[0];
        }
        return meterReading;
    }


    public static Meter_Reading__c retrieveMeterReading(Id meterId) {
        Meter_Reading__c meterReading;

        List<Meter_Reading__c> meterReadings = [
                SELECT Id,Name,Current_Lifetime_Cash_In__c,Asset__c,Route_Processing_Sheet__c,Reading_Status__c,Required_Data_Entered__c,Cannot_Collect__c
                FROM   Meter_Reading__c
                WHERE  Id = :meterId
        ];
        meterReading = meterReadings.isEmpty() ? null : meterReadings[0];

        return meterReading;
    }

    public static Meter_Reading__c retrieveCollectorMeterDetail(Id meterId) {
        Meter_Reading__c meterReading;
        Map<Id,Meter_Reading__c> mMeterReadings = new Map<Id,Meter_Reading__c>([
                SELECT Id,Name,Current_Lifetime_Cash_In__c,Asset__c,Route_Processing_Sheet__c, Reading_Status__c,
                        LastModifiedDate, Actual_1_Note_Count__c,Actual_5_Note_Count__c,Actual_20_Note_Count__c,
                        Actual_100_Note_Count__c,Actual_Drop__c,
                        Route_Processing_Sheet__r.Account__r.Name,
                        CreatedDate,
                        Asset__r.SAS__c,Asset__r.RecordType.DeveloperName,Asset__r.Model__c,Asset__r.SerialNumber,
                        Asset__r.RecordType.Name, Snapshot__c,Required_Data_Entered__c,Cannot_Collect__c
                FROM   Meter_Reading__c
                WHERE  Id = :meterId
        ]);
        if(!mMeterReadings.isEmpty()) {
            meterReading = mMeterReadings.values()[0];
        }
        return meterReading;
    }
}