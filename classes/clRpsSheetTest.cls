@IsTest
private class clRpsSheetTest {
    @IsTest
    static void test_construct() {
        new clRpsSheet( new clRouteProcessingSheetsController.RpsWrapper());
    }
}