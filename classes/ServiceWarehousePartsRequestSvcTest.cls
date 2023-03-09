@IsTest
private class ServiceWarehousePartsRequestSvcTest {

    @TestSetup
    static void setup() {

        Test.startTest();  //merely to reset gov limits to get around cpu time
        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        AccelTestHarness.createAllDataToServiceAppointments(params);

        Account account = [SELECT Id,Name FROM Account LIMIT 1];
        account.Name = 'Burr Ridge Warehouse';
        update account;

        Asset asset = [
                SELECT Id,AccountId
                FROM   Asset
                WHERE  RecordType.Name = 'VGT'
        ];
        asset.AccountId = account.Id;
        update asset;

        List<ServiceTerritory> sts = [
                SELECT Id, Restock_Warehouse__c
                FROM ServiceTerritory
        ];
        Schema.Location warehouse = new Schema.Location();
        warehouse.Name = 'Burr Ridge Warehouse';
        warehouse.LocationType = 'Warehouse';
        insert warehouse;
        for (ServiceTerritory st : sts) {
            st.Restock_Warehouse__c = warehouse.Id;
        }
        update sts;
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveWarehouseLocations() {

        Test.startTest();
        List<Schema.Location> warehouses = ServiceWarehousePartsRequestSvc.retrieveWarehouseLocations();
        System.assert(!warehouses.isEmpty());
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveListView() {

        Test.startTest();
        ListView lv =  ServiceWarehousePartsRequestSvc.retrieveListView('All_ProductRequests','ProductRequest');
        System.assert(lv != null);
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAsset() {

        Account account  = [SELECT Id FROM Account WHERE Name = 'Burr Ridge Warehouse'];
        Asset asset = [SELECT Id,Name FROM Asset WHERE Account.Name = 'Burr Ridge Warehouse'];

        Test.startTest();
        Map<Id, Asset> mAssets =  ServiceWarehousePartsRequestSvc.retrieveAsset(asset.Name,account.Id);
        System.assert(!mAssets.isEmpty());
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveWarehouseAssets() {

        Account account  = [SELECT Id FROM Account WHERE Name = 'Burr Ridge Warehouse'];

        Test.startTest();
        Map<Id, Asset> mAssets =  ServiceWarehousePartsRequestSvc.retrieveWarehouseAssets(account.Id);
        System.assert(!mAssets.isEmpty());
        Test.stopTest();
    }
}