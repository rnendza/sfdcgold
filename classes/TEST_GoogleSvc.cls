@IsTest
private class TEST_GoogleSvc {


    @IsTest
    static void test_init_geocoding_request() {

        Test.startTest();

        HttpRequest req = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);

        Test.stopTest();
    }

    @IsTest
    static void test_init_distancematrix_request() {

        Test.startTest();

        HttpRequest req = GoogleSvc.initHttpRequest(GoogleTransaction.DISTANCEMATRIX);

        Test.stopTest();
    }

    @IsTest
    static void test_quick_reverse_geo() {

        Test.startTest();

        GoogleSvc.quickReverseGeo(1,2);

        Test.stopTest();
    }
}