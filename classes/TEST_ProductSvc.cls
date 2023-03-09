@istest
private class TEST_ProductSvc {
    public static String UNAME = 'acceltest@accel.com';
    /**
     *
     */
    @isTest static void testRetrieveAllMachineAverages() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            List<Product2> productsWithAssetModelNames;
            productsWithAssetModelNames = [select id from product2 where asset_model_name__c!=null];

            Test.startTest();
            List<Product2> products = ProductSvc.retrieveAllMachineAverages();
            system.assertEquals(products.size(),productsWithAssetModelNames.size());

            Test.stopTest();
        }
    }
}