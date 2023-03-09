@IsTest
private class GeoCoordinatesTest {

    private static final GeoCoordinates sampleGeo = new GeoCoordinates(Double.valueOf(41.7957554),Double.valueOf(-88.0744586));

    @IsTest
    static void test_NoArgConstructor() {
        GeoCoordinates geoCoordinates = new GeoCoordinates();
        System.assertNotEquals(geoCoordinates.address,null);
    }

    @IsTest
    static void test_TwoArgConstructor() {
        GeoCoordinates geoCoordinates = new GeoCoordinates(sampleGeo.latitude,sampleGeo.longitude);
        System.assertEquals(geoCoordinates.latitude,sampleGeo.latitude);
    }

    @IsTest
    static void test_LocationConstructor() {
        System.Location location = System.Location.newInstance(Decimal.valueOf(sampleGeo.latitude),Decimal.valueOf(sampleGeo.longitude));
        GeoCoordinates geoCoordinates = new GeoCoordinates(location);
    }

    @IsTest
    static void test_accessorMethods() {
        GeoCoordinates geoCoordinates = new GeoCoordinates(sampleGeo.latitude,sampleGeo.longitude);
        geoCoordinates.address = geoCoordinates.address;
        geoCoordinates.accountName = geoCoordinates.accountName;
        geoCoordinates.accountAddress = geoCoordinates.accountAddress;
        geoCoordinates.accountId = geoCoordinates.accountId;

        geoCoordinates.address.street = '3223';
        geoCoordinates.address.city = 'sdfsd';
        String t1 = geoCoordinates.address.street;
        String t2 = geoCoordinates.address.city;
    }
}