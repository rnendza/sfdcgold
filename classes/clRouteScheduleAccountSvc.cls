public without sharing class clRouteScheduleAccountSvc {
    
    public static List<Route_Schedule_Account__c> retrieveRouteScheduleAccountsByIds(Set<Id> rsaIds) {
        System.debug('--- rsa ids='+rsaIds);
        String q = '';
        q += ' SELECT   {0},  ';
        q += '          Route_Schedule__r.Route_Fill_Date__c, Route_Schedule__r.Route_Collection_Date__c, ';
        //              Added 2/16/2022 for additional fill stuff.
        q += '          Route_Schedule__r.Processing_Location__c ';
        q += ' FROM     Route_Schedule_Account__c ';
        q += ' WHERE    Id IN :rsaIds ';
        q += ' ORDER BY Stop_Number__c ASC ';
        String formattedQuery = String.format(q,getAllRouteScheduleAccountFields());

        List<Route_Schedule_Account__c> routeScheduleAccounts = Database.query(formattedQuery);
        return routeScheduleAccounts;
    }

    @TestVisible
    private static List<String>  getAllRouteScheduleAccountFields() {
        Map<String, Schema.SObjectField> fieldsMap = Route_Schedule_Account__c.sObjectType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }
}