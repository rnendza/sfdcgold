@IsTest
private class GeoTabSearchParamsTest {
    @IsTest
    static void testConstructors() {
        Test.startTest();

        GeoTabSearchParams searchParams = new GeoTabSearchParams();

        GeoTabDeviceSearch gds = new GeoTabDeviceSearch();
        GeoTabLogRecordSearch glrs = new GeoTabLogRecordSearch();
        searchParams = new GeoTabSearchParams(gds);

        searchParams = new GeoTabSearchParams(gds,GeoTabUtils.getFormattedGmtDateTime(Datetime.now()),
                GeoTabUtils.getFormattedGmtDateTime(Datetime.now()));

        searchParams = new GeoTabSearchParams(glrs);


        Test.stopTest();
    }
}