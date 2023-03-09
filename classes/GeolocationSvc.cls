/**
 * All things Geo location from a server side standpoint. Assumes miles as the unit for overloaded methods.
 */
public class GeolocationSvc {

    public final static String UNIT_MILES = 'mi';
    public final static Set<String> VALID_UNITS = new Set<String> {UNIT_MILES};

    /**
     * @param originLoc         The origination System.Location object.
     * @param destinationLoc    The destination System.Location object.
     *
     * @return                  The double distance between the 2.
     */
    public static Double getDistance(System.Location originLoc, System.Location destinationLoc) {

        GeoCoordinates originGeo = new GeoCoordinates();
        GeoCoordinates destinationGeo = new GeoCoordinates();

        originGeo.latitude = originLoc.latitude;
        originGeo.longitude = originLoc.longitude;
        destinationGeo.latitude = destinationLoc.latitude;
        destinationGeo.longitude = destinationLoc.longitude;

        return getDistance(originGeo,destinationGeo);
    }


    /**
     * @param originGeo         The origination GeoCoordinates object.
     * @param destinationGeo    The destination GeoCoordinates object.
     *
     * @return                  The Double distance between the 2.
     */
    public static Double getDistance(GeoCoordinates originGeo, GeoCoordinates destinationGeo) {
        Map<GeoCoordinates, Double> m = getDistance(originGeo, new Set<GeoCoordinates>{destinationGeo}, UNIT_MILES);
        return m.get(originGeo);
    }

    /**
     * @param originGeo        The origination GeoCoordinates object.
     * @param waypointGeos     A List<GeoCoordinate> of waypoints.
     * @param unit             The unit [mi]
     *
     * @return                  A Map of GeoCoordinate => Double distance
     */
    public static Map<GeoCoordinates,Double> getDistance(GeoCoordinates originGeo, Set<GeoCoordinates> waypointGeos, String unit) {

        //  Throws GeoCoordinatesException if invalid params and gets the heck out.
        Warnings.checkGeoDistanceParams(originGeo,waypointGeos, unit);

        Map<GeoCoordinates,Double> mDistanceResults = new Map<GeoCoordinates,Double>();

        Boolean gotOrigin = false;
        for(GeoCoordinates waypointGeo : waypointGeos) {
            GeoCoordinates prevWaypointGeo;

            if(!gotOrigin) {
                System.Location loc1 = System.Location.newInstance(originGeo.latitude, originGeo.longitude);
                System.Location loc2 = System.Location.newInstance(waypointGeo.latitude, waypointGeo.longitude);
                mDistanceResults.put(originGeo, System.Location.getDistance(loc1,loc2,unit));
                gotOrigin = true;
            } else {
                if(prevWaypointGeo != null) {
                    System.Location loc1 = System.Location.newInstance(prevWaypointGeo.latitude, prevWaypointGeo.longitude);
                    System.Location loc2 = System.Location.newInstance(waypointGeo.latitude, waypointGeo.longitude);
                    mDistanceResults.put(originGeo, System.Location.getDistance(loc1,loc2,unit));
                }
            }
            prevWaypointGeo = waypointGeo;
        }

        return mDistanceResults;
    }

}