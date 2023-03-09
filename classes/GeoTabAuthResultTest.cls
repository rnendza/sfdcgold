@IsTest
private class GeoTabAuthResultTest {

    @IsTest
    static void testConstructors() {
        Test.startTest();

        GeoTabAuthResult authResult = new GeoTabAuthResult();
        authResult.credentials = new GeoTabAuthCredentials();
        authResult.path = 'blah';

        Test.stopTest();
    }
}