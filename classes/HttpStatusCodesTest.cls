@IsTest
private class HttpStatusCodesTest {
    @IsTest
    static void test_Statics() {
        Test.startTest();
        System.assertEquals(200,HttpStatusCodes.OK);
        Test.stopTest();
    }
}