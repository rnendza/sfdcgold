@IsTest
private class AccountAssetsControllerTest {

    private static final String CALLCENTERUNAME             = 'callcenterdude@dude.com';
    private static final String CASE_ACCOUNT_FIELD_NAME     = 'AccountId';
    private static  User uCallCenter                        = TestUtils.getUserForTest( CALLCENTERUNAME );


    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Asset asset = ((List<Asset>)mBaseData.get(clTESTUTILS.SFDCASSETS))[0];
        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        List<WorkType> workTypes = TestUtils.buildWorkTypes(params.workTypeNames, params.workTypeEstDuration,
                params.workOrderDurationType);
        insert workTypes;

        Case cse = TestUtils.buildCase('TEST Case for Account Assets','Call_Center',asset.Id,asset.AccountId);
        Asset rtAsset = TestUtils.buildAsset('TESTRTASSET', asset.AccountId, 'Redemption');
        insert rtAsset;

        cse.Work_Type__c = workTypes[0].Id;
        insert cse;
    }

    @isTest
    static void test_retrieveAccountAssetData_success() {

        uCallCenter.profileId = [SELECT Id from Profile where Name = 'Accel Call Center']?.Id;
        update uCallCenter;

        System.runAs(uCallCenter) {
            Case cse = [SELECT Id,AccountId FROM Case LIMIT 1];
            List<Asset> vgtAssets = AssetSvc.retrieveAccountVgts(cse.AccountId);
            List<Asset> rtAssets = AssetSvc.retrieveAccountRts(cse.AccountId);

            Test.startTest();

            ResponseDto dto = AccountAssetsController.retrieveAccountAssetData(cse.Id,CASE_ACCOUNT_FIELD_NAME);

            AccountAssetsController.AccountMachinesWrapper wrap =
                    (AccountAssetsController.AccountMachinesWrapper)dto.values.get(AccountAssetsController.MAP_KEY_ACCOUNT_MACHINE_DATA);

            System.assertEquals(wrap.sObjectApiName,'Case');
            System.assertEquals(wrap.account.Id,cse.AccountId);
            System.assertEquals(wrap.iNumVgts,vgtAssets.size());
            System.assertEquals(wrap.iNumRts,rtAssets.size());
            System.assertEquals(true,dto.isSuccess);

            Test.stopTest();

            System.debug(dto);
        }
    }

    @isTest
    static void test_retrieveAccountAssetData_nomachines() {


        Case cse = [SELECT Id,AccountId,AssetId FROM Case LIMIT 1];
        cse.AssetId = null;
        update cse;
        List<Asset> vgtAssets = AssetSvc.retrieveAccountVgts(cse.AccountId);
        delete vgtAssets;
        List<Asset> rtAssets = AssetSvc.retrieveAccountRts(cse.AccountId);
        delete rtAssets;
        System.runAs(uCallCenter) {

            Test.startTest();
            ResponseDto dto = AccountAssetsController.retrieveAccountAssetData(cse.Id,CASE_ACCOUNT_FIELD_NAME);
            System.assertEquals(false,dto.isSuccess);
            Test.stopTest();

            System.debug(dto);
        }
    }

    @isTest
    static void test_retrieveAccountAssetData_badParentRecordId() {
        uCallCenter.profileId = [SELECT Id from Profile where Name = 'Accel Call Center']?.Id;
        update uCallCenter;


        System.runAs(uCallCenter) {

            Test.startTest();
            ResponseDto dto = AccountAssetsController.retrieveAccountAssetData(null,CASE_ACCOUNT_FIELD_NAME);
            System.assertEquals(false,dto.isSuccess);
            System.assertEquals('error',dto.severity);
            Test.stopTest();

            System.debug(dto);
        }
    }

    @isTest
    static void test_retrieveAccountAssetData_badParentAccountFieldApiName() {

        uCallCenter.profileId = [SELECT Id from Profile where Name = 'Accel Call Center']?.Id;
        update uCallCenter;

        Case cse = [SELECT Id,AccountId FROM Case LIMIT 1];

        System.runAs(uCallCenter) {

            Test.startTest();
            ResponseDto dto;
            QueryException qex;
            try {
                dto = AccountAssetsController.retrieveAccountAssetData(cse.Id, 'bogus_account_api_name');
            } catch (QueryException qe) {
                qex = qe;
            }
            System.assert(qex.getMessage().contains('bogus_account_api_name'));
            Test.stopTest();

            System.debug(dto);
        }
    }

}