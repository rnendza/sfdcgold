public class GeoTabSearchParams {

    public String fromDate;
    public String toDate;
    public String serialNumber;
    public String id;
    public GeoTabLogRecordSearch logRecordSearch;
    public GeoTabDeviceSearch deviceSearch;


    public GeoTabSearchParams() {}

    public GeoTabSearchParams(GeoTabLogRecordSearch logRecordSearch) {
        this.logRecordSearch = logRecordSearch;
    }

    public GeoTabSearchParams(GeoTabDeviceSearch deviceSearch, String fromDate,String toDate) {
        this.fromDate = fromDate;
        this.toDate = toDate;
        this.serialNumber =deviceSearch.serialNumber;
        this.deviceSearch = deviceSearch;
    }

    public GeoTabSearchParams(GeoTabDeviceSearch deviceSearch) {
        this.deviceSearch = deviceSearch;
        //this.serialNumber = deviceSearch.serialNumber;
        //this.id = deviceSearch.id;
    }
}