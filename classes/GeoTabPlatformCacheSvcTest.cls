@IsTest
private class GeoTabPlatformCacheSvcTest {

    @IsTest
    static void test_put_get_AuthResp_positive() {
        String testAuthRespJson = GeoTabUtils.testAuthResJson;
        GeoTabAuthJsonToApex auth = GeoTabAuthJsonToApex.parse(testAuthRespJson);

        Test.startTest();
        GeoTabPlatformCacheSvc.putAuthResp(auth);
        Test.stopTest();

        GeoTabAuthJsonToApex cachedAuth = GeoTabPlatformCacheSvc.getAuthResp();
        System.assertEquals(auth,cachedAuth);
    }

    @IsTest
    static void test_put_AuthResp_negative() {
        String testAuthRespJson = GeoTabUtils.testAuthResJson;
        GeoTabAuthJsonToApex auth = GeoTabAuthJsonToApex.parse(testAuthRespJson);

        Test.startTest();
        GeoTabPlatformCacheSvc.GEOTAB_PARTITION = 'bogus';
        cache.Org.OrgCacheException testEx;
        try {
            GeoTabPlatformCacheSvc.putAuthResp(auth);
        } catch (cache.Org.OrgCacheException ex) {
            testEx = ex;
        }
        System.assert( testEx != null);

        Test.stopTest();

    }
}