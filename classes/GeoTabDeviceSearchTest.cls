@IsTest
private class GeoTabDeviceSearchTest {
    @IsTest
    static void testConstructor() {
        GeoTabDeviceSearch geoTabDeviceSearch = new GeoTabDeviceSearch();
        geoTabDeviceSearch = new GeoTabDeviceSearch(GeoTabUtils.TEST_DEVICE_IDS[0]);
    }
}