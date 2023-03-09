@IsTest
private class GeoTabAuthTest {
    @IsTest
    static void testConstructors() {
        Test.startTest();

        GeoTabAuth auth = new GeoTabAuth();
        auth = new GeoTabAuth(GeoTabAuth.DEFAULT_METHOD);
        auth = new GeoTabAuth('db','uname','pw');
        System.assertEquals(auth.params.database, 'db');

        Test.stopTest();
    }
}