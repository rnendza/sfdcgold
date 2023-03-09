@IsTest
private class GeoTabAuthParamsTest {

    @IsTest
    static void testConstructors() {
        Test.startTest();

        GeoTabAuthParams authParams = new GeoTabAuthParams();
        authParams = new GeoTabAuthParams('db','uname','pw');
        System.assert(authParams.database == 'db');

        Test.stopTest();
    }
}