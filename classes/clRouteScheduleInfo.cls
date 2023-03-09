public class clRouteScheduleInfo {

    public Id     rsId;
    public String rsName;
    public Date rsCollectionDate;
    public Integer totalLocations = 0;

    public clRouteScheduleInfo(Route_Schedule__c rs) {
        this.rsId = rs.Id;
        this.rsName = rs.Name;
        this.rsCollectionDate = rs.Route_Collection_Date__c;
        this.totalLocations = rs.Total_Processing_Sheets__c != null ? Integer.valueOf(rs.Total_Processing_Sheets__c) : 0;
    }
}