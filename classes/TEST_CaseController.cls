@isTest
private class TEST_CaseController {
    public static String UNAME = 'acceltest@accel.com';
    /**
     * Setup test data.
    */
    @testSetup static void setup() {
        Asset asset = TestUtils.createAsset('test asset');
        TestUtils.createCase('test case subject',asset.id);
    }
    /**
     *
     */
    @isTest static void testTerritoryFilter() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();
            Asset asset = [select id,name from asset where name = 'test asset' limit 1];
            ResponseDto dto =  CaseController.searchCases(asset.name);
            system.assert( !((List<Case>)dto.values.get(CaseController.MAP_KEY_CASE_LIST)).isEmpty());
            dto =  CaseController.searchCases('bogus');
            system.assert( ((List<Case>)dto.values.get(CaseController.MAP_KEY_CASE_LIST)).isEmpty());
            Test.stopTest();
        }
    }
    /**
   *
   */
    @isTest static void testSearchSettingsRetrieval() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();

            ResponseDto dto = CaseController.retrieveSearchSettings();
            Custom_Search__mdt searchMdt = ( Custom_Search__mdt)dto.values.get(CaseController.MAP_KEY_RSM_SEARCH_SETTINGS );
            system.assert(searchMdt != null);

            Test.stopTest();
        }
    }
}