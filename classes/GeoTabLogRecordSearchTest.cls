@IsTest
private class GeoTabLogRecordSearchTest {

    @IsTest
    static void testConstructors() {
        GeoTabLogRecordSearch glrs = new GeoTabLogRecordSearch();
        GeoTabDeviceSearch gds = new GeoTabDeviceSearch();
        glrs = new GeoTabLogRecordSearch(gds);
    }
}