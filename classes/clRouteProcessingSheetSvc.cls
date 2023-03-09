public without sharing class clRouteProcessingSheetSvc {

    public static Route_Processing_Sheet__c retrieveRouteProcessingSheet(Id rpsId) {
        Route_Processing_Sheet__c rps;
        String q = '';
        q += 'SELECT {0}, ';
        q += '       Account__r.Name,Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, ';
        q += '       Account__r.ShippingLatitude, Account__r.ShippingLongitude,Account__r.ShippingPostalCode,';
        q += '       Route_Schedule__r.Route__c,';
        q += '       Processing_Status_Changed_By__r.Name ,Account__r.Relationship_Manager__r.Name, Account__r.Collection_Contact_Name__c, ';
        q += '       Account__r.Collection_Contact_Number__c,Account__r.Collection_Notes__c ';
        q += 'FROM   Route_Processing_Sheet__c ';
        q += 'WHERE  Id  = :rpsId ';
        String formattedQuery = String.format(q,getAllRouteProcessingSheetFields());

        List<Route_Processing_Sheet__c> routeProcessingSheets = Database.query(formattedQuery);
        if(!routeProcessingSheets.isEmpty()) {
            rps = routeProcessingSheets[0];
        }
        return rps;
    }

    public static List<Route_Processing_Sheet__c> retrieveRouteProcessingSheets( Id userId, Date collectionDate ) {
        return retrieveRouteProcessingSheets(new Set<Id>{userId}, collectionDate);
    }

    public static List<Route_Processing_Sheet__c> retrieveRouteProcessingSheetsForProcessor( String type, Id userId, Id routeScheduleId, Date collectionDate ) {
        return retrieveRouteProcessingSheetsForProcessor(type, new Set<Id>{userId}, routeScheduleId,collectionDate);
    }

    public static List<Route_Processing_Sheet__c> retrieveAllRouteProcessingSheets() {
        /*
         * 3/8/2023 Added Account__r.IGB_License__c
         * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4106517832
         */
        String q = '';
        q += 'SELECT {0} ,';
        q += '       Account__r.Name,Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, ';
        q += '       Account__r.ShippingLatitude, Account__r.ShippingLongitude,Account__r.Location_Key_ID__c, ';
        q += '       Account__r.Access_Time__c,Account__r.Relationship_Manager__r.Name, Account__r.Collection_Contact_Name__c,';
        q += '       Account__r.IGB_License__c,';
        q += '       Route_Schedule__r.Route__c,Redemption_Asset__r.Model__c,';
        q += '       Account__r.Relationship_Manager__r.Phone, Account__r.Relationship_Manager__r.MobilePhone,';
        q += '       Account__r.Collection_Contact_Number__c ,Account__r.Collection_Notes__c ';
        q += 'FROM   Route_Processing_Sheet__c ';
        q += 'ORDER BY Stop_Number__c ASC LIMIT 200';
        
        String formattedQuery = String.format(q,getAllRouteProcessingSheetFields());

        List<Route_Processing_Sheet__c> routeProcessingSheets = Database.query(formattedQuery);
        return routeProcessingSheets;
    }

    public static List<Route_Processing_Sheet__c> retrieveRouteProcessingSheets( Set<Id> userIds, Date collectionDate ) {
        System.debug('----> retrieve rps userIds='+userIds + '.. date='+collectionDate);
        /*
         * 3/8/2023 Added Account__r.IGB_License__c
         * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4106517832
         */
        String q = '';
        q += 'SELECT {0} ,';
        q += '       Account__r.Name,Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, Account__r.ShippingPostalCode, ';
        q += '       Account__r.ShippingLatitude, Account__r.ShippingLongitude,Account__r.Location_Key_ID__c, ';
        q += '       Account__r.Access_Time__c,Account__r.Relationship_Manager__r.Name, Account__r.Collection_Contact_Name__c,';
        q += '       Account__r.IGB_License__c,';
        q += '       Route_Schedule__r.Route__c,Redemption_Asset__r.Model__c,';
        q += '       Account__r.Relationship_Manager__r.Phone,Account__r.Relationship_Manager__r.MobilePhone, ';
        q += '       Account__r.Collection_Contact_Number__c,Account__r.Collection_Notes__c ';
        q += 'FROM   Route_Processing_Sheet__c ';
        q += 'WHERE  ( ' +
                '      Route_Schedule__r.User__c               In :userIds ' +
                '      or Route_Schedule__r.Collector_1__c     In :userIds ' +
                '      or Route_Schedule__r.Assigned_Driver__c In :userIds ' +
                '      or Route_Schedule__r.Collector_3__c     In :userIds ' +
                '    ) ';
        q += 'AND    Collection_Date__c = :collectionDate ';

        q += 'ORDER BY Stop_Number__c ASC ';
        String formattedQuery = String.format(q,getAllRouteProcessingSheetFields());

        List<Route_Processing_Sheet__c> routeProcessingSheets = Database.query(formattedQuery);
        return routeProcessingSheets;
    }

    public static List<Route_Processing_Sheet__c> retrieveRouteProcessingSheetsForProcessor( String type, Set<Id> userIds, Id routeScheduleId,Date dDate ) {
        /*
         * 3/8/2023 Added Account__r.IGB_License__c
         * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4106517832
         */
        String q = '';
        q += 'SELECT {0} ,';
        q += '       Account__r.Name,Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState,  Account__r.ShippingPostalCode, ';
        q += '       Account__r.ShippingLatitude, Account__r.ShippingLongitude,Account__r.Location_Key_ID__c, ';
        q += '       Route_Schedule__r.Route__c,';
        q += '       Account__r.Access_Time__c,Account__r.Relationship_Manager__r.Name,Account__r.Collection_Contact_Name__c, ';
        q += '       Account__r.Collection_Contact_Number__c,Redemption_Asset__r.Model__c,';
        q += '       Account__r.Relationship_Manager__r.Phone,Account__r.Relationship_Manager__r.MobilePhone,Account__r.Collection_Notes__c, ';
        q += '       Account__r.IGB_License__c ';
        q += 'FROM   Route_Processing_Sheet__c ';
        q += 'WHERE  Route_Schedule__c = :routeScheduleId ';
        if(type == 'fill') {
            q += 'AND    Route_Fill_Date__c = :dDate ';
        } else {
            q += 'AND    Collection_Date__c = :dDate ';
        }

        q += 'ORDER BY Stop_Number__c ASC ';
        String formattedQuery = String.format(q,getAllRouteProcessingSheetFields());
        System.debug('---> formatted Query:'+formattedQuery);
        System.debug('---> userIds:'+userIds);
        System.debug('---> date:'+dDate);

        List<Route_Processing_Sheet__c> routeProcessingSheets = Database.query(formattedQuery);
        return routeProcessingSheets;
    }


    public static List<Route_Processing_Sheet__c> retrieveRouteProcessingSheets( Id routeScheduleId ) {
        /*
         * 3/8/2023 Added Account__r.IGB_License__c
         * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4106517832
         */
        String q = '';
        q += 'SELECT {0}, Account__r.Name, Account__r.ShippingStreet, Account__r.ShippingCity, Account__r.ShippingState, ';
        q += '       Account__r.Access_Time__c, ';
        q += '       Account__r.IGB_License__c,';
        q += '       Route_Schedule__r.Name, ';
        q += '       Redemption_Asset__r.Model__c ';
        q += 'FROM   Route_Processing_Sheet__c ';
        q += 'WHERE  Route_Schedule__c = :routeScheduleId ';
        q += 'ORDER BY Stop_Number__c ASC ';
        String formattedQuery = String.format(q,getAllRouteProcessingSheetFields());

        List<Route_Processing_Sheet__c> routeProcessingSheets = Database.query(formattedQuery);
        return routeProcessingSheets;
    }

    public static Map<String,Object> deleteScheduleRpsAndMeterRecords(Id routeScheduleId) {

        List<Route_Processing_Sheet__c> deletedRpsRecs = new List<Route_Processing_Sheet__c>();
        List<Meter_Reading__c> deletedMeterRecs =  new List<Meter_Reading__c>();

        Map<Id,Route_Processing_Sheet__c> rpsRecs = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id
                FROM   Route_Processing_Sheet__c
                WHERE  Route_Schedule__c = :routeScheduleId
        ]);
        if(!rpsRecs.isEmpty()) {
            List<Meter_Reading__c> meterReadings = [
                    SELECT Id
                    FROM   Meter_Reading__c
                    WHERE  Route_Processing_Sheet__c IN :rpsRecs.keySet()
            ];
            if(!meterReadings.isEmpty()) {
                deletedMeterRecs = meterReadings.deepClone(true);
                delete meterReadings;
            }
            deletedRpsRecs = rpsRecs.values().deepClone(true);
            delete rpsRecs.values();
        }
        return new Map<String,Object> {
                'DELETED_METER_RECS' => deletedMeterRecs,
                'DELETED_RPS_RECS' => deletedRpsRecs
        };
    }

    public static List<Meter_Reading__c> deleteScheduleMeterRecords(Id routeScheduleId) {

        List<Meter_Reading__c> deletedMeterRecs =  new List<Meter_Reading__c>();

        Map<Id,Route_Processing_Sheet__c> rpsRecs = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id
                FROM   Route_Processing_Sheet__c
                WHERE  Route_Schedule__c = :routeScheduleId
        ]);
        if(!rpsRecs.isEmpty()) {
            List<Meter_Reading__c> meterReadings = [
                    SELECT Id
                    FROM   Meter_Reading__c
                    WHERE  Route_Processing_Sheet__c IN :rpsRecs.keySet()
            ];
            if(!meterReadings.isEmpty()) {
                deletedMeterRecs = meterReadings.deepClone(true);
                delete meterReadings;
            }
        }
        return deletedMeterRecs;
    }

    @TestVisible
    private static List<String>  getAllRouteProcessingSheetFields() {
        Map<String, Schema.SObjectField> fieldsMap = Route_Processing_Sheet__c.sObjectType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }

}