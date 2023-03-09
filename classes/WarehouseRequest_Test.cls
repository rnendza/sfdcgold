@IsTest
private class WarehouseRequest_Test {
    
    @TestSetup
    static void makeData() {

        Test.startTest();

        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        AccelTestHarness.createAllDataToServiceAppointments(params);

        Account account = [SELECT Id,Name FROM Account LIMIT 1];
        
        Test.stopTest();
        
    }

    @IsTest
    static void test_getWarehouseList_Positive() {

        Test.startTest();

        List<Account> accounts = WarehouseRequest.getWarehouseList();
        System.assert(accounts != null);

        Test.stopTest();
    }

    @IsTest
    static void test_getAssetList_Positive() {

        Id whId;
        Account account = [SELECT Id,Name FROM Account LIMIT 1];
        whId = account.Id;

        Test.startTest();

        List<Asset> assets = WarehouseRequest.getAssetList(whId);
        System.assert(assets != null);

        Test.stopTest();
    }

    @IsTest
    static void test_getListView_Positive() {

        String recordTypeName = 'My_WH_Parts_Requests';
        String sObjectApiName = 'ProductRequest';
        Test.startTest();

        String listView = WarehouseRequest.getListView(recordTypeName,sObjectApiName);
        System.assert(listView != null);

        Test.stopTest();
    }

}