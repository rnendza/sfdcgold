@IsTest
public class ReusableLookupController_Test {

    @TestSetup
    static void makeData() {

        Test.startTest();

        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        AccelTestHarness.createAllDataToServiceAppointments(params);

        Account account = [SELECT Id,Name FROM Account LIMIT 1];
        

        Asset asset = [
                SELECT Id,AccountId
                FROM   Asset
                WHERE  RecordType.Name IN :ServiceWarehousePartsRequestSvc.ASSET_RTS
                LIMIT 1
        ];
        asset.AccountId = account.Id;
        update asset;
        
        Test.stopTest();
        
    }
    
    @IsTest
    static void searchTest1() {

        Account account = [SELECT Id,Name FROM Account LIMIT 1];

        String objectApiName = 'Asset';
        String fieldApiName = 'Name';
        String otherFieldApiName = 'Model__c';
        String searchString = '587';
        String selectedRecordId = '';
        String parentRecordId = account.Id;
        String parentFieldApiName = 'AccountId';
        String recordTypes = '(\'VGT\', \'Redemption\')';

        ReusableLookupController.SearchWrapper wrap = new ReusableLookupController.SearchWrapper();
        wrap.objectApiName = objectApiName;
        wrap.fieldApiName = fieldApiName;
        wrap.otherFieldApiName = otherFieldApiName;
        wrap.searchString = searchString;
        wrap.selectedRecordId = selectedRecordId;
        wrap.parentRecordId = parentRecordId;
        wrap.parentFieldApiName = parentFieldApiName;
        wrap.recordTypes = recordTypes;


        Test.startTest();
         
        List<ReusableLookupController.ResultWrapper> assets = ReusableLookupController.fetchRecords(wrap);
        System.assert(assets != null);
        
        Test.stopTest();
    }

    @IsTest
    static void searchTest2() {

        Account account = [SELECT Id,Name FROM Account LIMIT 1];

        String objectApiName = 'Asset';
        String fieldApiName = 'Name';
        String otherFieldApiName = 'Model__c';
        String searchString = '587';
        String selectedRecordId = '';
        String parentRecordId = account.Id;
        String parentFieldApiName = 'AccountId';
        String recordTypes = '(\'VGT\', \'Redemption\')';

        ReusableLookupController.SearchWrapper wrap = new ReusableLookupController.SearchWrapper();
        wrap.objectApiName = objectApiName;
        wrap.fieldApiName = fieldApiName;
        wrap.otherFieldApiName = otherFieldApiName;
        wrap.searchString = searchString;
        wrap.selectedRecordId = selectedRecordId;
        wrap.parentRecordId = parentRecordId;
        wrap.parentFieldApiName = parentFieldApiName;
        wrap.recordTypes = recordTypes;


        Test.startTest();
        
        List<ReusableLookupController.ResultWrapper> assets = ReusableLookupController.fetchRecords(wrap);
        System.assert(assets != null);

        Test.stopTest();
    }

    @IsTest
    static void searchTest3() {

        Account account = [SELECT Id,Name FROM Account LIMIT 1];
        Asset asset = [SELECT Id,Name FROM Asset];

        String objectApiName = 'Asset';
        String fieldApiName = 'Name';
        String otherFieldApiName = 'Model__c';
        String searchString = '587';
        String selectedRecordId = asset.Id;
        String parentRecordId = account.Id;
        String parentFieldApiName = '';

        ReusableLookupController.SearchWrapper wrap = new ReusableLookupController.SearchWrapper();
        wrap.objectApiName = objectApiName;
        wrap.fieldApiName = fieldApiName;
        wrap.otherFieldApiName = otherFieldApiName;
        wrap.searchString = searchString;
        wrap.selectedRecordId = selectedRecordId;
        wrap.parentRecordId = parentRecordId;
        wrap.parentFieldApiName = parentFieldApiName;


        Test.startTest();
        
        List<ReusableLookupController.ResultWrapper> assets = ReusableLookupController.fetchRecords(wrap);
        System.assert(assets != null);

        Test.stopTest();
    }

}