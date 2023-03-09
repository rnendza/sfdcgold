public without sharing class clAdminUtilsController {

    @AuraEnabled(cacheable=true)
    public static List<Route__c> retrieveRoutes( String searchKey, String sortBy, String sortDirection, Integer iLimit, Integer cycleNumber ) {

        String q = '';
        q += ' SELECT Id, Name, Cycle_Number__c, LastModifiedDate, Total_Accounts__c, Processing_Location__c, Collection_Cycle_Number__c ';
        q += ',Next_Fill_Date__c, Next_Collection_Date__c ';
        q += ' FROM Route__c ';

        Boolean searchKeySent = false;
        if ( searchKey != null && searchKey != '' ) {
            String key = '%' + searchKey + '%';
            searchKeySent = true;
            q += ' WHERE Name LIKE :key ';
        }
        if (cycleNumber != null && cycleNumber != 0) {
            if(searchKeySent) {
                q += ' AND Cycle_Number__c = :cycleNumber ';
            } else {
                q += ' WHERE Cycle_Number__c = :cycleNumber ';
            }
        }

        if ( sortBy != null && sortDirection != null ) {
            q += ' ORDER BY ' + sortBy + ' ' + sortDirection;
        }
        q += ' LIMIT :iLimit ';
        return Database.query(q);
    }

    @AuraEnabled(cacheable=true)
    public static List<RouteScheduleWrapper> retrieveRouteSchedules( String searchKey, Date collectionDate, Integer iLimit) {

        List<RouteScheduleWrapper> rsWraps = new List<RouteScheduleWrapper>();
        String q = '';
        q += ' SELECT Id, Name, Route_Collection_Date__c, Total_Accounts__c, Route_Fill_Date__c, ';
        q += '        Total_Processing_Sheets__c, Total_Meter_Readings__c, LastModifiedDate ';
        q += ' FROM   Route_Schedule__c ';

        if ( searchKey != null && searchKey != '' ) {
            String key = '%' + searchKey + '%';
            q += ' WHERE Name LIKE :key ';
            if ( collectionDate != null) {
                q += ' and Route_Collection_Date__c = :collectionDate ';
            }
        } else if(collectionDate != null) {
               q += 'WHERE Route_Collection_Date__C = :collectionDate ';
        }
        q += ' ORDER By LastModifiedDate DESC';
        q += ' LIMIT :iLimit ';
        List<Route_Schedule__c> routeSchedules = Database.query(q);
        if(!routeSchedules.isEmpty()) {
            for(Route_Schedule__c rs : routeSchedules) {
                rsWraps.add(new RouteScheduleWrapper(rs));
            }
        }
        return rsWraps;
    }

    public class RouteScheduleWrapper {

        @AuraEnabled  public Id rsId;
        @AuraEnabled  public String rsName;
        @AuraEnabled  public Date  rsCollectionDate;
        @AuraEnabled  public Date  rsFillDate;
        @AuraEnabled  public Integer totalAccounts;
        @AuraEnabled  public Integer totalRps;
        @AuraEnabled  public Integer totalMeterReadings;
        @AuraEnabled  public Datetime rsLastModifiedDate;

        public RouteScheduleWrapper(Route_Schedule__c rs) {
            this.rsId = rs.Id;
            this.rsName = rs.Name;
            this.rsCollectionDate = rs.Route_Collection_Date__c;
            this.rsFillDate = rs.Route_Fill_Date__c;
            this.totalAccounts = rs.Total_Accounts__c != null ? Integer.valueOf(rs.Total_Accounts__c) : null;
            this.totalRps = rs.Total_Processing_Sheets__c != null ?  Integer.valueOf(rs.Total_Processing_Sheets__c) : null;
            this.totalMeterReadings = rs.Total_Meter_Readings__c != null ?  Integer.valueOf(rs.Total_Meter_Readings__c) : null;
            this.rsLastModifiedDate = rs.LastModifiedDate;
        }

    }
}