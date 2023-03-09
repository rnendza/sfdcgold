@IsTest
private class GeolocationSvcTest {

    private static final GeoCoordinates sampleGeo = new GeoCoordinates(Double.valueOf(41.7957554),Double.valueOf(-88.0744586));

    @IsTest
    static void test_getDistance_with_locations() {

        System.Location locOrigin  = System.Location.newInstance(Decimal.valueOf(sampleGeo.latitude),Decimal.valueOf(sampleGeo.longitude));
        System.Location locDest  = System.Location.newInstance(Decimal.valueOf(sampleGeo.latitude + 1),Decimal.valueOf(sampleGeo.longitude + 1));

        Double distance = GeolocationSvc.getDistance(locOrigin,locDest);
        System.assertNotEquals(distance,null);
    }

    @IsTest
    static void test_getDistance_with_geocoords() {

        GeoCoordinates geoOrigin = sampleGeo.clone();
        GeoCoordinates geoDest1 = geoOrigin.clone();
        GeoCoordinates geoDest2 = geoDest1.clone();
        Set<GeoCoordinates> waypoints = new Set<GeoCoordinates> {geoDest1,geoDest2};
        Map<GeoCoordinates,Double> mDistance = GeolocationSvc.getDistance(geoOrigin,waypoints,'mi');
        System.assert(!mDistance.isEmpty());



//
//
//        System.Location locOrigin  = System.Location.newInstance(Decimal.valueOf(sampleGeo.latitude),Decimal.valueOf(sampleGeo.longitude));
//        System.Location locDest  = System.Location.newInstance(Decimal.valueOf(sampleGeo.latitude + 1),Decimal.valueOf(sampleGeo.longitude + 1));
//
//        Double distance = GeolocationSvc.getDistance(locOrigin,locDest);
//        System.assertNotEquals(distance,null);
    }

//
//    public static Map<GeoCoordinates,Double> getDistance( GeoCoordinates originGeo, Set<GeoCoordinates> waypointGeos,
//            String unit) {

    }