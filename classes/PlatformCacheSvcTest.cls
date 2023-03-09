@IsTest
private class PlatformCacheSvcTest {

    @IsTest
    static void test_saveInOrg_positive() {

        Test.startTest();
        PlatformCacheSvc.saveInOrg('geotab','testkey1','testval1');
        Test.stopTest();

        String val = (String)PlatformCacheSvc.retrieveFromOrg('geotab','testkey1');
        System.assertEquals('testval1',val);

    }

    @IsTest
    static void test_saveInOrg_negative() {

        Test.startTest();

        cache.Org.OrgCacheException testEx;
        try {
            PlatformCacheSvc.saveInOrg('geotab1','testkey1','testval1');
        } catch (cache.Org.OrgCacheException ex) {
            testEx = ex;
        }
        System.assert( testEx != null);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveFromOrg_positive() {

        Test.startTest();
        PlatformCacheSvc.saveInOrg('geotab','testkey1','testval1');
        Test.stopTest();

        String val = (String)PlatformCacheSvc.retrieveFromOrg('geotab','testkey1');
        System.assertEquals('testval1',val);
    }

    @IsTest
    static void test_retrieveFromOrg_null() {

        Test.startTest();
        PlatformCacheSvc.saveInOrg('geotab','testkey1','testval1');
        Test.stopTest();

        String val = (String)PlatformCacheSvc.retrieveFromOrg('geotab','testkey2');
        System.assertEquals(null,val);
    }

    @IsTest
    static void test_retrievePcPartition_Success() {

        Test.startTest();
        PlatformCachePartition partition = PlatformCacheSvc.retrievePcPartition(GeoTabPlatformCacheSvc.GEOTAB_PARTITION);
        System.assertEquals(partition.DeveloperName,GeoTabPlatformCacheSvc.GEOTAB_PARTITION);
        Test.stopTest();
    }
}