@IsTest
private class GeoTabUtilsTest {

    @IsTest
    static void test_generateId() {
        Test.startTest();
        System.assert(GeoTabUtils.generateId() != null);
        Test.stopTest();
    }

    @IsTest
    static void test_generateHexDigest() {
        Test.startTest();
        System.assert(GeoTabUtils.generateHexDigest('MD5', Blob.valueOf(DateTime.now().getTime().format())) != null);
        Test.stopTest();
    }

    @IsTest
    static void test_getFormattedGmtDateTime() {
        Test.startTest();
        System.assert(GeoTabUtils.getFormattedGmtDateTime(Datetime.now()) != null);
        Test.stopTest();
    }

}