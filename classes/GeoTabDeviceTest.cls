@IsTest
private class GeoTabDeviceTest {
    @IsTest
    static void testConstructors() {
        GeoTabDevice gtd = new GeoTabDevice();
        JSON.serialize(gtd);
    }
}