public class GeoTabLogRecordSearch {
    public GeoTabDeviceSearch deviceSearch;
//    public String fromDate;
//    public String toDate;
    public String id;

    public GeoTabLogRecordSearch() {}

    public GeoTabLogRecordSearch(GeoTabDeviceSearch deviceSearch) {
        this.deviceSearch = deviceSearch;
//        this.fromDate = deviceSearch.fromDate;
//        this.toDate = deviceSearch.toDate;
        this.id = deviceSearch.id;
    }
}