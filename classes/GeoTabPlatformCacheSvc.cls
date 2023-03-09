/**
 * @see GeoTabPlatformCacheSvcTest
 */
public class GeoTabPlatformCacheSvc {

    public static String                GEOTAB_PARTITION   = 'geotab';
    @TestVisible private static String  AUTH_JSON_RESP_KEY = 'authJsonRespKey';

    /**
     * Puts the auth json for geotab in platform cache.
     * @param authJsonRes An instance of GeoTabAuthJsonToApex
     */
    public static void putAuthResp(GeoTabAuthJsonToApex authJsonRes) {
        PlatformCacheSvc.saveInOrg(GEOTAB_PARTITION,AUTH_JSON_RESP_KEY,authJsonRes);
    }


    /**
     * Get the cached JSON if exists, otherwise null.
     * @return The cached GeoTabJsonToApex instance.
     */
    public static GeoTabAuthJsonToApex getAuthResp() {
        return (GeoTabAuthJsonToApex)PlatformCacheSvc.retrieveFromOrg(GEOTAB_PARTITION,AUTH_JSON_RESP_KEY);
    }
}